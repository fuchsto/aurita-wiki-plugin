
require('aurita')

module Aurita
module Plugins
module Wiki

  class Abstract_Folder_Access 
    
    attr_reader :folder

    def initialize(folder)
      @folder = folder
    end

    def permits_read_access_for(user)
      raise NotImplementedException.new("#{self.class.to_s}#permits_read_access_for is not implemented")
    end

    def permits_edit_for(user)
      raise NotImplementedException.new("#{self.class.to_s}#permits_edit_for is not implemented")
    end

    def permits_write_access_for(user)
      raise NotImplementedException.new("#{self.class.to_s}#permits_write_access_for is not implemented")
    end

    def permits_subfolders_for(user)
      raise NotImplementedException.new("#{self.class.to_s}#permits_subfolders_for is not implemented")
    end

  end

end
end
end

