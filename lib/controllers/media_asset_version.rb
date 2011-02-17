
require('aurita/plugin_controller')
Aurita.import_plugin_module :wiki, :media_asset_importer
Aurita.import_plugin_model :wiki, :media_asset
Aurita.import_plugin_model :wiki, :media_asset_version

module Aurita
module Plugins
module Wiki

  class Media_Asset_Version_Controller < Plugin_Controller
    
    def form_groups
      [
        Media_Asset.media_asset_id, 
        :upload_file
      ]
    end

    def add
      media_asset = Media_Asset.load(:media_asset_id => param(:media_asset_id))
      return unless media_asset

      form = add_form()
      form.fields = form_groups()
      form.add(Hidden_Field.new(:name  => Media_Asset.media_asset_id.to_s, 
                                :value => param(:media_asset_id)))
      file = File_Field.new(:name  => :upload_file, 
                            :label => tl(:file))
      form.add(file)

      GUI::Async_Upload_Form_Decorator.new(form)
    end
  
    def perform_add
      use_decorator(:iframe)
      
      log('Media_Asset_Version: Adding')
      instance = false
      begin
        base_media_asset = Media_Asset.load(:media_asset_id => param(:media_asset_id))
        file_info        = receive_file(param(:upload_file))
        
        instance         = Media_Asset_Version.create(:media_asset_id => param(:media_asset_id), 
                                                      :user_group_id  => Aurita.user.user_group_id)
        
        Media_Asset_Importer.new(base_media_asset).import_new_version(:file           => file_info, 
                                                                      :version_entity => instance)
        return instance
      rescue ::Exception => excep
        log.error('Media_Asset_Version: ' << excep.message)
        log.error('Media_Asset_Version: ' << excep.backtrace.join("\nMedia_Asset_Version: "))
        instance.delete if instance
        raise excep
      end
    end

    def rollback
      render_view(:confirm_rollback, 
                  :media_asset_version_id => param(:media_asset_version_id))
    end

    def delete
    end

    def perform_delete
    end

    def perform_rollback
      logger = Aurita::Log::Class_Logger.new(self.to_s)
      logger.log('VERSION: Adding')
      begin
        ma_version       = Media_Asset_Version.load(:media_asset_version_id => param(:media_asset_version_id))
        base_media_asset = Media_Asset.load(:media_asset_id => ma_version.media_asset_id)
        # Version number we are reactivating
        old_version      = (ma_version.version.to_i) 
        # Next version number for this asset
        new_version      = (base_media_asset.version.to_i+1)
        base_media_asset.version = new_version
        base_media_asset.commit
        instance = Media_Asset_Version.create(:media_asset_id => ma_version.media_asset_id, 
                                              :user_group_id => Aurita.user.user_group_id, 
                                              :version => new_version)
        importer = Media_Asset_Importer.new(base_media_asset)
        importer.rollback_version(old_version)

        base_media_asset.touch

        redirect_to(base_media_asset)
      rescue ::Exception => excep
        logger.log('VERSION: ' << excep.message)
        logger.log('VERSION: ' << excep.inspect)
        logger.log('VERSION: ' << excep.backtrace.join("\nVERSION: "))
      end
    end

  end

end
end
end
