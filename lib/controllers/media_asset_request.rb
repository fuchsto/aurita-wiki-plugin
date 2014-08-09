
require('aurita/controller')

Aurita.import_plugin_model :wiki, :media_asset
Aurita.import_plugin_model :wiki, :media_asset_request
Aurita::Main.import_controller :category

module Aurita
module Plugins
module Wiki

  class Media_Asset_Request_Controller < Plugin_Controller

    guard(:toggle) { 
      Aurita.user.may?(:request_files)
    }

    def toolbar_buttons
      buttons = []
      if Aurita.user.may?(:request_files) then
        buttons << Text_Button.new(:icon   => :add_article, 
                                   :action => 'Wiki::Media_Asset_Request/list_user_requests') { 
          tl(:my_requested_files) 
        } 
      end
      if Aurita.user.may?(:view_all_requested_files) then
        buttons << Text_Button.new(:icon   => :add_article, 
                                   :action => 'Wiki::Media_Asset_Request/all') { 
          tl(:all_requested_files) 
        } 
      end
    end

    def toggle
      ma_id = param(:id)
      existing_req = Media_Asset_Request.find(1).with(:media_asset_id => ma_id, 
                                                      :user_group_id  => Aurita.user.user_group_id).entity
      
      media_asset = Media_Asset.get(ma_id)
      
      if existing_req then
        return if media_asset.approved? # Approved files cannot be de-requested
        existing_req.delete
      else
        Media_Asset_Request.create(:media_asset_id => ma_id, 
                                   :user_group_id  => Aurita.user.user_group_id)
      end
    end

    def list_user_requests
    # {{{
      assets = Media_Asset.select { |m|
        m.join(Media_Asset_Request).on(Media_Asset_Request.media_asset_id == Media_Asset.media_asset_id) { |mr|
          mr.where((Media_Asset_Request.user_group_id == Aurita.user.user_group_id) &
                   (Media_Asset.deleted == 'f'))
          mr.order_by(:time_requested, :desc)
        }
      }
      table   = GUI::Media_Asset_Table.new(assets)
      headers = [ HTML.th { '&nbsp;' }, 
                  HTML.th { tl(:requested) }, 
                  HTML.th { tl(:approved) }, 
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

      Page.new(:id => :requested_files, :header => tl(:requested_files)) { 
        table
      }
    end # }}}

    def all
      assets = Media_Asset.select { |m|
        m.where((Media_Asset.has_category_in(Aurita.user.category_ids)) & 
                (Media_Asset.deleted == 'f') & 
                (Media_Asset.media_asset_id.in( 
                   Media_Asset_Request.select(:media_asset_id) { |mr| 
                     mr.where(true)
                   }
                ))
               )
        m.order_by(:media_asset_id, :desc)
      }.to_a
      table   = GUI::Media_Asset_Table.new(assets)
      headers = [ HTML.th { '&nbsp;' }, 
                  HTML.th { tl(:requested) }, 
                  HTML.th { tl(:approved) }, 
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

      Page.new(:id => :all_requested_files, :header => tl(:requested_files)) { 
        table
      }
    end

  end

end
end
end

