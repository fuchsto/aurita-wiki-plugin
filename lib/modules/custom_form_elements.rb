
require('aurita')
require('aurita-gui')
Aurita.import_module :gui, :i18n_helpers

module Aurita
module Plugins
module Wiki
module GUI

  class Media_Folder_Select_Field < Aurita::GUI::Select_Field
  include Aurita::GUI::I18N_Helpers

    attr_accessor :private_folders, :public_folders, :folders

    def initialize(params={}, &block)
      params[:label] = tl(:select_folder) unless params[:label]
      params[:exclude_folder_ids] = [] unless params[:exclude_folder_ids]
      params[:exclude_folder_ids] = [ params[:exclude_folder_ids] ] unless params[:exclude_folder_ids].is_a?(Array)
      @first_option_label ||= params[:first_option_label]
      @first_option_value   = params[:first_option_value]
      @first_option_label ||= tl(:select_folder)
      @first_option_value ||= 0 
      if block_given? then 
        @folders = Media_Asset_Folder.hierarchy(:filter => yield, :exclude_folder_ids => params[:exclude_folder_ids])
      elsif params[:folders] then
        @folders = params[:folders]
        params.delete(:folders)
      elsif params[:parent_id] then
        @folders = Media_Asset_Folder.hierarchy(:parent_id => params[:parent_id], 
                                                :exclude_folder_ids => params[:exclude_folder_ids])
        params.delete(:parent_id)
      else
        @folders = Media_Asset_Folder.hierarchy(:exclude_folder_ids => params[:exclude_folder_ids])
      end
      params[:name] = Media_Asset_Folder.media_asset_folder_id unless params[:name]
      params[:id]   = :media_asset_folder_select unless params[:id]
      super(params)
      set_options(folder_options())
    end

    protected 

    def folder_options
    # {{{
      opt = { @first_option_value.to_s => @first_option_label }
      @folders.each { |entry| 
        folder_name = ''
        for i in 0...entry[:indent] do 
          folder_name << '|--'
        end
        folder_name << ' ' << entry[:folder].physical_path
        opt[entry[:folder].media_asset_folder_id.to_s] = folder_name
      }
      return opt
    end # }}}

  end

end
end
end
end
