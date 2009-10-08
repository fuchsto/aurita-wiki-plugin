
require('aurita/model')
require('RMagick') # Require manually in dispatch runner if needed (big lib!)

Aurita::Main.import_model :content
Aurita.import_plugin_model :wiki, :asset
Aurita.import_plugin_model :wiki, :media_asset_folder

module Aurita
module Plugins
module Wiki

  class Media_Asset < Asset

    table :media_asset, :public
    primary_key :media_asset_id, :media_asset_id_seq
    
    is_a Asset, :asset_id
    has_a Media_Asset_Folder, :media_folder_id

    use_label :title
    def label_string
      title
    end

    expects :title
    
    add_input_filter(:description) { |d|
      d.to_s.gsub("'",'&apos;')
    }

    html_escape_values_of :title

    def user_group
      u =   User_Group.load(:user_group_id => user_group_id)
      u ||= User_Group.load(:user_group_id => 5)
    end

=begin
    # CMS Worldwide Hype, Ajax => {cms,worldwide,hype,ajax}
    add_input_filter(:tags) { |tags| 
      tags = tags.to_s
      tags.gsub!("'","\'")
      tags.gsub!('{','')
      tags.gsub!('}','')
      tags.gsub!(',',' ')
      tags = tags.squeeze(' ')
      tags.strip!
      tags.gsub!(' ',',')
      tags.downcase!
      tags = '{' << tags + '}'
      tags
    }
    # {cms,worldwide,hype,ajax} => cms worldwide hype ajax
    add_output_filter(:tags) { |tags| 
      tags.gsub!("'",'&apos;')
      tags.gsub!("\"",'')
      tags.gsub!('{','')
      tags.gsub!('}','')
      tags.gsub!(',',' ')
      tags = tags.squeeze(' ')
      tags
    }
