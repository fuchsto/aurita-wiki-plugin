
require('./spec_env')

Aurita::Main.import_model :category
Aurita::Main.import_model :content_category
Aurita.import_plugin_model :wiki, :media_asset

include Aurita::Plugins::Wiki

describe Aurita::Plugins::Wiki::Media_Asset do

  it "should have categories assigned to it" do

    c1 = Category.create(:category_name => "C1")
    c2 = Category.create(:category_name => "C2")

    ma = Media_Asset.create(:user_group_id => 1, 
                            :title         => 'Spec file', 
                            :tags          => [ :spec ])

    ma.add_category(c1)
    ma.add_category(c2)

    ma.category_ids.should_include c1.category_id
    ma.category_ids.should_include c2.category_id

    p ma.categories

    ma.categories.should_include c1
    ma.categories.should_include c2

  end

end

