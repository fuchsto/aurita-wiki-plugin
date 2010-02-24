
require 'rake'

spec = Gem::Specification.new { |s|

  s.name = 'aurita-wiki-plugin' 
  s.rubyforge_project = 'aurita-wiki-plugin'
  s.summary = 'Simple and extensible wiki functionality for Aurita. '
  s.description = <<-EOF
Simple and extensible wiki functionality for Aurita. 
  EOF
  s.version = '0.7.0'
  s.author  = 'Tobias Fuchs'
  s.email   = 'twh.fuchst@gmail.com'
  s.date    = Time.now
  s.add_dependency('arrayfields',  '>= 4.6.0')
  s.add_dependency('aurita-gui',   '>= 0.5.9')
  s.add_dependency('lore',         '>= 0.3.8')
  s.add_dependency('aurita',       '>= 0.5.9')
  s.add_dependency('prawn',        '>= 0.4.0')
  s.add_dependency('prawn-format', '>= 0.1.0')
  s.files = [ 
    'lib/plugin.rb',
    'lib/model/media_asset_folder.rb',
    'lib/model/text_asset.rb',
    'lib/model/article_version.rb',
    'lib/model/article.rb',
    'lib/model/container.rb',
    'lib/model/asset.rb',
    'lib/model/media_asset.rb',
    'lib/model/media_asset_folder_category.rb',
    'lib/model/media_asset_version.rb',
    'lib/model/media_container.rb',
    'lib/model/media_asset_download.rb',
    'lib/model/article_access.rb',
    'lib/model/media_iptc.rb',
    'lib/model/media_container_entry.rb',
    'lib/permissions.rb',
    'lib/controllers/media_asset_folder.rb',
    'lib/controllers/text_asset.rb',
    'lib/controllers/article_version.rb',
    'lib/controllers/user_media_asset_folder.rb',
    'lib/controllers/image_editor.rb',
    'lib/controllers/context_menu.rb',
    'lib/controllers/article.rb',
    'lib/controllers/container.rb',
    'lib/controllers/asset.rb',
    'lib/controllers/hierarchy_entry.rb',
    'lib/controllers/media_asset_statistics.rb',
    'lib/controllers/media_asset.rb',
    'lib/controllers/media_asset_version.rb',
    'lib/controllers/autocomplete.rb',
    'lib/controllers/media_container.rb',
    'lib/controllers/media_asset_download.rb',
    'lib/modules/text_asset_decorator.rb',
    'lib/modules/media_meta_data.rb',
    'lib/modules/media_asset_helpers.rb',
    'lib/modules/article_hierarchy_default_decorator.rb',
    'lib/modules/article_versioning.rb',
    'lib/modules/article_hierarchy_pdf_decorator.rb',
    'lib/modules/article_hierarchy_visitor.rb',
    'lib/modules/custom_form_elements.rb',
    'lib/modules/image_manipulation.rb',
    'lib/modules/article_full_hierarchy_visitor.rb',
    'lib/modules/article_decorator.rb',
    'lib/modules/gui/media_asset_thumbnail.rb',
    'lib/modules/gui/media_asset_grid.rb',
    'lib/modules/gui/media_asset_list.rb',
    'lib/modules/gui/media_asset_folder_grid.rb',
    'lib/modules/gui/text_asset_partial.rb',
    'lib/modules/gui/media_asset_selection_field.rb',
    'lib/modules/gui/article_selection_field.rb',
    'lib/modules/gui/media_asset_folder_thumbnail.rb',
    'lib/modules/gui/widgets.rb',
    'lib/modules/gui/media_asset_table.rb',
    'lib/modules/gui/media_container_partial.rb',
    'lib/modules/gui/media_asset_version_list.rb',
    'lib/modules/article_hierarchy_sortable_decorator.rb',
    'lib/modules/article_cache.rb',
    'lib/modules/article_visitor.rb',
    'lib/modules/media_asset_renderer.rb',
    'lib/modules/article_dump_default_decorator.rb',
    'lib/modules/media_asset_importer.rb', 
    'lib/views/container_form.rhtml',
    'lib/views/article_list.rhtml',
    'lib/views/article_version_decorator.rhtml',
    'lib/views/media_asset_info.rhtml',
    'lib/views/after_file_upload.rhtml',
    'lib/views/container_attachments.rhtml',
    'lib/views/article_asset.rhtml',
    'lib/views/media_asset_choice_list.rhtml',
    'lib/views/article_title_list.rhtml',
    'lib/views/article_public_decorator.rhtml',
    'lib/views/article_decorator_no_info.rhtml',
    'lib/views/article_sortable_decorator.rhtml',
    'lib/views/article_list_recently_commented.rhtml',
    'lib/views/media_asset_folder_level.rhtml',
    'lib/views/media_asset_folder_box.rhtml',
    'lib/views/article_decorator.rhtml',
    'lib/views/article_category_list.rhtml',
    'lib/views/user_media_management_select.rhtml',
    'lib/views/media_asset_folder.rhtml',
    'lib/views/image_editor.rhtml',
    'lib/views/container_inline_form.rhtml', 
    'lib/lang',
    'lib/lang/de.regular.yaml',
    'lib/lang/de.yaml',
    'lib/lang/de.enterprise.yaml',
    'lib/lang/en.yaml'
  ]

  s.has_rdoc = true
  s.rdoc_options << '--title' << 'Aurita::Plugins::Wiki' <<
                    '--line-numbers'

  s.homepage = 'http://github.com/fuchsto/aurita-wiki-plugin'

}
