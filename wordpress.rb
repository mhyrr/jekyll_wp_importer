require 'rubygems'
require 'rexml/document'
require 'time'
require 'fileutils'

module Jekyll
  module Wordpress
  if ARGV.length   == 0
      puts 'I require an XML file name to be passed as an argument.'
      exit 1
    end

    file = File.new(ARGV[0])

    # we have to hack the XML file, unfortunately, since it isn't valid
    # at least, for Wordpress 2.6.2
    file = file.read
    file.sub!(/xmlns:wp="http:\/\/wordpress.org\/export\/1.0\/"/,
             "xmlns:wp=\"http://wordpress.org/export/1.0/\"\nxmlns:excerpt=\"excerpt\"")

    doc = REXML::Document.new file

    FileUtils.mkdir_p "_posts"
    posts = 0
    
    # Assume that there is one channel  (FIX?)
    # cycle through all of the items
    doc.root.elements["channel"].elements.each("item") { |item| 
      # if it's a published post, then we import it
      # Scanty doesn't support pages or drafts yet
      if item.elements["wp:post_type"].text == "post" and
         item.elements["wp:status"].text == "publish" then
     
    		post_id = item.elements["wp:post_id"].text.to_i
        title = item.elements["title"].text
        content = item.elements["content:encoded"].text
        time = Time.parse item.elements["wp:post_date"].text
    		# post_parent = item.elements["wp:post_parent"].text.to_i
        tags = []
        item.elements.each("category") { |cat|
          domain = cat.attribute("domain")
          if domain and domain.value == "tag"
            tags.unshift cat.text
          end
        }
        tags = tags.map { |t| t.downcase }.sort.uniq

        permalink = title.downcase.gsub(/ /, '_').gsub(/[^a-z0-9_]/, '').squeeze('_')
        
        name = %W(#{time.year} #{time.month.to_s.rjust(2, "0")} #{time.day.to_s.rjust(2, "0")}).join("-")+"-"+permalink+".markdown"
        File.open("_posts/#{name}", "w") do |f|
          f.puts <<-HEADER
---
layout: post
title: #{title}
---

          HEADER
          f.puts content
        end
        
        posts += 1

      end
    }
    puts "Created #{posts} posts!"
  end
end