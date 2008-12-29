module Jekyll
  module Filters
    def date_to_string(date)
      date.strftime("%d %b %Y")
    end

    def date_to_xmlschema(date)
      date.xmlschema
    end

    def date_to_utc(date)
      date.getutc
    end

    def xml_escape(input)
      input.gsub("<", "&lt;").gsub(">", "&gt;")
    end

    def number_of_words(input)
      input.split.length
    end

    def html_truncatewords(input, words = 15, truncate_string = "...")
      doc = Hpricot.parse(input)
      (doc/:"text()").to_s.split[0..words].join(' ') + truncate_string
    end

    def to_month(input)
      return Date::MONTHNAMES[input.to_i]
    end

    def to_month_abbr(input)
      return Date::ABBR_MONTHNAMES[input.to_i]
    end
  end
end
