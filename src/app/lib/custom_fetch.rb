class CustomFetch
  class << self
    
    def fetch_pubmed(pmid)
      
      require 'hpricot'
      require 'open-uri'
      
      doc = open("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=#{pmid}&retmode=xml") { |f| Hpricot(f) }
      p_article = doc.at("pubmedarticle")
      results = nil
      if p_article
        citation= p_article.at("medlinecitation")
        article = citation.at("article")
        results = {}
        pubdate = article.at("journal").at("journalissue").at("pubdate")
        results[:year]=''
        if pubdate.at("year")
          results[:year]=pubdate.at("year").innerHTML
        elsif pubdate.at("medlinedate")
          results[:year]=pubdate.at("medlinedate").innerHTML.split(" ").first
        end
        results[:title]=article.at("articletitle").innerHTML
        authors = article.at("authorlist").search("author")
        first_author = authors.first
        results[:authors]= first_author.at("lastname").innerHTML + " " + ((first_author.at("initials")) ?  first_author.at("initials").innerHTML : '')
        results[:authors]+= " et al." if authors.size > 1
        abstract = article.at("abstract")
        results[:abstract]=abstract.at("abstracttext").innerHTML if abstract
      end
      return results
      
    end

      # capitalize each part of an all-caps name: SMITH-JONES -> Smith-Jones, O’BRIEN -> O’Brien, DE LA CRUZ -> De La Cruz
      def title_case s
        s.downcase.gsub(/(\A|[\s\-'’])(\p{Ll})/) { $1 + $2.upcase }
      end

      # only all-caps family names have their case guessed (mixed-case names like Machado are kept as is)
      def normalize_family family
        return family if !family.is_a?(String)
        family = family.strip
        if family.upcase == family
          family = title_case(family)
          family = family.sub(/\AMc(\p{Ll})/) { "Mc" + $1.upcase } # MCDONALD -> McDonald (not Mac: Mackay, Macedo)
        end
        family
      end

      def normalize_given given
        return given if !given.is_a?(String)
        given = given.strip
        # bare initials written "F. C." ("F C", "FC", "F.C." -> "F. C."): single letters, dotted tokens,
        # or 2-3 capitals without vowel (so that short names like "AL" or "JO" are not taken as initials)
        given = given.split(" ").map{ |t|
          (t =~ /\A\p{Lu}\z/ or t =~ /\A(?:\p{Lu}\.)+\p{Lu}?\z/ or t =~ /\A[B-DF-HJ-NP-TV-XZ]{2,3}\z/) ? t.delete(".").chars.map{|c| c + "."}.join(" ") : t
        }.join(" ")
        # remaining all-caps given name (JEAN-PIERRE -> Jean-Pierre)
        given.split(" ").map{ |t| (t.upcase == t and t =~ /\p{Lu}{2}/ and t !~ /\./) ? title_case(t) : t }.join(" ")
      end

      def initials given
        given ? given.gsub(/\p{Ll}+/, "") : nil
      end

      def format_author e
        h_author = nil
        if e['family']
          # Crossref JSON is already UTF-8: do not re-encode (it turned e.g. "Barrón" into "BarrÃ³n")
          fname = normalize_family(e['family'])
          given = normalize_given(e['given'])

          h_author = {
            'initials' => initials(given),
            'fname' => given,
            'lname' => fname,
            'aff_ids' => []
          }
        end
        return h_author
      end
    
    def doi_info doi
      
      h_article = {}
 #     puts "toto"
      cmd = "wget -qO - 'http://api.crossref.org/works/#{doi}'"
  #    puts cmd
      data_json = `#{cmd}`.force_encoding(Encoding::UTF_8)
      h_json = Basic.safe_parse_json(data_json, {})
#      puts h_json.to_json                                                                                                                                                                                                
      m = h_json["message"]

      j = nil
      if m

        j_name = nil
#        puts m["institution"].to_json
        if journals = m['container-title'] and journals[0]
          j_name = journals[0]
        elsif inst = m["institution"] and (inst = inst.is_a?(Array) ? inst.first : inst) and inst["name"]
          j_name = inst["name"]
        end

        if j_name
          j = Journal.where(:name => j_name).first
          if !j
            j = Journal.new(:name => j_name)
            j.save
          end
        end

#        i = Iconv.new('UTF-8','LATIN1')
  
        
        title = (m['title']) ? m['title'][0] : ''
#        puts title.to_json
        if m2 = title.match(/\[sub\s*(\d+)\]/)
#          puts title
          title.gsub!(/\[sub\s*(\d+)\]/, "<sub>/1</sub>")
        end

        authors =  (m['author']) ? m['author'].map{|e|
          format_author(e)
        }.compact : []
#        puts authors.to_json
        fa = (authors and authors.size > 0) ? authors.first : nil

        #          puts  m['journal-issue'].to_json
       # if doi == "10.1111/gbb.12048"
       #   title = "Genome-wide association mapping of natural variation in odour-guided behaviour in <i>Drosophila</i>"
       # end
#        title.gsub(/[^ ]<i>/, " <i>")
        title.gsub!(/\s*<i>/, " <i>")
        title.gsub!(/<\/i>\s+/, "<i> ")
        published_at = (m['journal-issue'] and e = m['journal-issue']['published-print'] and e2 = e["date-parts"] and d = e2[0]) ? Time.new(d[0], d[1] || 1, d[2] || 1) : ((m['issued'] and  e3 = m['issued']["date-parts"] and d2 = e3[0]) ? Time.new(d2[0], d2[1] || 1, d2[2] || 1) : nil)
        h_article = {
          :doi => doi,
          :title => title,
          :authors => (fa) ? ("#{fa['lname']}" + ((authors.size > 1) ?  " et al." : '')) : nil ,
          :authors_json => authors.to_json,
          :first_author => (fa) ? fa['lname'] : nil,
          #            :url => m['redirectURL'],                                                                                                                                                                                  
          :journal_id => (j) ? j.id : nil,
          :volume => m['volume'],
          :issue => m['issue'],
          # year follows published_at (print date of the journal issue, falling back to Crossref 'issued')
          :year => (published_at) ? published_at.year : nil,
          #          :published_online_at => (m['journal-issue'] and e = m['journal-issue']['published-online'] and e2 = e["date-parts"] and d = e2[0]) ? Time.new(d[0], d[1] || 1, d[2] || 1) : nil,
          :published_at => published_at
          #            :url => m["URL"]                                                                                                                                                                                           
        }
        if m['issued'] and  e3 = m['issued']["date-parts"] and d2 = e3[0]
      #    puts Time.new(d2[0], d2[1] || 1, d2[2] || 1)
        end
      #  puts h_article
        
      end
      puts h_article
      return h_article
      
    end
    
    
    
  end
end  
