
require('aurita/model')
Aurita::Main.import_model :content
Aurita::Main.import_model :tag_index
Aurita.import_plugin_model :wiki, :asset
Aurita.import_plugin_model :wiki, :container

Aurita.import_plugin_model :form_generator, :form_asset
Aurita.import_plugin_model :todo, :todo_asset
Aurita.import_plugin_model :todo, :todo_container_asset

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
      tags.downcase!
      tags = '{' << tags.gsub("'",'&apos;').gsub(',',' ').squeeze(' ').gsub(' ',',') << '}' 
      tags.gsub!('{{','{')
      tags.gsub!('}}','}')
      log('TEXT_ASSET tags filter: ' << tags.inspect)
      tags
    }

    def parent_article
      if !@parent_article then
        @parent_article = Article.select { |c| 
          c.join(Container).on(Article.content_id == Container.content_id_parent) { |ca|
            ca.where(Container.content_id_child == content_id)
          }
        }.first
      end
      return @parent_article
    end
    alias article parent_article

    def self.before_create(args)
    # text_tags = Tag_Index.resolve_tags_from_string(args[:text])
    # log('TAGS: ' << args.hash.inspect)
      unless args[:tags] then
        args[:tags] = 'text ' + text_tags 
      end
      super(args)
    end

    def self.after_update(instance)
      tags = Tag_Index.resolve_tags_from_string(instance.text)
      instance.parent_article.add_tags(tags)
    end

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

    def media_assets
      Media_Asset.all_with(Content.content_id.in(
                             Container.select(:content_id_child) { |c|
                                c.where((Container.content_id_parent == content_id) &
                                        (Container.content_type == 'IMAGE'))
                             } 
                          )).entities
    end

    def accept_visitor(v)
      v.visit_text_asset(self)
    end

    def inspect
      puts text
    end
      
  end 

end # module
end # module
end # module
