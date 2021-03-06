
require('aurita/plugin_controller')
Aurita::Main.import_model :content_history
Aurita::Main.import_model :content_category
Aurita::Main.import_model :tag_relevance

Aurita.import_plugin_model :wiki, :article
Aurita.import_plugin_model :wiki, :container
Aurita.import_plugin_model :wiki, :text_asset
Aurita.import_plugin_model :wiki, :media_asset
Aurita.import_plugin_model :wiki, :article_version
Aurita.import_plugin_model :wiki, :article_access
Aurita.import_plugin_module :wiki, :article_cache
Aurita.import_plugin_module :wiki, :article_hierarchy_visitor
Aurita.import_plugin_module :wiki, :article_full_hierarchy_visitor
Aurita.import_plugin_module :wiki, :article_hierarchy_default_decorator
Aurita.import_plugin_module :wiki, :article_hierarchy_pdf_decorator
Aurita.import_plugin_module :wiki, :article_dump_default_decorator
Aurita.import_plugin_module :wiki, :article_hierarchy_sortable_decorator
Aurita.import_plugin_module :wiki, :gui, :article_selection_list_entry

begin
  Aurita.import_plugin_model :memo, :memo_article
rescue ::Exception => ignore
end

module Aurita
module Plugins
module Wiki

  class Article_Controller < Plugin_Controller

    guard_interface(:add, :perform_add) {
      Aurita.user.may(:create_articles)
    }
    guard_interface(:delete, :perform_delete, :update, :perform_update) { |c|
      Aurita.user.may_edit_content?(c.load_instance()) || Aurita.user.may(:edit_foreign_articles)
    }

    def form_groups
      [
       Article.title,
       Content.tags, 
       Category.category_id
      ]
    end
    
    def form_hints
      { 
        Article.title.to_s        => tl(:article_title_hint), 
        Content.tags.to_s         => tl(:article_tags_hint), 
        Category.category_id.to_s => tl(:article_category_hint)
      }
    end
    
    def hierarchy_entry_type
      { 
        :name       => 'ARTICLE', 
        :label      => tl(:article), 
        :request    => 'Wiki::Article_Selection_Field' 
      }
    end
    
    def hierarchy_entry(params)
      entry = params[:entry]
      if entry.attr[:type] == 'ARTICLE' then
        article_id = entry.interface.split('=')[-1]
        article = Article.load(:article_id => article_id)
      end
      return ''
    end
    
    def add_tag
      Aurita::Main::Content_Controller.add_tag()
      article = Article.find(1).with(Article.content_id == param(:content_id)).entitiy
      article.touch if article
    end
    
    def invalidate_and_show(params={})
    # {{{

      article   = Article.load(:article_id => params[:article_id])
      article ||= Article.find(1).with(:content_id => params[:content_id]).entity
      return unless article
      article.touch if article
      redirect_to(:controller => 'Wiki::Article', :action => 'show', 
                  :article_id => article.article_id)

    end # }}}
    
    def commit_version
      article = load_instance()
      article.commit_version if (article && Aurita.user.may_edit_content?(article))
    end
    
    def list_category(params)
    # {{{
      articles = Article.select { |a|
        a.where(Article.in_category(params[:category_id]))
        a.order_by(Article.changed, :desc)
        a.limit(100)
      }
      article_box        = Box.new(:class => :topic_inline, 
                                   :id    => :category_articles, 
                                   :type  => :none)
      article_box.body   = view_string(:article_list, :articles => articles)
      article_box.header = tl(:recently_changed_articles)
      return article_box
    end # }}}

    def toolbar_buttons
    # {{{
      if Aurita.user.may(:create_articles) then
        return Text_Button.new(:icon    => :add_article, 
                               :action  => 'Wiki::Article/add') { 
          tl(:write_new_article) 
        } 
      end
    end # }}}

    def recent_changes
    # {{{
      
      result = HTML.h2 { :recent_changes_in_categories }.to_s
      user_cats = User_Category.all_with(User_Category.user_group_id == Aurita.user.user_group_id).sort_by(Category.category_name, :asc)
      cats = []
      cat_list = {}
      user_cats.each { |c|
        if !cat_list[c.category_id] then
          cats << c
          cat_list[c.category_id] = true
        end
      }
      cats.each { |cat|
        entries = Article.select { |a|
          a.join(Content_Category).on(Content_Category.content_id == Article.content_id) { |cc|
            cc.where((Content_Category.category_id == cat.category_id) & (Article.changed > (Time.now - 60 * 60 * 24 * 7).strftime("%Y-%m-%d")))
            cc.order_by(Article.changed, :desc)
            cc.limit(5)
          }
        }
        unread_articles = {}
        entries.each { |e| 
          if Article_Access.find(1).with((Article_Access.article_id == e.article_id) &
                                         (Article_Access.user_group_id == Aurita.user.user_group_id) & 
                                         (Article_Access.changed > e.changed)).entity
          then
            unread_articles[e.article_id] = false
          else
            unread_articles[e.article_id] = true
          end
        }
        if entries.length > 0 then
          result << HTML.h3 { cat.category_name }.to_s
          result << HTML.a(:href => '/aurita/Feed/for_category/category_id=' << cat.category_id + '&cb__mode=dispatch', :target => '_blank') { 'FEED' }.to_s
          result << view_string(:article_list, 
                                :unread_articles => unread_articles, 
                                :articles => entries)
          result << HTML.hr.to_s
        end
      }
      Element.new { result }

    end # }}}
    
    def find_in_category(category, key)
      Article.all_with((Article.has_tag(key.to_s.split(' ')) | 
                        Article.title.ilike("%#{key}%")) & 
                       Article.in_category(category.category_id)).sort_by(Article.changed, :desc).entities
    end
    
    def find_all(params)
    # {{{
      
      return unless params[:key]
      key = params[:key].to_s
      tags = key.split(' ')
      articles = Article.all_with((Article.has_tag(tags) | 
                                   Article.title.ilike("%#{key}%")) &
                                   Article.is_accessible).sort_by(Article.changed, :desc).entities
      return unless articles.first
      box = Box.new(:type => :none, :class => :topic_inline)
      box.body = view_string(:article_list, :articles => articles, :client_id => param[:client_id])
      box.header = tl(:articles)
      return box
      
    end # }}}

    def find_full(params)
    # {{{

      key         = params[:key].to_s.strip
      tags        = key.split(' ')
      tag         = "%#{tags.last}%"
      num         = params[:amount]
      num       ||= :all
      
      filter      = Article.is_accessible
      filter      = filter & params[:filter] if params[:filter]

      
      constraints = Article.title.ilike(tag)
      articles    = Article.find(num).with((Article.has_tag(tags) | 
                                      Article.title.ilike("%#{key}%")
                                     ) & 
                                     filter).sort_by(Wiki::Article.changed, :desc).entities
      
      num -= articles.length unless num == :all
      begin
        key.to_named_html_entities! # UTF-8 could be broken (1-Byte) but okay nonetheless
      rescue ::Exception => e
      end
      articles   += Article.find(num).with(filter & Article.content_id.in(
                                       Container.select(Container.content_id_parent) { |cid|
                                         cid.join(Text_Asset).on(Container.asset_id_child == Text_Asset.asset_id) { |ta|
                                           ta.where(Text_Asset.text.ilike("%#{key}%"))
                                         }}
                                     )).sort_by(Article.article_id, :desc).entities
      
      
      return unless articles.first
      
      box        = Box.new(:type => :none, :class => :topic_inline)
      box.body   = view_string(:article_list, :articles => articles, :client_id => params[:client_id])
      box.header = tl(:articles) 
      return box
      
    end # }}}

    def own_articles_box
    # {{{

      result = ''
      User_Category.all_with(User_Category.user_group_id == Aurita.user.user_group_id).each { |cat|
        entries = Article.select { |a|
          a.join(Content_Category).on(Content_Category.content_id == Article.content_id) { |cc|
            cc.where((Article.user_group_id == Aurita.user.user_group_id) & 
                     (Content_Category.category_id == cat.category_id))
            cc.order_by('lower(article.title)', :asc)
          }
        }
        box = Box.new(:type => :media_asset_bookmark_box, :class => :small_topic, :id => 'own_articles_cat_' << cat.category_id)
        box.header = cat.category_name + ' (' + entries.length.to_s + ')'
        box.header_style = 'font-size: 11px;'
        box.collapsed = true
        box.body = view_string(:articles_unpublished_list, :articles => entries)
        if cat.category_id == Aurita.user.category_id then
          box.header = 'Private Artikel (' + entries.length.to_s + ')'
          result = box.string + result
        else
          result << box.string
        end
      }
      box = Box.new(:type => :media_asset_bookmark_box, :class => :topic, :id => 'own_articles_box')
      box.header = 'Meine Artikel'
      box.body = result
      return box

    end # }}}
    
    def index
      puts list
    end
    
    def add
    # {{{
      default_cat_id = param(:category_id) 

      form = add_form()
      form.add(Category_Selection_List_Field.new())
      form[Content.tags] = Tag_Autocomplete_Field.new(:name => Content.tags, :label => tl(:tags))
      form[Content.tags].required!

      form[Category.category_id].value = default_cat_id if default_cat_id
      
      exec_js('Aurita.Main.init_autocomplete_tags();')

      form = decorate_form(form)
      return form unless param(:element) == 'app_main_content'
  
      header = tl(:create_article)
      header = tl(:write_new_entry) if Aurita.user.may(:use_portal_view)
      Page.new(:header => header) { form }

    end # }}}

    def update
    # {{{
      
      article  = load_instance()
      form     = update_form()
      category = Category_Selection_List_Field.new()
      category.value = article.category_ids
      form.add(category)

      form[Content.tags] = Tag_Autocomplete_Field.new(:name => Content.tags.to_s, :label => tl(:tags), :value => article.tags)
      form[Content.tags].required!
      exec_js('Aurita.Main.init_autocomplete_tags();')

      if Aurita.user.is_admin? or article.user_group_id == Aurita.user.user_group_id then 
        form.fields << Content.locked.to_s
        is_locked   = Boolean_Radio_Field.new(:name => Content.locked, 
                                              :label => tl('public--content--locked'), 
                                              :value => article.locked)
        form.add(is_locked)
      end

