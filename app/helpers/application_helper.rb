module ApplicationHelper
  def inline_svg_tag(name, **options)
    svg_path(name).read.strip.then do |svg|
      raw options.any? ? svg.sub(/\A<svg(.*?)>/, "<svg\\1 #{tag.attributes(options)}>") : svg
    end
  end

  def svg_path(name)
    Rails.root.join("app/assets/images/#{name}.svg")
  end
end
