module Jekyll
  module Convertible
    # Return the contents as a string
    def to_s
      if self.is_a? Jekyll::Post
        (self.content || '') + (self.extended || '')
      else
        self.content || ''
      end
    end
    
    # Read the YAML frontmatter
    #   +base+ is the String path to the dir containing the file
    #   +name+ is the String filename of the file
    #
    # Returns nothing
    def read_yaml(base, name)
      self.content = File.read(File.join(base, name))

      if self.content =~ /^(---.*?\n.*?)\n---.*?\n(.*)/m
        self.data = YAML.load($1)
        self.content = $2
        
        # if we have an extended section, separate that from content
        if self.is_a? Jekyll::Post
          if self.data.key? 'extended'
            marker = self.data['extended']
            self.content, self.extended = self.content.split(marker + "\n", 2)
          end
        end
      end
    end
  
    # Transform the contents based on the file extension.
    #
    # Returns nothing
    def transform
      case self.ext
      when ".textile":
        self.ext = ".html"
        self.content = RedCloth.new(self.content).to_html
        if self.is_a? Jekyll::Post and self.extended
          self.extended = RedCloth.new(self.extended).to_html
        end
      when ".markdown":
        self.ext = ".html"
        self.content = Jekyll.markdown_proc.call(self.content)
        if self.is_a? Jekyll::Post and self.extended
          self.extended = Jekyll.markdown_proc.call(self.extended)
        end
      end
    end
    
    # Add any necessary layouts to this convertible document
    #   +layouts+ is a Hash of {"name" => "layout"}
    #   +site_payload+ is the site payload hash
    #
    # Returns nothing
    def do_layout(payload, layouts, site_payload)
      # construct payload
      payload = payload.merge(site_payload)

      # render content
      unless self.is_a? Jekyll::Post
        self.content = Liquid::Template.parse(self.content).render(payload, [Jekyll::Filters])
      end
      self.transform
      
      # output keeps track of what will finally be written
      if self.is_a? Jekyll::Post and self.extended
        self.output = self.content + self.extended
      else
        self.output = self.content
      end

      # recursively render layouts
      layout = layouts[self.data["layout"]]
      while layout
        payload = payload.merge({"content" => self.output})

        # process any scripts
        if layout.data["scripts"]
          payload = payload.merge(self.do_scripts(layout.data["scripts"]))
        end

        self.output = Liquid::Template.parse(layout.content).render(payload, [Jekyll::Filters])
        
        layout = layouts[layout.data["layout"]]
      end
    end

    # Process scripts for the layout
    #   +scripts+ is a Array of [{"name" => "foo", "command": "foo.py"}]
    #
    # Returns a Hash of {"foo" => "... script output ..."}
    def do_scripts(scripts)
      result = {}
      scripts.each do |script|
        p = IO.popen(File.join(@base, '_scripts', script["command"]) +
                     ' ' + @base)
        result[script["name"]] = p.read || ""
        p.close
      end
      result
    end
  end
end
