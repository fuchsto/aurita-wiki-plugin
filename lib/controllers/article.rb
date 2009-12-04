
require('aurita/plugin_controller')
Aurita::Main.import_model :content_history
Aurita::Main.import_model :content_category
Aurita::Main.import_model :tag_relevance

Aurita.import_plugin_model :wiki, :article
Aurita.import_plugin_model :wiki, :container
Aurita.import_plugin_model :wiki, :text_asset
Aurita.import_plugin_model :wiki, :media_asset
# Aurita.import_plugin_model :wiki, :form_asset
Aurita.import_plugin_model :wiki, :article_version
Aurita.import_plugin_model :wiki, :article_access
Aurita.import_plugin_module :wiki, :article_cache
Aurita.import_plugin_module :wiki, :article_hierarchy_visitor
Aurita.import_plugin_module :wiki, :article_full_hierarchy_visitor
Aurita.import_plugin_module :wiki, :article_hierarchy_default_decorator
Aurita.import_plugin_module :wiki, :article_hierarchy_pdf_decorator
Aurita.import_plugin_module :wiki, :article_dump_default_decorator
Aurita.import_plugin_module :wiki, :article_hierarchy_sortable_decorator

Aurita.import_plugin_model :memo, :memo_article

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

    def hierarchy_entry_type
      { 
        :name       => 'ARTICLE', 
        :label      => tl(:article), 
        :request    => 'Wiki::Article_Selection_Field', 
        :form_field => GUI::Input_Field.new(:type  => :text, 
                                            :name  => :article_id, 
                                            :label => tl(:article), 
                                            :value => 'article field')
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

      return unless Aurita.user.is_in_category?(params[:category_id])
=begin
# TODO: Use as test case! 

      articles = Article.select { |a|
        a.join(Article_Version).on((Article.article_id == Article_Version.article_id) & (Article_Version.version == Article.version)) { |av|
          av.join(Content_Category).on(Article.content_id == Content_Category.content_id) { |ac|
            ac.join(User_Group).on(Article_Version.user_group_id == User_Group.user_group_id) { |au|
              au.where((Content_Category.category_id == params[:category_id]))
              au.order_by(Article.title, :asc)
            }
          }
        }
      }
=end
      articles = Article.select { |a|
        a.join(Content_Category).on(Article.content_id == Content_Category.content_id) { |ac|
          ac.where((Content_Category.category_id == params[:category_id]))
          ac.order_by(Article.changed, :desc)
        }
      }
      article_box        = Box.new(:class => :topic_inline, 
                                   :type => :none)
      body = view_string(:article_list, :articles => articles)
      article_box.body   = body
      article_box.header = tl(:articles)
      return article_box

    end # }}}

    def toolbar_buttons
    # {{{

      result = []
      if Aurita.user.may(:create_articles) then
        add_article = HTML.a(:class => :icon, 
                             :onclick => link_to(:add)) { 
          icon_tag(:article_add) + tl(:write_new_article) 
        } 
        result << add_article 
      end

      return result

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
      Article.all_with((Article.has_tag(key.to_s.split(' ')) | Article.title.ilike("%#{key}%")) & Article.in_category(category.category_id)).entities
    end

    def find_all(params)
    # {{{

      return unless params[:key]
      key = params[:key].to_s
      tags = key.split(' ')
      articles = Article.all_with((Article.has_tag(tags) | 
                                   Article.title.ilike("%#{key}%")) &
                                  Article.is_accessible).sort_by(Wiki::Article.title, :desc).entities
      return unless articles.first
      box = Box.new(:type => :none, :class => :topic_inline)
      box.body = view_string(:article_list, :articles => articles)
      box.header = tl(:articles)
      return box

    end # }}}

    def find_full(params)
    # {{{

      key   = params[:key].to_s.strip
      tags  = key.split(' ')
      tag   = "%#{tags.last}%"

      constraints = Article.title.ilike(tag)
      articles    = Article.all_with((Article.has_tag(tags) | 
                                      Article.title.ilike("%#{key}%")
                                     ) & 
                                     Article.is_accessible).sort_by(Wiki::Article.article_id, :desc).entities

      key.to_named_html_entities!
      articles   += Article.all_with(Article.is_accessible & Article.content_id.in(
                                       Container.select(Container.content_id_parent) { |cid|
                                         cid.join(Text_Asset).on(Container.asset_id_child == Text_Asset.asset_id) { |ta|
                                           ta.where(Text_Asset.text.ilike("%#{key}%"))
                                         }}
                                     )).sort_by(Article.article_id, :desc).entities


      return unless articles.first

      box        = Box.new(:type => :none, :class => :topic_inline)
      box.body   = view_string(:article_list, :articles => articles)
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

      form = add_form()
      form.add(Category_Selection_List_Field.new())
      form[Content.tags] = Tag_Autocomplete_Field.new(:name => Content.tags, :label => tl(:tags))
      form[Content.tags].required!
      exec_js('Aurita.Main.init_autocomplete_tags();')
      Page.new(:header => tl(:create_article)) { decorate_form(form) }

    end # }}}

    def update
    # {{{
      
      article  = load_instance()
      form     = model_form(:model => Article, :instance => article, :action => :perform_update)
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

      render_form(form)

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
      Content_Category.create_for(article, param(:category_ids))

      @params.set('public.text_asset.text', tl(:text_asset_blank_text))
      @params.set('public.article.content_id', article.content_id)
      text_asset = Text_Asset_Controller.new(@params).perform_add()

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
      article = load_instance()
      content_id = article.content_id
      Content_Category.update_for(article, param(:category_ids))

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

    def perform_publish
    # {{{

      article = Article.load(:article_id => param(:article_id))
      content_category = Content_Category.all_with(Content_Category.content_id == article.content_id).each { |c|
        c['category_id'] = param(:category_id)
        c.commit
      }

    end # }}}

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
      return unless Aurita.user.may_view_content?(article.content_id)

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

    def decorate_article(article, viewparams=nil)
    # {{{
      hierarchy = Article_Full_Hierarchy_Visitor.new(article).hierarchy
      decorator = Article_Hierarchy_Default_Decorator.new(hierarchy)
      decorator.viewparams = viewparams
      decorator.string
    end # }}}

    def show(article_id=nil, edit_inline_content_id=false)
    # {{{
      begin
        article    = load_instance()
        article_id = article.article_id
        if !article.is_a? Memo::Memo_Article then
          if Memo::Memo_Article.find(1).with(Memo::Memo_Article.article_id == article_id).entity then
            Aurita.import_plugin_controller :memo, :memo_article
            render_controller(Memo::Memo_Article_Controller, :show, :article_id => article_id)
            return
          end
        end
      rescue ::Exception => e
        puts tl(:article_does_not_exist)
        return
      end
      
      author = User_Profile.load(:user_group_id => article.user_group_id)
      article_id = article.article_id
      if(!Aurita.user.may_view_content?(article.content_id)) then
        puts HTML.div { tl(:no_permission_to_access_article) }
        puts HTML.div { tl(:article_owned_by_user).gsub('{1}', author.label) +
                        tl(:article_is_in_category).gsub('{1}', article.category.category_name) }
        return
      end

      if param(:edit_inline_content_id) then
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
      exec_js("Aurita.Wiki.add_recently_viewed('Wiki::Article', '#{article.article_id}', '#{article.title.gsub("'",'&apos;').gsub('"','&quot;')}'); ")
      
      viewparams = param(:viewparams).to_s.gsub(' ','')
      if !Aurita.user.is_registered? then
        viewparams << '--' unless viewparams.empty?
        viewparams << 'public--false'
      end

      if false && Article_Cache.exists_for(article, viewparams) then
        article_string = Article_Cache.read(article, viewparams)
      else
        article_string = decorate_article(article, viewparams)
        Article_Cache.create_for(article, viewparams) { article_string }
      end

      result = article_string

      if Aurita.user.is_registered? then
      #  result << render_controller(Content_Comment_Controller, :box, :content_id => article.content_id).string
      end

      puts result
      
      if Aurita.user.is_registered? then
        Article_Access.create(:user_group_id => Aurita.user.user_group_id, 
                              :article_id => article_id)
      end
      Tag_Relevance.add_hits_for(article)

    end # }}}

    def show_version(article_id=nil, version=nil)
    # {{{
      
      article_id = param(:article_id) unless article_id
      version    = param(:version)    unless version

      article = Article.load(:article_id => article_id)
      return unless Aurita.user.may_view_content?(article.content_id)

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
      return unless Aurita.user.may_view_content?(article.content_id)

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
      article_list = list(clause, :order => [ Article.changed, :desc ])
      return Element.new(:content => article_list) if article_list

    end # }}}

    def list(clause=:true, params={})
    # {{{

      order       = params[:order][0]
      order_dir   = params[:order][1]
      order     ||= :title
      order_dir ||= :asc
      articles = Article.all_with(clause).ordered_by(order, order_dir).entities
      articles.delete_if { |a| 
        !(Aurita.user.may_view_content?(a)) 
      }
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
      
      positions         = param(:article_partials_list, []).map { |v| v.to_i }
      content_id_parent = param(:content_id_parent)
      Container.all_with(Container.content_id_parent == content_id_parent).ordered_by(:sortpos, :asc).to_a.each_with_index { |c, pos_count|
        c.sortpos = (positions.index(c.asset_id_child).to_i + 1)
        c.commit
      }
      Article.find(1).with(Article.content_id == content_id_parent).entity.touch

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
      viewed_articles.body = recently_viewed()
      return viewed_articles

    end # }}}

  end # class
  
end # module
end # module
end # module

