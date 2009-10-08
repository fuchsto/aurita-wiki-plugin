
require('aurita/model')
begin
  require('lore/model/behaviours/movable')
rescue ::Exception => ignore
  require('lore/behaviours/movable')
end

Aurita::Main.import_model :content

module Aurita
module Plugins
module Wiki

  class Container < Aurita::Model
  extend Lore::Behaviours::Movable

    table :container, :public
    primary_key :content_id_parent
    primary_key :content_id_child
    
    has_a Content, :content_id_parent
    has_a Content, :content_id_child

    ordered_by :sortpos
    
  end 

end # module
end # module
end # module
