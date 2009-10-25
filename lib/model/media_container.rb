
require('aurita')
Aurita.import_plugin_model :wiki, :asset

module Aurita
module Plugins
module Wiki

  class Media_Container_Entry < Aurita::Model
    table :media_container_entry, :public
    primary_key :media_container_entry_id, :media_container_entry_id_seq
  end

  class Media_Container < Asset

    table :media_container, :public
    primary_key :media_container_id, :media_container_id_seq
    is_a Asset, :asset_id

    has_n Media_Container_Entry, :media_container_id

    def media_assets
      Media_Asset.select { |c|
        c.join(Media_Container_Entry).on(Media_Container_Entry.media_asset_id == Media_Asset.media_asset_id) { |ma|
          ma.order_by(Media_Container_Entry.position, :asc)
          ma.where(Media_Container_Entry.media_container_id == media_container_id)
        }
      }.to_a
    end
  end

end
end
end

