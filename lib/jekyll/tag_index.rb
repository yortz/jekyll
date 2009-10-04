module Jekyll
 
  class TagIndex < Page
    # Initialize a new TagIndex.
    #   +base+ is the String path to the <source>
    #   +dir+ is the String path between <source> and the file
    #
    # Returns <TagIndex>
    def initialize(site, base, dir, tag)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'
      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag_index.html')
      self.data['tag'] = tag
    end
  end
 
end
