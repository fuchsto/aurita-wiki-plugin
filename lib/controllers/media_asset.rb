
require('aurita/controller')

Aurita::Main.import_model :content_comment
Aurita::Main.import_model :tag_relevance
Aurita::Main.import_model :content_access
Aurita.import_plugin_model :wiki, :media_asset
Aurita.import_plugin_model :wiki, :media_asset_version
Aurita.import_plugin_model :wiki, :media_asset_folder
Aurita.import_plugin_module :wiki, :media_asset_importer
Aurita.import_plugin_module :wiki, :media_meta_data
Aurita.import_plugin_module :wiki, :gui, :media_asset_version_list
Aurita.import_plugin_module :wiki, :gui, :media_asset_list
Aurita.import_plugin_module :wiki, :gui, :media_asset_selection_field
Aurita.import_plugin_module :wiki, :gui, :media_asset_grid

Aurita::Main.import_controller :content_comment
Aurita::Main.import_controller :category
Aurita.import_module :gui, :hierarchy_node_select_field
Aurita.import_module :gui, :multi_file_field
Aurita.import_module :gui, :multi_file_flash_field
Aurita.import_module :gui, :flash_upload_form_decorator

begin
  Aurita.import_plugin_model :bookmarking, :media_asset_bookmark
rescue ::Exception => ignore
end