#     render_form(form)
      
      return form unless param(:element) == 'app_main_content'

      Page.new(:header => tl(:edit_article)) { decorate_form(form) }

    end # }}}

    def delete
      article  = load_instance()
      form     = model_form(:action => :perform_delete, :instance => article)
      form.readonly!
      render_form(form, :name => 'article_add_form')
    end

    def perform_add
    # {{{
      article = super()
      article.set_categories(param(:category_id))
      
      @params.set('public.text_asset.text', 'Editieren')
      @params.set('public.article.content_id', article.content_id)
      text_asset = Aurita::Plugins::Wiki::Text_Asset_Controller.new(@params).perform_add()
      
      redirect_to(article, :edit_inline_content_id => text_asset.content_id, 
                           :article_id             => article.article_id, 
                           :edit_inline_type       => 'TEXT_ASSET')
      
      article.commit_version
    end # }}}

    def perform_update
    # {{{
      if param(:locked).to_s == '' then 
        @params[Content.locked] = 'f' 
        @params[:locked] = 'f' 
        @params['public.content.locked'] = 'f' 
      end
      article    = load_instance()
      content_id = article.content_id
      article.set_categories(param(:category_id))

      super()

      Content.touch(content_id)

      # Reload from DB so we have most recent record
      instance = Article.load(:article_id => param(:article_id))
      instance.commit_version

      redirect_to(:action => :show, :article_id => instance.article_id)
    end # }}}

    def perform_delete
      super()
      exec_js("Aurita.Wiki.after_article_delete(#{param(:article_id)}); ")
    end

    def self.touch_article(article_id)
      Article.load(:article_id => article_id).touch
    end
    
    def show_own_latest
    # {{{

      latest_article_id = Article.value_of.max(:article_id).with(Article.user_group_id == Aurita.user.user_group_id).to_i
      article = Article.load(:article_id => latest_article_id)

      @params[:article_id] = latest_article_id

      begin
        edit_inline_content_id = Container.select { |c| 
          c.where(Container.content_id_parent == article.content_id)
        }.first.asset.content_id
      rescue ::Exception => e
      end

      show(latest_article_id, edit_inline_content_id)

    end # }}}
    
    def show_pdf
    # {{{
      use_decorator :none

      article    = load_instance()
      return unless Aurita.user.may_view_content?(article)

      article_id = article.article_id
      hierarchy  = Article_Full_Hierarchy_Visitor.new(article).hierarchy
      decorator  = Article_Hierarchy_PDF_Decorator.new(hierarchy)
      decorator.run

      set_content_type('application/pdf')
      set_http_header('Content-Disposition' => ("attachment; filename=\"article_#{article_id}_#{article.max_version}.pdf\""))

      File.open("/tmp/article_#{article_id}.pdf").each { |l|
        puts l
      }
    end # }}}

    def decorate_article(article, viewparams={})
    # {{{
      hierarchy = Article_Full_Hierarchy_Visitor.new(article).hierarchy
      decorator = Article_Hierarchy_Default_Decorator.new(hierarchy)
      decorator.viewparams = viewparams
      HTML.div { decorator.string }
    end # }}}

    def show(article_id=nil, edit_inline_content_id=false)
    # {{{
      begin
        article    = load_instance()
        article_id = article.article_id
        begin
          if !article.is_a? Memo::Memo_Article then
            if Memo::Memo_Article.find(1).with(Memo::Memo_Article.article_id == article_id).entity then
              Aurita.import_plugin_controller :memo, :memo_article
              render_controller(Memo::Memo_Article_Controller, :show, :article_id => article_id)
              return
            end
          end
        rescue ::Exception => ignore
        end
      rescue ::Exception => e
        return HTML.div { tl(:article_does_not_exist) }
      end
      
      author = User_Profile.load(:user_group_id => article.user_group_id)
      article_id = article.article_id
      if(!Aurita.user.may_view_content?(article)) then
        return HTML.div { tl(:no_permission_to_access_article) } +
               HTML.div { tl(:article_owned_by_user).gsub('{1}', author.label) +
                          tl(:article_is_in_category).gsub('{1}', article.categories.map { |c| c.category_name }.join(', ')) }
      end

