module Jekyll
  
  class Site
    attr_accessor :source, :dest
    attr_accessor :layouts, :posts, :collated
    
    # Initialize the site
    #   +source+ is String path to the source directory containing
    #            the proto-site
    #   +dest+ is the String path to the directory where the generated
    #          site should be written
    #
    # Returns <Site>
    def initialize(source, dest)
      self.source = source
      self.dest = dest
      self.layouts = {}
      self.posts = []
      self.collated = {}
    end
    
    # Do the actual work of processing the site and generating the
    # real deal.
    #
    # Returns nothing
    def process
      self.read_layouts
      self.read_posts
      self.write_posts
      self.write_archives
      self.transform_pages
    end
    
    # Read all the files in <source>/_layouts into memory for
    # later use.
    #
    # Returns nothing
    def read_layouts
      base = File.join(self.source, "_layouts")
      entries = Dir.entries(base)
      entries = entries.reject { |e| File.directory?(e) }
      
      entries.each do |f|
        name = f.split(".")[0..-2].join(".")
        self.layouts[name] = Layout.new(base, f)
      end
    rescue Errno::ENOENT => e
      # ignore missing layout dir
    end
    
    # Read all the files in <source>/posts and create a new Post
    # object with each one.
    #
    # Returns nothing
    def read_posts
      base = File.join(self.source, "_posts")
      entries = Dir.entries(base)
      entries = entries.reject { |e| File.directory?(e) }

      entries.each do |f|
        self.posts << Post.new(self.source, f) if Post.valid?(f)
      end

      self.posts.sort!

      # build collated post structure for archives
      self.posts.reverse.each do |post|
        y, m, d = post.date.year, post.date.month, post.date.day
        unless self.collated.key? y
          self.collated[y] = {}
        end
        unless self.collated[y].key? m
          self.collated[y][m] = {}
        end
        unless self.collated[y][m].key? d
          self.collated[y][m][d] = []
        end
        self.collated[y][m][d] += [post]
      end
    rescue Errno::ENOENT => e
      # ignore missing layout dir
    end
    
    # Write each post to <dest>/<year>/<month>/<day>/<slug>
    #
    # Returns nothing
    def write_posts
      self.posts.each do |post|
        post.add_layout(self.layouts, site_payload)
        post.write(self.dest)
      end
    end

    def write_archive(dir, type)
      archive = Archive.new(self.source, dir, type)
      archive.add_layout(self.layouts, site_payload)
      archive.write(self.dest)
    end

    # Write out archive pages based on special layouts.  Yearly,
    # monthly, and daily archives will be written if layouts exist.
    # Yearly archives will be in <dest>/<year>/index.html and other archives
    # will be generated similarly.
    #
    # Returns nothing.
    def write_archives
      self.collated.keys.each do |year|
        if self.layouts.key? 'archive_yearly'
          self.write_archive(year.to_s, 'archive_yearly')
        end

        self.collated[year].keys.each do |month|
          if self.layouts.key? 'archive_monthly'
            self.write_archive(File.join(year.to_s, month.to_s),
                               'archive_monthly')
          end

          self.collated[year][month].keys.each do |day|
            if self.layouts.key? 'archive_daily'
              self.write_archive(File.join(year.to_s, month.to_s, day.to_s),
                                 'archive_daily')
            end
          end
        end
      end
    end

    # Copy all regular files from <source> to <dest>/ ignoring
    # any files/directories that are hidden (start with ".") or contain
    # site content (start with "_")
    #   The +dir+ String is a relative path used to call this method
    #            recursively as it descends through directories
    #
    # Returns nothing
    def transform_pages(dir = '')
      base = File.join(self.source, dir)
      entries = Dir.entries(base)
      entries = entries.reject { |e| ['.', '_'].include?(e[0..0]) }

      entries.each do |f|
        if File.directory?(File.join(base, f))
          next if self.dest.sub(/\/$/, '') == File.join(base, f)
          transform_pages(File.join(dir, f))
        else
          first3 = File.open(File.join(self.source, dir, f)) { |fd| fd.read(3) }
          
          # if the file appears to have a YAML header then process it as a page
          if first3 == "---"
            page = Page.new(self.source, dir, f)
            page.add_layout(self.layouts, site_payload)
            page.write(self.dest)
          # otherwise copy the file without transforming it
          else
            FileUtils.mkdir_p(File.join(self.dest, dir))
            FileUtils.cp(File.join(self.source, dir, f), File.join(self.dest, dir, f))
          end
        end
      end
    end

    # The Hash payload containing site-wide data
    #
    # Returns {"site" => {"time" => <Time>, "posts" => [<Post>]}}
    def site_payload
      {"site" => {"time" => Time.now,
          "posts" => self.posts.sort.reverse,
          "collated_posts" => self.collated}}
    end
  end

end
