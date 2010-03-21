
require('aurita')
Aurita::Main.import_model :strategies, :abstract_access_strategy

module Aurita
module Plugins
module Wiki

  class Abstract_Folder_Access < Abstract_Access_Strategy

    def permits_subfolders_for(user)
      raise NotImplementedException.new("#{self.class.to_s}#permits_subfolders_for is not implemented")
    end

    def permits_edit_for(user)
      raise NotImplementedException.new("#{self.class.to_s}#permits_edit_for is not implemented")
    end

  end

end
end
end

