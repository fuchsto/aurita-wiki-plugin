
require('aurita/model')
Aurita::Main.import_model :content

module Aurita
module Plugins
module Wiki

  class Asset < Content

    table :asset, :public
    primary_key :asset_id, :asset_id_seq
    
    is_a Content, :content_id

    is_polymorphic :concrete_model

  end 

end # module
end # module
end # module