=begin
      if Aurita.user.may_edit_content?(article) && param(:edit_inline_content_id) then
        edit_inline_content_id = param(:edit_inline_content_id) unless edit_inline_content_id
        if param(:edit_inline_type) == 'TEXT_ASSET' then
          editable_text_asset = Text_Asset.select { |ta|
            ta.where(Text_Asset.content_id == edit_inline_content_id)
            ta.limit(1)
          }.first

          exec_js("Aurita.Editor.save_all(); ")
          redirect(:element           => "article_part_asset_#{editable_text_asset.asset_id}", 
                   :controller        => 'Wiki::Text_Asset', 
                   :action            => :update_inline, 
                   :asset_id          => editable_text_asset.asset_id, 
                   :content_id_parent => article.content_id, 
                   :text_asset_id     => editable_text_asset.text_asset_id)

        elsif param(:edit_inline_type == 'MEDIA_CONTAINER') then
          media_container = Media_Container.select { |ta|
            ta.where(Media_Container.content_id == edit_inline_content_id)
            ta.limit(1)
          }.first

          redirect(:element           => "article_part_asset_#{media_container.asset_id}", 
                   :controller        => 'Wiki::Media_Container', 
                   :action            => :update_inline, 
                   :asset_id_child    => media_container.asset_id, 
                   :content_id_parent => article.content_id, 
                   :asset_id          => media_container.asset_id)
        end
      end
