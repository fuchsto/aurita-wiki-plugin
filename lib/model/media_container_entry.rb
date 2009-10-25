
require('aurita')

module Aurita
module Plugins
module Wiki

  class Media_Container_Entry < Aurita::Model
    table :media_container_entry, :public
    primary_key :media_container_entry_id, :media_container_entry_id_seq
  end

end
end
end

