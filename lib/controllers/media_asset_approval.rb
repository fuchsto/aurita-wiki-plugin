
require('aurita/controller')

Aurita.import_plugin_model :wiki, :media_asset
Aurita.import_plugin_model :wiki, :media_asset_request
Aurita::Main.import_controller :category

module Aurita
module Plugins
module Wiki

  class Media_Asset_Approval_Controller < Plugin_Controller

    guard(:toggle) { 
      Aurita.user.may?(:approve_requested_files)
    }
    guard(:all) { 
      Aurita.user.may?(:view_approved_files_list)
    }

    def toolbar_buttons
      if Aurita.user.may?(:view_approved_files_list) then
        Text_Button.new(:icon    => :add_article, 
                        :action  => 'Wiki::Media_Asset_Approval/all/') { 
          tl(:approved_files) 
        } 
      end
    end

    def toggle
      ma_id = param(:id)

      approvable_cat_ids = Category.select_values(:category_id) { |catid|
        catid.where(:approver_id => Aurita.user.user_group_id)
      }.to_a.flatten.uniq

      existing_appr = Media_Asset_Approval.find(1).with(:media_asset_id => ma_id, 
                                                        :user_group_id  => Aurita.user.user_group_id).entity
      
      if existing_appr then
        existing_appr.delete
      else
        Media_Asset_Approval.create(:media_asset_id => ma_id, 
                                    :category_ids   => approvable_cat_ids, 
                                    :user_group_id  => Aurita.user.user_group_id)
      end
    end

    def all
      # Assets that have at least one approval: 
      assets = Media_Asset.select { |m|
        m.where(Media_Asset.media_asset_id.in( 
          Media_Asset_Approval.select(:media_asset_id) { |mapr|
            mapr.where(true)
          }
        ))
        m.order_by(Media_Asset.created, :desc)
      }.to_a
      
      assets.reject! { |media_asset|
        # select approved media assets only: 
        !media_asset.approved?
      }

      Page.new(:id => :approved_files, :header => tl(:approved_files)) {
        HTML.div.section_toolbar { 
          HTML.a(:target => "_blank", :href => "/direct_download/approved.zip", :class => :message_field) { 
            HTML.img(:src => '/aurita/images/icons/zip.jpg', :class => :message_icon) + 
            HTML.span.message_text { "Download all files as ZIP archive (#{assets.length} files)" }
          }
        } + 
        GUI::Media_Asset_Grid.new(assets)
      }
    end

  end

end
end
end