=end
      exec_js("Aurita.Wiki.add_recently_viewed('Wiki::Article', '#{article.article_id}', '#{article.title.gsub("'",'&apos;').gsub('"','&quot;')}'); ")
      editable = Aurita.user.may_edit_content?(article)
      exec_js("Aurita.Wiki.init_article(#{article.article_id}, { editable: #{editable} });")
      
      viewparams = param(:viewparams).to_s.gsub(' ','')
      if !Aurita.user.is_registered? then
        viewparams << '--' unless viewparams.empty?
        viewparams << 'public--false'
      end

      result = HTML.div 
      if false && Article_Cache.exists_for(article, viewparams) then
        result = Article_Cache.read(article, viewparams)
      else
        result = decorate_article(article, viewparams)
        Article_Cache.create_for(article, viewparams) { result.string }
      end

      if Aurita.user.is_registered? then
        Article_Access.create(:user_group_id => Aurita.user.user_group_id, 
                              :article_id => article_id)
      end
      Tag_Relevance.add_hits_for(article)

      return result
    end # }}}

    def show_version(article_id=nil, version=nil)
    # {{{
      
      article_id = param(:article_id) unless article_id
      version    = param(:version)    unless version

      article = Article.load(:article_id => article_id)
      return unless Aurita.user.may_view_content?(article)

      version_entry = Article_Version.find(1).with((:article_id.is(article_id)) & 
                                                   (:version.is(version))).entity
      if !version_entry then
        puts tl(:no_such_version)
        return
      end

      decorator                     = Article_Dump_Default_Decorator.new(version_entry)
      decorator.viewparams          = param(:viewparams)
      decorator.templates[:article] = :article_version_decorator
      article_string = decorator.string
      puts article_string
    end # }}}

    def show_sortable
    # {{{

      article = Article.load(:article_id => param(:article_id))
      return unless Aurita.user.may_view_content?(article)

      hierarchy = Article_Full_Hierarchy_Visitor.new(article).hierarchy
      decorator = Article_Hierarchy_Sortable_Decorator.new(hierarchy)
      exec_js("Aurita.Wiki.init_article_reorder('#{article.content_id}');")
      puts decorator.string

    end # }}}

    def infobox_for(article_inst)
    # {{{
      view_history = Content_History.select { |ch|
        ch.join(User_Group).using(:user_group_id) { |chu|
          chu.where(Content_History.content_id == article_inst.content_id)
          chu.order_by(:time, :desc)
        }
      }
      
      author = User_Group.load(:user_group_id => article_inst.user_group_id)
      view_string(:content_infobox, 
                  :created_by_user => author,
                  :view_history    => view_history, 
                  :article         => article_inst)
    end # }}}

    def recent_changes_in_category(params={})
    # {{{

      clause = (Article.changed >= (Datetime.new - 7.days)) & 
               (Article.content_id.in(Content_Category.select(:content_id) { |cid| 
                   cid.where(Content_Category.category_id == params[:category_id]) 
               } ))
      article_list = list(clause, :limit => 30, :order => [ Article.changed, :desc ])
      return Element.new(:content => article_list) if article_list

    end # }}}

    def list(clause=:true, params={})
    # {{{

      order       = params[:order][0]
      order_dir   = params[:order][1]
      order     ||= :title
      order_dir ||= :asc
      articles = Article.all_with(clause & Article.accessible).ordered_by(order, order_dir)
      articles = articles.limit(params[:limit]) if params[:limit]
      articles = articles.entities
