require "json"

class LiquidBook < SiteBuilder
  def build
    load_all_liquid_components
    build_component_documents
    liquid_tag "component_previews", :preview_tag
  end

  def load_liquid_components(dir, root: true)
    @components ||= {}
    @entry_filter ||= Bridgetown::EntryFilter.new(site)
    @current_root = dir if root

    return unless File.directory?(dir) && !@entry_filter.symlink?(dir)

    entries = Dir.chdir(dir) {
      Dir["*.{liquid,html}"] + Dir["*"].select { |fn| File.directory?(fn) }
    }

    entries.each do |entry|
      path = File.join(dir, entry)
      next if @entry_filter.symlink?(path)
      if File.directory?(path)
        load_liquid_components(
          path,
          root: false
        )
      else
        template = ::File.read(path)
        component = LiquidComponent.parse(template)

        unless component.name.nil?
          sanitized_filename = sanitize_filename(
            File.basename(path, ".*")
          )
          file_path = Pathname.new(File.dirname(path))
          key = File.join(
            file_path.relative_path_from(@current_root),
            sanitized_filename
          )
          p sanitize_filename(component.name.downcase)
          @components[key] = component
            .to_h
            .deep_stringify_keys
            .merge({
              "relative_path" => key
            })
          File.write("#{site.root_dir}/stories/#{sanitized_filename}.stories.json",
            JSON.pretty_generate(
              json_story(
                component.name,
                sanitized_filename
              )
            ), mode: "w")
        end
      end
    end
  end

  def preview_tag(_attributes, tag)
    component = tag.context.registers[:page]["component"]
    preview_path = site.in_source_dir(
      "_components",
      "#{component["relative_path"]}.preview.html"
    )

    info = {
      registers: {
        site: site,
        page: tag.context.registers[:page],
        cached_partials: Bridgetown::Converters::LiquidTemplates.cached_partials
      },
      strict_filters: site.config["liquid"]["strict_filters"],
      strict_variables: site.config["liquid"]["strict_variables"]
    }

    template = site.liquid_renderer.file(preview_path).parse(
      File.exist?(preview_path) ? File.read(preview_path) : ""
    )
    template.warnings.each do |e|
      Bridgetown.logger.warn(
        "Liquid Warning:",
        LiquidRenderer.format_error(
          e, preview_path
        )
      )
    end

    template.render!(
      site.site_payload.merge({
        page: tag.context.registers[:page]
      }),
      info
    )
  end

  private

  def load_all_liquid_components
    site.components_load_paths.each do |path|
      puts path
      load_liquid_components(path)
    end
  end

  def build_component_documents
    @components.each do |component_filename, component_object|
      doc "#{component_filename}.html" do
        layout :storybook
        collection :components
        excerpt ""
        component component_object
        title component_object["metadata"]["name"]
        content(
          Bridgetown::LayoutReader
          .new(site)
          .read["storybook"]
          .content
        )
      end
    end
  end

  def sanitize_filename(name)
    name.gsub(%r{[^\w\s-]+|(?<=^|\b\s)\s+(?=$|\s?\b)}, "")
      .gsub(%r{\s+}, "_")
  end

  def json_story(name, id)
    {
      title: name,
      stories: [{
        name: name,
        parameters: {
          server: {
            id: id
          }
        }
      }]
    }
  end
end
