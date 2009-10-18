
require 'rake'

spec = Gem::Specification.new { |s|

  s.name = 'aurita-wiki-plugin' 
  s.rubyforge_project = 'aurita-wiki-plugin'
  s.summary = 'Simple and extensible wiki functionality for Aurita. '
  s.description = <<-EOF
Simple and extensible wiki functionality for Aurita. 
  EOF
  s.version = '0.5.9'
  s.author = 'Tobias Fuchs'
  s.email = 'fuchs@wortundform.de'
  s.date = Time.now
  s.files = '*.rb'
  s.add_dependency('arrayfields', '>= 4.6.0')
  s.add_dependency('aurita-gui',  '>= 0.5.9')
  s.add_dependency('lore',        '>= 0.3.8')
  s.add_dependency('aurita',      '>= 0.5.9')
  s.files = [ 
   'lib/permissions.rb', 
   'lib/model/media_asset_download.rb',
   'lib/model/media_asset_folder.rb',
   'lib/model/article_access.rb',
   'lib/model/media_asset_folder_category.rb',
   'lib/model/article.rb',
   'lib/model/text_asset.rb',
   'lib/model/media_asset.rb',
   'lib/model/container.rb',
   'lib/model/article_version.rb',
   'lib/model/media_asset_version.rb',
   'lib/model/asset.rb',
   'lib/plugin.rb',
   'lib/controllers/media_asset_download.rb',
   'lib/controllers/user_media_asset_folder.rb',
   'lib/controllers/media_asset_folder.rb',
   'lib/controllers/context_menu.rb',
   'lib/controllers/media_asset_statistics.rb',
   'lib/controllers/article.rb',
   'lib/controllers/text_asset.rb',
   'lib/controllers/media_asset.rb',
   'lib/controllers/autocomplete.rb',
   'lib/controllers/image_editor.rb',
   'lib/controllers/container.rb',
   'lib/controllers/article_version.rb',
   'lib/controllers/media_asset_version.rb',
   'lib/controllers/hierarchy_entry.rb',
   'lib/controllers/asset.rb',
   'lib/modules/article_versioning.rb',
   'lib/modules/article_visitor.rb',
   'lib/modules/article_decorator.rb',
   'lib/modules/media_asset_helpers.rb',
   'lib/modules/article_dump_default_decorator.rb',
   'lib/modules/gui/media_asset_grid.rb',
   'lib/modules/gui/media_asset_version_list.rb',
   'lib/modules/gui/media_asset_table.rb',
   'lib/modules/gui/media_asset_folder_thumbnail.rb',
   'lib/modules/gui/widgets.rb',
   'lib/modules/gui/multi_file_entry_field.rb',
   'lib/modules/gui/media_asset_folder_grid.rb',
   'lib/modules/gui/media_asset_thumbnail.rb',
   'lib/modules/gui/media_asset_list.rb',
   'lib/modules/gui/multi_file_field.rb',
   'lib/modules/article_hierarchy_visitor.rb',
   'lib/modules/article_hierarchy_sortable_decorator.rb',
   'lib/modules/media_asset_renderer.rb',
   'lib/modules/media_asset_importer.rb',
   'lib/modules/text_asset_decorator.rb',
   'lib/modules/article_full_hierarchy_visitor.rb',
   'lib/modules/image_manipulation.rb',
   'lib/modules/custom_form_elements.rb',
   'lib/modules/article_hierarchy_default_decorator.rb',
   'lib/modules/article_hierarchy_pdf_decorator.rb',
   'lib/modules/article_cache.rb',
   'README.rb'
  ]

  s.has_rdoc = true
  s.rdoc_options << '--title' << 'Aurita::Plugins::Wiki' <<
                    '--main' << 'README.rb' <<
                    '--line-numbers'

  s.homepage = 'http://intra.wortundform.de/doc/'

}