#     articles.delete_if { |a| 
#       !(Aurita.user.may_view_content?(a)) 
#     }
      assets = Hash.new
      return unless articles.first
      view_string(:article_list, 
                  :articles => articles, 
                  :assets => assets)
     
    end # }}}

    def list_all
    # {{{
      tag = param(:tag).downcase
      articles = Article.all_with(Article.tags.has_element(tag)).sort_by(:article_id, :asc).entities
      render_view(:article_list, :articles => articles)
    end # }}}
    
    def frontpage_article
    # {{{
      
      article = Article.find(1).with(Article.tags.has_element_like('frontpage')).entity
      return unless article
      hierarchy = Article_Full_Hierarchy_Visitor.new.visit_article(article)
      decorator = Article_Hierarchy_Default_Decorator.new(hierarchy)
      decorator.viewparams = 'public--false'
      article_string = decorator.string
      return HTML.div { article_string } 

    end # }}}

    def recently_changed_string
      articles = Article.find(5).sort_by(:changed, :desc).entities
      return view_string(:article_title_list, :articles => articles)
    end
    def recently_changed
      puts recently_changed_string()
    end
    
    def recently_viewed_string
      articles = Article_Access.of_user(Aurita.user.user_group_id, 5)
      articles = []
      view_string(:article_title_list, :articles => articles)
    end
    def recently_viewed
      puts recently_viewed_string
    end 
    
    def find_by_tag
      tag    = param(:tag)
      render_view(:article_list, 
                  :articles => Article.all_with(Article.tags.has_element(tag)).entities)
    end

    def perform_reorder
    # {{{
      article           = load_instance()
      positions         = param("article_body_#{article.article_id}", []).map { |v| v.to_i }
      content_id_parent = article.content_id
      Container.all_with(Container.content_id_parent == content_id_parent).ordered_by(:sortpos, :asc).to_a.each_with_index { |c, pos_count|
        c.sortpos = (positions.index(c.asset_id_child).to_i + 1)
        c.commit
      }
    end # }}}

    def list_recently_commented
    # {{{
      articles = Article.select { |ma|
        ma.join(Content_Comment).on(Article.content_id == Content_Comment.content_id) { |uma|
        uma.join(User_Group).on(Content_Comment.user_group_id == User_Group.user_group_id) { |cma|
            cma.where(true)
            cma.order_by(:time, :desc)
            cma.limit(30)
          }
        }
      }

      render_view(:article_list_recently_commented, 
                  :commented_articles => articles)
    end # }}}

    def recently_changed_box
    # {{{
      
      changed_articles = Box.new(:type => :none, :class => :topic, :id => 'changed_articles', :params => {})
      changed_articles.header = tl(:recently_changed_articles)
      changed_articles.body = recently_changed()
      return changed_articles

    end # }}}

    def recently_viewed_box
    # {{{

      viewed_articles = Box.new(:type => :none, :class => :topic, :id => 'viewed_articles', :params => {})
      viewed_articles.header = tl(:recently_viewed_articles)
      viewed_articles.body = recently_viewed_string
      return viewed_articles

    end # }}}

    def selection_choice
      field_name   = param(:name)
      field_name ||= 'article_ids[]'
      article      = Article.get(param(:article_id))
      GUI::Article_Selection_List_Entry.new(:article => article, :name => field_name)
    end

  end # class
  
end # module
end # module
end # module

