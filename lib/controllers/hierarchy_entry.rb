
module Aurita
module Plugins
module Wiki

  # Controller for answering hooks in Main::Hierarchy_Entry. 
  #
  class Hierarchy_Entry_Controller < Plugin_Controller

    def entry_types
      { 
        'ARTICLE'      => { :label   => tl(:new_article), 
                            :handler => 'Wiki::Hierarchy_Entry.new_article' }, 
        'FIND_ARTICLE' => { :label   => tl(:link_to_article), 
                            :handler => 'Wiki::Hierarchy_Entry.find_article' }
      }
    end

    def new_article
      GUI::Fieldset.new { 
        Text_Field.new(:name => :title) + 
        Text_Field.new(:name => :tags)
      }
    end

    def find_article
      GUI::Fieldset.new { 
        GUI::Article_Autocomplete.new(:name => :article_id)
      }
    end

  end

end
end
end