module Aurita
module Plugins
module Wiki

  class Media_Asset_Controller < Plugin_Controller

    guard_interface(:delete, :update, :perform_delete, :perform_update, :edit_info, :move_to_folder) { 
      may_edit = true
      begin
        c = load_instance()
        may_edit = Aurita.user.may_edit_content?(c) if c
      rescue ::Exception => ignore
      end
      (Aurita.user.is_registered? && may_edit) 
    }
    guard_interface(:add, :perform_add, :empty_trash) { 
      Aurita.user.is_registered?
    }
    
    def form_groups
      [
       'upload_file[]', 
       Media_Asset.title, 
       Content.tags, 
       Category.category_id, 
       Media_Asset.description, 
       Media_Asset.media_folder_id, 
       Media_Asset.preview_media_asset_id, 
       :media_container_id
      ]
    end

    def form_hints
      { 
       'upload_file[]'                  => tl(:media_asset_file_hint),
       Media_Asset.title.to_s           => tl(:media_asset_title_hint), 
       Content.tags.to_s                => tl(:media_asset_tags_hint), 
       Category.category_id.to_s        => tl(:media_asset_category_hint), 
       Media_Asset.description.to_s     => tl(:media_asset_description_hint), 
       Media_Asset.media_folder_id.to_s => tl(:media_asset_folder_hint), 
      }
    end

    def toolbar_buttons
    # {{{
      if Aurita.user.may?(:approve_requested_files) then
        Text_Button.new(:icon   => :add_article, 
                        :action => 'Wiki::Media_Asset/approval_grid') { 
          tl(:approve_files) 
        } 
      end
    end # }}}

    def approval_list
    # {{{
      assets = Media_Asset.select { |m|
        m.join(Media_Asset_Request).on(Media_Asset_Request.media_asset_id == Media_Asset.media_asset_id) { |mr|
          mr.where(Media_Asset.has_category_in(Aurita.user.category_ids))
          mr.order_by(:time_requested, :desc)
        }
      }
      table   = GUI::Media_Asset_Table.new(assets)
      headers = [ HTML.th { '&nbsp;' }, 
                  HTML.th { tl(:approved) }, 
                  HTML.th { tl(:requested) }, 
                  HTML.th { tl(:description) }, 
                  HTML.th { tl(:filetype) }, 
                  HTML.th { tl(:filesize) }, 
                  HTML.th { tl(:created) }, 
                  HTML.th { tl(:changed) } ]
      table.headers = headers

      even = true
      table.rows.each { |r|
        r.add_css_class :even if even
        r.add_css_class :odd  if !even
        even = !even
      }

      Page.new(:id => :approve_files, :header => tl(:approve_files)) { 
        table
      }
    end # }}}

    def approval_grid
      assets = Media_Asset.select { |m|
        m.where((Media_Asset.has_category_in(Aurita.user.category_ids)) & 
                (Media_Asset.media_asset_id.in( 
                   Media_Asset_Request.select(:media_asset_id) { |mr| 
                     mr.where(true)
                   }
                )) & 
                (Media_Asset.deleted == 'f')
               )
        m.order_by(:media_asset_id, :desc)
      }.to_a

      Page.new(:id => :media_asset_approval_grid, :header => tl(:approve_files)) {
        GUI::Media_Asset_Grid.new(assets)
      }
    end

    def flash_upload
      instance = false
      begin
        file_uploaded   = param(:Filedata)
        title           = file_uploaded[:filename].to_s
        param[:title]   = title.split('.')[0..-2].join('.')
        param[:tags]    = param(:tags) +  ' ' + title.gsub('_',' ').gsub('-',' ').split(' ')
        if(param(:token)) then
          param[:user_group_id] = param(:token)
        end
        
        instance        = Media_Asset.create(@params)

        if param(:category_id) then
          instance.set_categories(param(:category_id));
        else
          instance.set_categories([ 100 ]);
        end

        raise ::Exception.new("Could not create Media_Asset instance") unless instance
        file_info = receive_file(file_uploaded)
        # file_info now stores information needed by Media_Asset_Importer 
        # to handle this file correctly (e.g. create previews, set file name
        # extension ...)
        
        Media_Asset_Importer.new(instance).import(file_info)
      rescue ::Exception => excep
        Aurita.log { 'Error in file upload: ' << excep.message } 
        excep.backtrace.each { |l| Aurita.log { l } } 
        begin
          instance.delete 
        rescue ::Exception => ignore
        end
        raise excep
      end
    end

    def recent_changes_in_category(params={}) 
    # {{{
      clause = (Media_Asset.changed >= (Datetime.new - 7.days)) & 
               (Media_Asset.content_id.in(Content_Category.select(:content_id) { |cid| 
                   cid.where(Content_Category.category_id == params[:category_id]) 
               } ))
      list_str = list(clause, :limit => 20, :order => [ Media_Asset.changed, :desc ])
      return Element.new(:content => list_str) if list_str
    end # }}}

    def recent_changes(params={})
      clause = ((Media_Asset.changed >= (Datetime.new - 7.days)) & Media_Asset.accessible)
      list_str = list(clause, :limit => 10, :order => [ Media_Asset.changed, :desc ], :mode => :table)
      return Element.new(:content => list_str) if list_str
    end

    def list(clause=Lore::Clause.new(true), params={})
    # {{{
      amount    = params[:limit]
      amount  ||= :all
      mode      = params[:mode]
      mode    ||= :grid
      order     = params[:order][0]
      order_dir = params[:order][1]
      order     ||= :created
      order_dir ||= :desc
      images    = Array.new
      # Important: Do not test permissions using Media_Asset.is_accessible? here. 
      # Pass this check as clause argument if needed, so we don't do it twice. 
      images    = Media_Asset.find(amount).with(clause & (Media_Asset.deleted == 'f'))
      images.order_by(order, order_dir) if order
      images    = images.entities
      return unless images.first

      return GUI::Media_Asset_Table.new(images) if mode == :table
      return GUI::Media_Asset_Grid.new(images) 
    end # }}}

    def list_category(params)
      clause = (Media_Asset.content_id.in(Content_Category.select(:content_id) { |cid| 
                   cid.where(Content_Category.category_id == params[:category_id]) 
               } ))
    # list_str = list(clause, :limit => 30, :order => [ Media_Asset.changed, :desc ])
      list_str = list(clause, :order => [ Media_Asset.changed, :desc ])
      return unless list_str
      body   = Element.new(:content => list_str) 
      box    = Box.new(:class => :topic_inline, 
                       :type => :none)
      box.body   = body
      box.header = tl(:recently_changed_files)
      return box
    end


    def find(params)
    # {{{
      key     = params[:key].to_s
      tags    = key.split(' ')
      limit   = params[:limit] 
      limit ||= :all
			constraints  = Wiki::Media_Asset.deleted == 'f'
      media        = Media_Asset.find(limit).with(constraints & 
                                                  (Media_Asset.has_tag(tags) & Media_Asset.accessible)
                                                 ).sort_by(Media_Asset.media_asset_id, :desc).entities
      return unless media.first

      box        = Box.new(:type => :none, :class => :topic_inline)
      box.header = tl(:media)
      box.body   = GUI::Media_Asset_Grid.new(media)
      return box
    end # }}}

    def find_all(params={})
      find(params)
    end
    alias find_full find_all

    # Use parameter :physically => true to really delete a file 
    # instead of just marking it as deleted. 
    def perform_delete(args={})
    # {{{
      asset = load_instance()
      media_asset_id = asset.media_asset_id
      if args[:physically] then
        super()
      else
        return unless ( asset.user_group_id == Aurita.user.user_group_id || Aurita.user.may?(:delete_foreign_files) || Aurita.user.is_admin? )
        asset.deleted = true
        Container.delete { |c|
          c.where(c.content_id_child == asset.content_id)
        }
        asset.commit()
      end
      exec_js("Aurita.Wiki.after_media_asset_delete(#{media_asset_id}); ")
    end # }}}

    def add_flash
    # {{{
      
    # TODO: Implement redirect to plain HTML upload form if flash is not installed: 
