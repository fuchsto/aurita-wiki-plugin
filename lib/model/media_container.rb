
require('aurita')
Aurita.import_plugin_model :wiki, :asset
Aurita.import_plugin_model :wiki, :media_container_entry


module Aurita
module Plugins
module Wiki

  class Media_Container < Asset

    table :media_container, :public
    primary_key :media_container_id, :media_container_id_seq
    is_a Asset, :asset_id

    has_n Media_Container_Entry, :media_container_id

    def media_assets(clause=nil)
      Media_Asset.select { |c|
        c.join(Media_Container_Entry).on(Media_Container_Entry.media_asset_id == Media_Asset.media_asset_id) { |ma|
          ma.order_by(Media_Container_Entry.position, :asc)
          if clause then
            ma.where((Media_Container_Entry.media_container_id == media_container_id) & clause)
          else
            ma.where(Media_Container_Entry.media_container_id == media_container_id)
          end
          ma
        }
      }.to_a
    end
  end

end
end
end