=end

    def filesize
      self.get_attribute_values()[:filesize].to_i.filesize
    end

    def self.bootstrap
      create(:media_asset_id => 1, 
             :tags => '{}', 
             :user_group_id => '5')
    end

    def self.before_create(args)
      args[:mime] = '?' unless args[:mime]
      asset_folder_id   = args[:media_folder_id] 
      asset_folder_id ||= 0
      if asset_folder_id.to_i != 0 then
        folder = Media_Asset_Folder.find(1).with(Media_Asset_Folder.media_asset_folder_id == asset_folder_id).entity
        folder_path = folder.folder_path
        folder_tags = ([folder] + folder_path).map { |f| f.physical_path.downcase }
        tmp_tags = (args[:tags].strip.split(' ') + folder_tags)
        tmp_tags.uniq!
        args[:tags] = tmp_tags.join(' ')
        log(tmp_tags)
      end
      super(args)
    end

    def self.before_commit(instance)
      asset_folder_id   = instance.media_folder_id
      asset_folder_id ||= '0'
      if asset_folder_id != '0' then
        folder = Media_Asset_Folder.find(1).with(Media_Asset_Folder.media_asset_folder_id == asset_folder_id).entity
        folder_path   = folder.folder_path if folder
        folder_path ||= []
        folder_tags   = ([folder] + folder_path).map { |f| f.physical_path.downcase } if folder
        folder_tags ||= []
        tmp_tags      = (instance.tags.strip.split(' ') + folder_tags)
        tmp_tags.uniq!
        instance[:tags] = '{' + tmp_tags.join(',').gsub('{','').gsub('}','') + '}'
        log(tmp_tags)
      end
    end

    def folder_path
      asset_folder_id = media_folder_id unless asset_folder_id
      return [] if asset_folder_id == '0'
      folder = Media_Asset_Folder.find(1).with(Media_Asset_Folder.media_asset_folder_id == asset_folder_id).entity
      return folder.folder_path if folder
      return []
    end

    def mime_extension
      if extension.to_s == '' then
        @mime_extension = mime.split('/')[-1].downcase.gsub('x-','') unless @mime_extension
        return @mime_extension
      end
      extension
    end

    add_output_filter(:mime_extension) { |m|
      m.gsub('jpeg','jpg')
    }


    # Relative path, including size-folder only. 
    # Example: 
    #
    #   'thumb/asset_343.4.jpg' 
    #
    # For version 4 of asset 343, thumbnail of size 'thumb'. 
    # Note that file extension is always .jpg for thumbnails. 
    # Only original file paths have the real extension 
    # appended: 
    #
    #   'asset_343.4.odt' 
    #
    def rel_name(params={})
      ma_version     = params[:version]
      variant        = params[:size]
      variant      ||= params[:variant]
      filename_ext   = params[:extension] 
      filename_ext ||= 'jpg'
      folder         = ''

      if ma_version.to_i > 0 then 
        a_id = "#{media_asset_id}.#{ma_version.to_s}"
      else 
        a_id = media_asset_id
      end
      if !variant || variant == :org then 
      # Path to original file
        filename_ext = extension()
      else 
      # Path to thumbnail
        folder = "#{variant}/"
      end
      if variant && !has_preview? then
      # Path to MIME type thumbnail
        a_id = mime_extension
      end
      return "#{folder}asset_#{a_id}.#{filename_ext}"
    end

    # Absolute path to asset in file system. 
    def fs_path(params={})
      Aurita.project_path(:public, :assets, rel_name(params))
    end

    # Path to original sized image path of this file. 
    # Example: 
    #   
    #   MIME-type image/jpg -> original image path is assets/asset_<id>.jpg
    #                          original file path is assets/asset_<id>.jpg
    #
    #   MIME-type x-application/pdf -> original image path is assets/asset_<id>.jpg
    #                                  original file path is assets/asset_<id>.pdf
    def original_image_path
      return fs_path if is_image?
      return fs_path(:extension => 'jpg') 
    end

    def filename(version=0)
      return "asset_#{media_asset_id}.#{mime_extension}" if version == 0
      return "asset_#{media_asset_id}.#{version}.#{mime_extension}"
    end
    def url(version=0)
      "/aurita/assets/#{filename(version)}"
    end

    def is_archive?
      return ['rar','zip','tgz','bz','7z'].include?(mime_extension)
    end
    def is_image?
      return mime.to_s[0..5] == 'image/' || ['jpg', 'jpeg', 'png', 'gif', 'postscript', 'eps', 'tif', 'tiff', 'tga', 'ai'].include?(mime_extension.downcase)
    end
    def is_vector?
      return ['ai', 'svg'].include?(mime_extension)
    end
    def is_video?
      return ['mpeg', 'mpg', 'wmv', 'avi', 'flv', 'mp4', 'swf'].include?(mime_extension.downcase)
    end
    def is_audio?
      return ['ogg', 'wma', 'wav', 'mp3'].include?(mime_extension)
    end
    def is_slide?
      return ['ppt'].include?(mime_extension)
    end
    def is_readonly_document?
      return ['pdf'].include?(mime_extension)
    end
    def is_document?
      return ['doc', 'dot', 'odt'].include?(mime_extension)
    end
    def is_plaintext?
      return ['rtf', 'txt'].include?(mime_extension)
    end
    def is_archive?
      return ['zip', 'rar', 'tar.gz', '7z', 'dmg'].include?(mime_extension)
    end

    def has_preview? 
      is_image? || mime_extension.downcase == 'pdf'
    end

    def doctype
      if !@doctype then
        @doctype = :any
        @doctype = :image if is_image? 
        @doctype = :archive if is_archive? 
        @doctype = :video if is_video? 
        @doctype = :vector if is_vector? 
        @doctype = :audio if is_audio? 
        @doctype = :slides if is_slide? 
        @doctype = :readonly_document if is_readonly_document? 
        @doctype = :document if is_document? 
        @doctype = :plaintext if is_plaintext? 
        @doctype = :archive if is_archive? 
      end
      @doctype
    end

    def icon(size=:tiny, version=nil)
      return "<img src=\"/aurita/assets/#{size}/asset_#{media_asset_id}.jpg?#{checksum}\" />" if has_preview? && version.nil?
      return "<img src=\"/aurita/assets/#{size}/asset_#{media_asset_id}.#{version}.jpg?#{checksum}\" />" if has_preview? 
      return "<img src=\"/aurita/assets/#{size}/asset_#{mime_extension}.jpg\" />"
    end

    # Absolute URL path to file. 
    def icon_path(params)
      "/aurita/assets/#{rel_name(params)}?#{checksum}"
    end
    
    def accept_visitor(v)
      v.visit_media_asset(self)
    end

    def self.import_image(media_asset_instance, image_path_from)
      return unless media_asset_instance.is_image? 
      Media_Asset_Importer.new(self).import_image(image_path_from)
    end

    # Returns most recent Media_Asset created by user specified. 
    # User defaults to Aurita.user if no user or user id is passed. 
    def self.latest_of_user(user=nil)
      user_group_id = user
      user_group_id = user.user_group_id if user.kind_of? Aurita::Main::User_Group
      user_group_id ||= Aurita.user.user_group_id
      
      select { |m|
        m.where(m.user_group_id == user_group_id)
        m.order_by(m.changed, :desc)
        m.limit(1)
      }.first
    end

  end 

end # module
end # module
end # module