=begin
      if(no_flash) then
        redirect(:to => :add)
        return
      end
=end

      folder_id   = param(:media_asset_folder_id)
      folder_id ||= param(:media_folder_id)
      folder_id ||= Aurita.user.media_asset_folder_id
      form = add_form()

      form[:action].value = :flash_upload

      default_cats = [] 

      form[Media_Asset.media_folder_id] = GUI::Hierarchy_Node_Select_Field.new(:name  => Media_Asset.media_folder_id.to_s, 
                                                                               :label => tl(:folder), 
                                                                               :value => folder_id) 
      category = Category_Selection_List_Field.new()
      article  = false
      if param(:media_container_id) then
        article = Media_Container.get(param(:media_container_id)).article
        form.add(Hidden_Field.new(:name  => :media_container_id, 
                                  :value => param(:media_container_id))) 
      end
      
      if article then
        default_cats << article.category_id 
      else
        begin
          general_cat = Category.find(1).with(:special => :general).first
          default_cats << general_cat.category_id if general_cat
        rescue ::Exception => ignore
        end
      end

      category.value = default_cats
      
      file = GUI::Multi_File_Flash_Field.new(:id => :flash_upload_applet, :name => 'upload_file[]')
      
      form.add(file)
      form.add(category)
      form[Content.tags] = Tag_Autocomplete_Field.new(:name => Content.tags.to_s, :label => tl(:tags))
      form[Content.tags].required!
      form[Media_Asset.title] = nil
      
      element = GUI::Flash_Upload_Form_Decorator.new(form)
      element = Page.new(:header => tl(:upload_file)) { element } if param(:element) == 'app_main_content'

      return element
    end # }}}

    def add
    # {{{
      folder_id   = param(:media_asset_folder_id)
      folder_id ||= param(:media_folder_id)
      folder_id ||= Aurita.user.media_asset_folder_id
      form = add_form()

      form[Media_Asset.media_folder_id] = GUI::Hierarchy_Node_Select_Field.new(:name  => Media_Asset.media_folder_id.to_s, 
                                                                               :label => tl(:folder), 
                                                                               :value => folder_id) 
      category = Category_Selection_List_Field.new()
      if param(:media_container_id) then
        article        = Media_Container.get(param(:media_container_id)).article
        category.value = [ article.category_id ] if article
        form.add(Hidden_Field.new(:name  => :media_container_id, 
                                  :value => param(:media_container_id))) 
      end
      if param(:set_as_profile_image) then
        form.add(Hidden_Field.new(:name => :set_as_profile_image, :value => 1))
        form.fields << :set_as_profile_image
      end
      file = GUI::Multi_File_Field.new(:name => 'upload_file[]', :label => tl(:file))
      form.add(file)
      form.add(category)
      form[Content.tags] = Tag_Autocomplete_Field.new(:name => Content.tags.to_s, :label => tl(:tags))
      form[Content.tags].required!
      form['upload_file[]'].required!
      form[Media_Asset.title] = nil

      exec_js('Aurita.Main.init_autocomplete_tags();')

      element = GUI::Async_Upload_Form_Decorator.new(form)
      element = Page.new(:header => tl(:upload_file)) { element } if param(:element) == 'app_main_content'

      return element
    end # }}}

    def add_profile_image
      @params[:folder_id] = Aurita.user.folder_id
      @params[:set_as_profile_image] = 1
      add()
    end

    def after_add
      puts ' '
    end

    def update(title=nil)
    # {{{
      media_asset = load_instance()
      form = update_form()

      form[Media_Asset.media_folder_id] = GUI::Hierarchy_Node_Select_Field.new(:name => Media_Asset.media_folder_id.to_s, 
                                                                               :label => tl(:folder), 
                                                                               :value => media_asset.media_folder_id)
      form[Media_Asset.preview_media_asset_id] = GUI::Media_Asset_Selection_Field.new(:name  => Media_Asset.preview_media_asset_id.to_s, 
                                                                                      :label => tl(:preview_image), 
                                                                                      :value => media_asset.preview_media_asset_id, 
                                                                                      :mime_type  => :image)

      category = Category_Selection_List_Field.new()
      category.value = media_asset.category_ids

      form[Content.tags] = Tag_Autocomplete_Field.new(:name => Content.tags.to_s, :label => tl(:tags), :value => media_asset.tags)
      form[Content.tags].required!
      
      exec_js('Aurita.Main.init_autocomplete_tags();')
      form.add(category)

      # render_form(form, :title => title)
      
      form = decorate_form(form) 

      return form unless param(:element) == 'app_main_content'

      Page.new(:id => :approve_files, :header => tl(:edit_asset)) { 
        form
      }
    end # }}}
    def update_section
    # {{{
      update(load_instance.physical_path)
    end # }}}
    
    def delete
      form = delete_form
      form.fields = [
       'upload_file[]', 
       Media_Asset.title, 
       Content.tags, 
       Category.category_id, 
       Media_Asset.media_folder_id, 
       :media_container_id
      ]
      form[Media_Asset.media_folder_id].hidden = true
      form[Media_Asset.description].hidden = true
      render_form(form)
    end

    def unpack_archive
    # {{{
      form = model_form(:model => Media_Asset, :action => :perform_unpack_archive)
      form.add_hidden(Media_Asset.media_folder_id => param(:media_folder_id))
      form.add(Category_Selection_List_Field.new())
      file = File_Field.new(:name => :upload_file, :label => tl(:file))
      form.add(file)
      render_view(:media_asset_unpack_archive_form, 
                  :form => form.string)
    end # }}}

    def perform_add
    # {{{
      use_decorator :none

      begin
        instances = []
        inc_title = param(:title)
        tags      = param(:tags)

        param(:upload_file).each_with_index { |file_uploaded, idx|
          
          title           = "#{inc_title} #{idx}" if inc_title
          title         ||= file_uploaded[:filename] 
          param[:title]   = title
          param[:tags]    = tags
          instance        = super()

          raise ::Exception.new("Could not create Media_Asset instance") unless instance

          # Instance is created in DB but following attributes are 
          # not valid until set in Media_Asset_Importer: 
          #  - mime
          #  - mime_extension
          #  - fs_path
          #  - Any other attribute based on file type of this instance
          
          file_info = receive_file(file_uploaded)
          # file_info now stores information needed by Media_Asset_Importer 
          # to handle this file correctly (e.g. create previews, set file name
          # extension ...)
          
          Media_Asset_Importer.new(instance).import(file_info)
          # Now, after having imported the file via Media_Asset_Importer, 
          # we have a valid instance. 
          if param(:media_container_id) then
            Media_Container_Entry.create(:media_container_id => param(:media_container_id),
                                         :media_asset_id     => instance.media_asset_id)
          end
          
          instance.set_categories(param(:category_id))
          
          if param(:set_as_profile_image) then
            User_Profile.update { |u|
              u.set(:picture_asset_id => instance.media_asset_id)
              u.where(User_Profile.user_group_id == Aurita.user.user_group_id)
            }
          end
          instances << instance
        }
        return instances
      rescue ::Exception => excep
        log { 'Error in file upload: ' << excep.message } 
        excep.backtrace.each { |l| log { l } } 
        begin
          instance.delete 
        rescue ::Exception => ignore
        end
        raise excep
      end
    end # }}}

    def perform_update
    # {{{
      super()
      media_asset = load_instance()
      media_asset.set_categories(param(:category_id))

      # exec_js("Aurita.flash('#{tl(:changes_have_been_saved)}');")

      redirect_to(media_asset)
    end # }}}

    def perform_unpack
    # {{{
      STDERR.puts 'UNZIP 1: ' << param(:media_folder_id).inspect + ' - ' << param(:tags).inspect
      @params[:user_group_id] = Aurita.user.user_group_id
      @params[:user_submitted] = 't' unless Aurita.user.is_admin?
      @params[:created] = Aurita::Datetime.now(:sql)

      media_folder = Media_Asset_Folder.load(:media_asset_folder_id => param(:media_folder_id))
      tags = media_folder.physical_path.downcase.split(' ')
      tags += param(:tags).to_s.split(' ') unless param(:tags).to_s == ''
      tags = tags.join(' ')

      file_info = upload_file(:form_file_tag_name => :upload_file, 
                              :relative_path => '' )

      Media_Asset_Importer.new(file_info).import_zip(file_info[:server_filepath], media_folder.media_asset_folder_id, tags)
      FileUtils.rm(file_info[:server_filepath])
    end # }}}

    def async_upload
    # {{{
      log('ASYNC UPLOAD')
      log('ASYNC UPLOAD PARAMS: ' << @request.get_params.inspect)

      media_folder_id = @request.get_params['media_folder_id']
      user_group_id   = @request.get_params['user_group_id']
      if param(:action) == 'getMaxFilesize' then
        puts '&maxFileSize=100M'
      else
        log('RUNNING ASYNC UPLOAD')
        server_filename = @request.params['Filename'].first
        if server_filename.instance_of? Tempfile then
          File.chmod(0777, server_filename.local_path)
          server_filename = server_filename.read
        elsif server_filename.instance_of? StringIO then
          server_filename = server_filename.read
        end
        
        file_info = upload_file(:form_file_tag_name => 'Filedata', 
                                :relative_path => 'up', 
                                :server_filename => server_filename)
        server_filename = file_info[:server_filename]
                                
        instance = Media_Asset.create(:mime => file_info[:type], 
                                      :tags => 'global ' + file_info[:type].to_s.gsub('application/x-','').gsub('/',' '), 
                                      :media_folder_id => media_folder_id, 
                                      :description => server_filename.to_s.split('/')[-1], 
                                      :user_group_id => user_group_id, 
                                      :created => Aurita::Datetime.now(:sql))
       
        log('File info for uploaded file: ' << file_info.inspect)
        log('Moving from ' << file_info[:server_filepath].to_s)
        log('To ' << Aurita.project_path + 'public/assets/asset_' + instance.media_asset_id.to_s + '.' << file_info[:type].split('/')[-1].gsub('x-',''))

        FileUtils.move(file_info[:server_filepath], 
                       Aurita.project_path + 'public/assets/asset_' + instance.media_asset_id.to_s + '.' << file_info[:type].split('/')[-1].gsub('x-',''))

        log('ASYNC UPLOAD DONE')
        id = instance.media_asset_id
        extension = '.' << instance.mime_extension
        if instance.is_image? then
          log('IMAGE: Resizing')
          # ==========================================================
          # TODO: temporary fix until edit-history is implemented...
          img = ImageList.new(Aurita.project_path + 'public/assets/asset_' << id + extension)
      #    img.resize_to_fit!(600, 600)
          img.write(Aurita.project_path + 'public/assets/asset_' << id + '.jpg')
          # end block =================================================
          instance['mime'] = 'image/jpg'
          instance.commit

          FileUtils.copy(Aurita.project_path + 'public/assets/asset_' << id + '.jpg', 
                         Aurita.project_path + 'public/assets/tmp/asset_' << id + '.jpg')
          FileUtils.copy(Aurita.project_path + 'public/assets/tmp/asset_' << id + '.jpg', 
                         Aurita.project_path + 'public/assets/tmp/asset_' << id + '_show.jpg')
          FileUtils.copy(Aurita.project_path + 'public/assets/tmp/asset_' << id + '.jpg', 
                         Aurita.project_path + 'public/assets/tmp/asset_' << id + '_work.jpg')
          FileUtils.copy(Aurita.project_path + 'public/assets/tmp/asset_' << id + '.jpg', 
                         Aurita.project_path + 'public/assets/tmp/asset_' << id + '_org.jpg')
          save_uploaded_image(id, 0)
        elsif instance.is_movie? and instance.mime != 'application/x-flv' then
          system('ffmpeg -i ' << instance.fs_path + ' ' << Aurita.project_path + 'public/assets/asset_' << id + '.flv')
          FileUtils.remove(instance.fs_path)
          instance['mime'] = 'application/x-flv'
          instance.commit 
        end
      end
      puts 'OK'
    end # }}}
    
    def perform_bookmark
      Media_Asset_Bookmark.create(:user_group_id => Aurita.user.user_group_id, 
                                  :media_asset_id => param(:media_asset_id))
    end

    def perform_reorder
      puts param(:media_asset_sortable_list_body).inspect
      param(:media_asset_sortable_list_body).each_with_index { |media_asset_id,position|
        Media_Asset.update { |m| 
          m.set(:sortpos => position)
          m.where(:media_asset_id => media_asset_id)
        }
      }
    end

    def proxy
    # {{{
      use_decorator(:none)
    
      asset_req  = param(:asset).to_s.split('.')
      asset_id   = asset_req[0]
      asset_id ||= param(:media_asset_id)
      asset_id ||= param(:id)
      asset      = Media_Asset.load(:media_asset_id => asset_id) if asset_id
      asset    ||= load_instance()
      asset_id ||= asset.media_asset_id

      version    = param(:version).to_i

      if Aurita.user.may_download_file?(asset) then

        Media_Asset_Download.create(:media_asset_id => asset_id, 
                                    :user_group_id  => Aurita.user.user_group_id)
        
        filename   = asset.title.to_s.gsub(' ','_')
        filename   = 'download' if filename.to_s == ''

        if version > 0 && version < asset.version then
          version_entity = Media_Asset_Version.find(1).with(:media_asset_id => asset.media_asset_id, 
                                                            :version        => version).entity
          filename  << " v#{version}" 
          filename  << ".#{version_entity.extension}"
          send_file("/assets/#{asset.filename(:version => version_entity)}", :filename => filename)
        else
          filename  << ".#{asset.extension}"
          send_file("/assets/#{asset.filename}", :filename => filename)
        end
      else 
        set_http_status(403)
      end
    end # }}}

    def icon
      m = load_instance()
      HTML.div(:class => "media_asset_thumbnail #{param(:size)}") { 
        m.icon(param(:size)) 
      } 
    end

    def show_latest
      show(Media_Asset.latest_of_user.media_asset_id)
    end
   
    def after_file_upload
      media_asset = Media_Asset.latest_of_user
      return unless media_asset
      render_view(:after_file_upload, :media_asset => media_asset)
    end

    def show(media_asset_id=nil)
    # {{{
      content_expires = Time.now + (10 * 24 * 60 * 60)

      media_asset = load_instance()
      return unless media_asset 
      media_asset_id = media_asset.media_asset_id

      if media_asset.deleted then
        return HTML.div.warning_box { tl(:file_has_been_deleted) }
      end

      author = User_Profile.load(:user_group_id => media_asset.user_group_id)
      if(!Aurita.user.may_view_content?(media_asset)) then
        return HTML.span { tl(:no_permission_to_access_content) } 
      end
      
      # media_asset.increment_hits
      owner_user_group = User_Profile.find(1).with(User_Group.user_group_id == media_asset.user_group_id).entity
      media_asset_comments = render_controller(Content_Comment_Controller, :box, :content_id => media_asset.content_id)

      Tag_Relevance.add_hits_for(media_asset)

      Content_Access.create(:content_id    => media_asset.content_id, 
                            :user_group_id => Aurita.user.user_group_id, 
                            :res_type      => 'MEDIA_ASSET')

      versions = []
      if media_asset.user_group_id == Aurita.user.user_group_id || Aurita.user.may?(:view_foreign_media_versions) then
        versions = Media_Asset_Version.select { |v| 
          v.join(Media_Asset).using(:media_asset_id) { |ma| 
            ma.where(Media_Asset_Version.media_asset_id == media_asset_id)
            ma.order_by(Media_Asset_Version.version, :desc)
          }
        }.to_a
      end
      current_version  = Media_Asset_Version.create_shallow(:media_asset_id    => media_asset.media_asset_id, 
                                                            :mime              => media_asset.mime, 
                                                            :version           => media_asset.version, 
                                                            :timestamp_created => media_asset.changed, # not 'created'
                                                            :user_group_id     => media_asset.user_group_id)

      versions = [ current_version ] + versions

      media_asset_tags = view_string(:editable_tag_list, :content => media_asset)

      render_view(:media_asset_info, 
                  :owner_user_group     => owner_user_group, 
                  :media_asset          => media_asset, 
                  :content_tags         => media_asset_tags, 
                  :media_asset_versions => GUI::Media_Asset_Version_List.new(versions), 
                  :asset_folder_path    => media_asset.folder_path, 
                  :download_stats       => render_controller(Media_Asset_Download_Controller, :box, :media_asset_id => media_asset.media_asset_id), 
                  :content_comments     => media_asset_comments)

      Tag_Relevance.add_hits_for(media_asset)

      exec_js("Aurita.Wiki.add_recently_viewed('Wiki::Media_Asset', '#{media_asset.media_asset_id}', '#{media_asset.title.gsub("'",'&apos;').gsub('"','&quot;')}'); ")
    end # }}}

    def show_latest_user_pics
    # {{{
      latest_pics = Media_Asset.find(15).with((Media_Asset.user_submitted == 't') & (Media_Asset.deleted == 'f')).order_by(:created, :desc).entities
      view_string(:media_asset_smallthumbs_list, 
                  :media_asset_folders => [], 
                  :media_assets => latest_pics)
    end # }}}

    def show_metadata
      media_asset = load_instance()
      exif = Media_Meta_Data.new(media_asset).exif
      table = GUI::Table.new(:class   => [ :listing_2_columns ], 
                             :headers => [ tl(:exif_entry), tl(:exif_value) ])
      exif.each_pair { |k,v|
        table.add_row(HTML.b { k },v) unless [ 'NativeDigest', 'UserComment' ].include?(k)
      }
      table
    end

    def edit_info
    # {{{
      media_asset = Media_Asset.load(:media_asset_id => param(:media_asset_id))
      form = update_form
      form.set_readonly(Content.created, Content.changed, Content.user_group_id, Media_Asset.mime)
      form.add(Category_Selection_List_Field.new(:value => media_asset.category_ids))
      render_view(:media_asset_edit_info, 
                  :media_asset => media_asset, 
                  :form => form.string)
    end # }}}
    
    def manage()
      render_view(:media_asset_upload)
    end

    def choose_from_user_folders
    # {{{
      folder_select_box = GUI::Media_Folder_Select_Field.new(:name => :media_asset_folder_select, 
                                                             :first_option_label => "-- #{tl(:home_directory)} --", 
                                                             :first_option_value => Aurita.user.home_dir.media_asset_folder_id, 
                                                             :parent_id => Aurita.user.home_dir.media_asset_folder_id) 
      images = Media_Asset.all_with((Media_Asset.media_folder_id == Aurita.user.home_dir.media_asset_folder_id) & 
                                    (Media_Asset.deleted == 'f') & 
                                    (Media_Asset.is_accessible) &
                                    (Media_Asset.mime.ilike('image/%'))).entities
      decorator = Proc.new { |e, element|
        element[0].onclick = "Aurita.Wiki.select_media_asset_click('#{e.media_asset_id}', '#{param(:image_dom_id)}');"
        element[0].add_css_class(:link)
        element
      }
      grid = GUI::Media_Asset_Grid.new(images, :thumbnail_size => :tiny, :decorator => decorator)
      
      render_view(:user_media_management_select, 
                  :folder_content    => grid, 
                  :folder_select_box => folder_select_box, 
                  :image_dom_id      => param(:image_dom_id))
    end # }}}

    def list_folder
    # {{{
      images = Array.new
      if param(:media_asset_folder_id) then
        images = Media_Asset.all_with((Media_Asset.media_asset_folder_id == params[:media_asset_folder_id]) &
                                      (Media_Asset.deleted = 'f')).entities
      end
      
      trashbin = Media_Asset_Folder.find(1).with((Media_Asset_Folder.user_group_id == Aurita.user.user_group_id) & 
                                                 (Media_Asset_Folder.trashbin == 't')).entity 

      public_folders  = Media_Asset_Folder.public_folders_root()
      private_folders = Media_Asset_Folder.private_folders_root()
      
      render_view(:media_management, 
                  :media_assets => images, 
                  :user => Aurita.user, 
                  :trashbin_folder => trashbin, 
                  :private_folders => private_folders, 
                  :public_folders => public_folders)
    end # }}}
    
    def list_selected()
    # {{{
      text_asset_content_id = param(:content_id)
      pre_select_media_assets = Media_Asset.select { |ma|
        ma.where(Media_Asset.content_id.in(
            Container.select(Container.content_id_child) { |cid|
              cid.where(cid.content_id_parent == text_asset_content_id)
            })
        )
      }
      render_view(:media_asset_selected_list,  
                  :selected_media_assets => pre_select_media_assets)
      
    end # }}}

    def choice_list(args={})
    # {{{
      selected = args[:selected]
      text_asset = args[:text_asset]
      text_asset_content_id = 0
      text_asset_content_id = text_asset.content_id if text_asset
      
      selected = selected.map { |media_asset|
        GUI::Media_Asset_Selection_Thumbnail.new(media_asset, :size => :tiny).to_s
      }
      
      images = Array.new
      if param(:media_asset_folder_id) then
        images = Media_Asset.all_with(Media_Asset.media_asset_folder_id == param(:media_asset_folder_id)).entities
      end

      view_string(:media_asset_choice_list, 
                  :media_assets => images, 
                  :text_asset_content_id => text_asset_content_id, 
                  :selected_media_assets => selected)
    end # }}}

    def move_to_folder()
    # {{{
      asset = Media_Asset.load(:media_asset_id => param(:media_asset_id).gsub('image_drag__',''))
      asset[:media_folder_id] = param(:media_folder_id).gsub('folder_','')
      asset.commit
    end # }}}
    
    def empty_trash() 
    # {{{
      trashbin = Media_Asset_Folder.find(1).with((Media_Asset_Folder.user_group_id == Aurita.user.user_group_id) & 
                                       (Media_Asset_Folder.trashbin == 't')).entity
      Media_Asset.all_with(Media_Asset.media_folder_id == trashbin.media_asset_folder_id).each { |a|
        a.delete
      }
    end # }}}


    def editor_insert_dialog()
      use_decorator(:async)

      form = GUI::Form.new(:id => :editor_insert_file_form) 
      form.add_css_class(:wide)

      form.add(GUI::Media_Asset_Selection_Field.new(:name       => :media_asset, 
                                                    :key        => :media_asset_id, 
                                                    :variant    => true, 
                                                    :label      => tl(:select_file), 
                                                    :row_action => 'Wiki::Media_Asset/editor_list_variant_choice', 
                                                    :id         => :media_asset))

      element = decorate_form(form, 
                              :buttons => Proc.new { |btn_params|
                                Text_Button.new(:class   => :submit, 
                                                :onclick => "$('message_box').hide();", 
                                                :icon    => 'button_ok.gif', 
                                                :label   => tl(:close))
                              })
      element.add_css_class(:wide)
      element
    end

    def editor_list_choice
      variant   = param(:variant)
      variant ||= Aurita::Project_Configuration.article_inserted_image_variant
      select_list = render_controller(Media_Asset_Folder_Controller, :list_choice, @params)
      select_list.row_onclick = Proc.new { |m| "Aurita.Wiki.insert_file('#{m.media_asset_id}', '#{variant}'); " } 
      select_list.rebuild
      select_list
    end

    def editor_list_variant_choice
      clause = (Media_Asset.deleted == 'f')
      param(:key).to_s.split(' ').each { |key|
        clause = clause & 
                 (Media_Asset.tags.has_element_ilike("#{key}%") | 
                  Media_Asset.title.ilike("#{key}%")) & 
                 (Media_Asset.accessible) & 
                 (Content.deleted == 'f')
      }
      assets = Media_Asset.find(15).with(clause).sort_by(:media_asset_id, :desc).entities
      select_list = GUI::Media_Asset_Select_Variant_List.new(assets)
      select_list.onselect = Proc.new { |m,variant| "Aurita.Wiki.insert_file('#{m.media_asset_id}', #{variant}); " } 
      select_list.rebuild
      select_list
    end

    def selection_list_choice
      return HTML.div { } unless param(:key).to_s.length > 2
      
      list_id       = param(:list_id)
      field_name    = params[:name]
      field_name  ||= 'media_asset_ids'
      # Returns configured GUI::Media_Asset_Select_List
      select_list = render_controller(Media_Asset_Folder_Controller, :list_choice, @params)
      select_list.row_onclick = Proc.new { |m| "Aurita.Wiki.media_asset_selection_list_onclick({ media_asset_id: '#{m.media_asset_id}', 
                                                                                                 selection_list_id: '#{list_id}', 
                                                                                                 label: '#{m.title}', 
                                                                                                 name: '#{field_name}'
                                                                                               }); " } 
      select_list.rebuild
      select_list
    end

    def selection_choice
      return HTML.div { } unless param(:key).to_s.length > 2
      
      list_id       = param(:list_id)
      field_name    = params[:name]
      field_name  ||= 'media_asset_ids'
      # Returns configured GUI::Media_Asset_Select_List
      select_list = render_controller(Media_Asset_Folder_Controller, :list_choice, @params)
      select_list.row_onclick = Proc.new { |m| "$('#{list_id}').innerHTML = ''; 
                                                Aurita.Wiki.media_asset_selection_list_onclick({ media_asset_id: '#{m.media_asset_id}', 
                                                                                                 selection_list_id: '#{list_id}', 
                                                                                                 label: '#{m.title}', 
                                                                                                 name: '#{field_name}'
                                                                                               }); " } 
      select_list.rebuild
      select_list
    end

    def editor_list_link_choice
      return HTML.div { } unless param(:key).to_s.length > 2
      
      # Returns configured GUI::Media_Asset_Select_List
      select_list = render_controller(Media_Asset_Folder_Controller, :list_choice, @params)
      select_list.row_onclick = Proc.new { |m| "Aurita.Wiki.link_to_file('#{m.media_asset_id}'); $('message_box').hide(); " } 
      select_list.rebuild
      select_list
    end

    def editor_list_download_link_choice
      return HTML.div { } unless param(:key).to_s.length > 2
      
      # Returns configured GUI::Media_Asset_Select_List
      select_list = render_controller(Media_Asset_Folder_Controller, :list_choice, @params)
      select_list.row_onclick = Proc.new { |m| "Aurita.Wiki.link_to_file_download('#{m.media_asset_id}'); $('message_box').hide(); " } 
      select_list.rebuild
      select_list
    end

    def viewer_info
      ma_id       = param(:media_asset_id)
      media_asset = Media_Asset.get(ma_id)
      return unless media_asset

      set_content_type('text/xml')
      use_decorator(:none)

      pages = []
      idx   = 0 
      host  = Aurita.project.host
      host  = "http://#{host}" unless host.include?('://')
      
      while File.exists?(Aurita.project.base_path + "public/assets/asset_#{ma_id}-#{idx}.png") do
        pages << host + "/aurita/assets/asset_#{ma_id}-#{idx}.png"
        idx += 1
      end
      XML::Document.new { 
        XML.meta { 
          XML.pages { 
            pages.map { |p| XML.page { "<![CDATA[#{p}]]>" } }
          } 
        }
      }
    end

  end

end
end
end

