
require('aurita/model')
Aurita::Main.import_model :content
Aurita::Main.import_model :tag_index
Aurita.import_plugin_model :wiki, :asset
Aurita.import_plugin_model :wiki, :container

begin
    Aurita.import_plugin_model :form_generator, :form_asset
rescue ::Exception => ignore
end

begin
  Aurita.import_plugin_model :todo, :todo_asset
  Aurita.import_plugin_model :todo, :todo_container_asset
rescue ::Exception => ignore
end

module Aurita
module Plugins
module Wiki

  class Text_Asset < Asset

    table :text_asset, :public
    primary_key :text_asset_id, :text_asset_id_seq
    
    is_a Asset, :asset_id

    add_input_filter(:text) { |t|
      t = '' unless t
      t.gsub!('\'','&apos;')
      t
    }
    add_output_filter(:display_text) { |t|
      t.to_s.gsub("&apos;","'")
    }

    use_label :text

    add_input_filter(:tags) { |tags| 
      if tags.is_a?(Array) then
        tags.uniq!
        tags = "{#{tags.join(',')}}"
      else
        tags = tags.to_s
        tags.downcase!
        tags = '{' << tags.gsub("'",'&apos;').gsub(',',' ').squeeze(' ').gsub(' ',',') << '}' 
        tags.gsub!('{{','{')
        tags.gsub!('}}','}')
      end
      tags
    }

    def self.before_create(args)
      super(args)
    end

    def self.after_create(instance)
      super(instance)
      instance.asset_id_child = instance.asset_id
      instance.commit
      instance
    end

    def self.after_instance_delete(instance)
      instance.article.commit_version('DELETE:Text_Asset')
    end

    def version_dump
      text().to_s.gsub('"','\"')
    end

=begin
    def subs
      # TODO: Change into
      #   subs = {}
      #   plugin_get(Hook.wiki.text_asset.subs, self).each { |sub|
      #     subs.update(sub) 
      #   }
      {
        :media_assets => media_assets(), 
        :todo_asset => Todo::Todo_Container_Asset.all_with(Content.content_id.in(
                         Container.select(:content_id_child) { |c|
                            c.where((Container.content_id_parent == content_id) &
                                    (Container.content_type == 'TODO'))
                         } 
                       )).entity, 
        :form_asset => Form_Generator::Form_Asset.find(1).with(Content.content_id.in(
                           Container.select(:content_id_child) { |c|
                              c.where((Container.content_id_parent == content_id) &
                                      (Container.content_type == 'FORM'))
                           } 
                       )).entity
      }
    end
=end

    def media_assets
      Media_Asset.all_with(Content.content_id.in(
                             Container.select(:content_id_child) { |c|
                                c.where((Container.content_id_parent == content_id) &
                                        (Container.content_type == 'IMAGE'))
                             } 
                          )).entities
    end

    def inspect
      "Text_Asset #{text_asset_id}"
    end
      
  end 

end # module
end # module
end # module
