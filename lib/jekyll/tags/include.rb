module Jekyll
  
  # we are replacing Liquid's include tag because it is horribly, horribly
  # broken.
  class IncludeTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super

      @template = markup.strip
    end

    def render(context)
      file = File.join(Jekyll.source, '_includes', @template)
      partial = Liquid::Template.parse(File.read(file))
      partial.render(context, [Jekyll::Filters])
    end
  end
  
end

Liquid::Template.register_tag('include', Jekyll::IncludeTag)
