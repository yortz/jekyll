$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

# rubygems
require 'rubygems'

# core
require 'fileutils'
require 'time'

# stdlib

# 3rd party
require 'liquid'
require 'redcloth'
require 'bluecloth'
require 'hpricot'

# internal requires
require 'jekyll/site'
require 'jekyll/convertible'
require 'jekyll/layout'
require 'jekyll/page'
require 'jekyll/post'
require 'jekyll/filters'
require 'jekyll/tags/highlight'
require 'jekyll/tags/include'
require 'jekyll/albino'

module Jekyll
  VERSION = '0.2.1'
  
  class << self
    attr_accessor :source, :dest, :lsi, :pygments, :markdown_proc
  end
  
  Jekyll.lsi = false
  Jekyll.pygments = false
  Jekyll.markdown_proc = Proc.new { |x| BlueCloth.new(x).to_html }
  
  def self.process(source, dest)
    require 'classifier' if Jekyll.lsi
    
    Jekyll.source = source
    Jekyll.dest = dest
    Jekyll::Site.new(source, dest).process
  end
end
