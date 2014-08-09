
require('aurita')
require('aurita-gui')
require('aurita-gui/widget')

Aurita.import_module :gui, :helpers

module Aurita
module Plugins
module Wiki
module GUI
 
  class Media_Asset_Thumbnail < Aurita::GUI::Widget
  include Aurita::GUI
  include Aurita::GUI::Link_Helpers
  include Aurita::GUI::I18N_Helpers

    def initialize(entity, params={})
      if entity.is_a?(Hash) then
        params  = entity
        @entity = Wiki::Media_Asset.load(:media_asset_id => params[:media_asset_id])
        raise ::Exception.new(params.inspect) unless @entity
      else 
        @entity = entity
      end
      @thumbnail_size   = params[:thumbnail_size]
      @thumbnail_size ||= params[:size]
      @thumbnail_size ||= :thumb
      @img_attribs      = params[:img_attribs]
      params.delete(:size)
      params.delete(:thumbnail_size)
      params.delete(:img_attribs)
      super()
    end

    def element
      requested_by_user   = @entity.requested_by?(Aurita.user) 
      approvable_by_user  = Aurita.user.may_approve_file?(@entity)
      requested           = @entity.requested?
      approved            = @entity.approved?
      requested_css_class = nil
      requested_css_class = :requested if requested_by_user
      approved_css_class  = nil
      approved_css_class  = :approved if approved && approvable_by_user

      HTML.div(:class => [ :media_asset_thumbnail, :bright_bg, @thumbnail_size, requested_css_class, approved_css_class ]) { 
        HTML.span(:class => [ :image, @thumbnail_size ]) { 
          img_attribs = { 
            :src => @entity.icon_path(:size => @thumbnail_size)
          }
          img_attribs.update(@img_attribs) if @img_attribs
          HTML.img(img_attribs)
        } + 
        HTML.div(:class => [ :request_file, @thumbnail_size ]) { 
          if Aurita.user.may?(:request_files) then
            HTML.div.request_file_button { 
              HTML.span { 
                if !approved then
                  HTML.input(:type    => :checkbox, 
                             :checked => ((requested_by_user)? :checked : nil ), 
                             :name    => "request_file_#{@entity.media_asset_id}", 
                             :onclick => "Aurita.Wiki.request_file(this, this.ancestors()[3], #{@entity.media_asset_id});") 
                end
              } +
              HTML.span { 
                if approved then
                  HTML.label { tl(:approved)  } 
                else
                  HTML.label { tl(:requested)  } 
                end
              }
            }
          end
        } + 
        HTML.div(:class => [ :approve_file, @thumbnail_size ]) { 
          if requested && approvable_by_user then
            approved = @entity.approved_by?(Aurita.user)
            HTML.div.approve_file_button { 
              HTML.input(:type    => :checkbox, 
                         :checked => ((approved)? :checked : nil ), 
                         :name    => "approve_file_#{@entity.media_asset_id}", 
                         :onclick => "Aurita.Wiki.approve_file(this, this.ancestors()[2], #{@entity.media_asset_id});") + 
              HTML.label { tl(:approved) }
            }
          end
        } + 
        HTML.div(:class => [:info, :default_bg, @thumbnail_size ]) { 
           HTML.div.title { @entity.title } +
           HTML.div.tags { @entity.tags }
        }
      }
    end

  end

end
end
end
end
