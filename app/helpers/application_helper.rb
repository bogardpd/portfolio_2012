module ApplicationHelper
  
  # Return a title on a per-page basis.
  def title
    base_title = "Paul Bogard"
    if @title.nil?
      base_title
    else
      "#{@title} - #{base_title}"
    end
  end
  
  def title_flight_log
    base_title = "Paul Bogard's Flight Log"
    if @title.nil?
      base_title
    else
      "#{@title} - #{base_title}"
    end
  end  
  
  def meta_description
    if @meta_description.nil?
      ""
    else
      "<meta name=\"description\" content=\"#{@meta_description}\" />".html_safe
    end
  end
  
  
  
  def country_flag(country)
    image_tag(Airport.new(:country => country).country_flag_path, :title => country, :class => 'country_flag')
  end
  
  
  def download_link(title, path)
    html = "<ul><li>Download: " + link_to(title, path) + "</li></ul>"
    html.html_safe
  end
  
  def distance_block(distance, adjective = nil)
    html = "<p class=\"distance\">" + distance_string(distance, adjective) + "</p>"
    html.html_safe
  end
  
  def distance_string(distance, adjective = nil)
    html = pluralize("<span class=\"distance_primary\">" + number_with_delimiter(distance, :delimiter => ','), [adjective,'mile'].join(' ')) + "</span> <span class=\"distance_secondary\">(" + number_with_delimiter((distance*1.60934).to_i, :delimiter => ',') + " km)</span>"
    html.html_safe
  end
  
  def format_date(input_date) # Also see method in application controller
    input_date.strftime("%e %b %Y")
  end
  
  def gcmap_embed(route_string, *args)
    @gcmap_used = true
    map_center = args[1] == "world" ? "" : ""
    if args[0] == "labels"
      query_pm = "*"
    else
      query_pm = "b:disc5:black"
    end
    html = "<div class=\"center\">"
    html += link_to(image_tag("http://www.gcmap.com/map?PM=#{query_pm}&MP=r&MS=wls2#{map_center}&P=#{route_string}", :alt => "Map of flight routes", :class => "photo_gallery"), "http://www.gcmap.com/mapui?PM=#{query_pm}&MP=r&MS=wls2#{map_center}&P=#{route_string}")
    html += "</div>"
    html.html_safe
  end
  
  def iata_mono(code)
    html = "<span class=\"iata_mono\">" + code + "</span>"
    html.html_safe
  end
  
  def photo_gallery_image(path, alt, border = true)
    base_class = "photo_gallery"
    unless border
      base_class += " white_border"
    end
    html = "<p class='center image'>#{image_tag(path, :alt => alt, :class => base_class)}</p>"
    html.html_safe
  end
  
  def computer_attributed_image(path, alt, author, license)
    case license
    when "CC BY-SA 3.0"
      link = link_to(license,"http://creativecommons.org/licenses/by-sa/3.0/")
    when "Public Domain"
      link = license
    else
      link = nil
    end
    html = "#{image_tag(path, :alt => alt, :class => 'computer_history')} #{author}<br/>#{link}"
    html.html_safe
  end
  
  def project_tile(title, path, image_path)
    banner = image_tag(image_path, :alt => title, :title => title, :class => "project_tile", :size => "265x170")
    html = "<li class=\"project_tile\">"
    html += link_to banner, path
    html += "<h2 class=\"project_tile\">#{link_to(title, path)}</h2>"
    html += "</li>"
    html.html_safe
  end
  
  def sort_link(title_string, sort_symbol, sort_string, default_dir, page_anchor)
        
    if @sort_cat == sort_symbol
      if @sort_dir == :asc
        category_sort_symbol = "<span class=\"sort_symbol\">&#x25B2;</span>" # Up Triangle
      elsif @sort_dir == :desc
        category_sort_symbol = "<span class=\"sort_symbol\">&#x25BC;</span>" # Down Triangle
      end
    else
      category_sort_symbol = ""
    end
    
    case default_dir
    when :asc
      sort_dir_string = ['desc','asc']
    else
      sort_dir_string = ['asc','desc']
    end
    link_to([title_string,category_sort_symbol].join(" ").html_safe, url_for(:sort_category => sort_string, :sort_direction => ((@sort_cat == sort_symbol && @sort_dir == default_dir) ? sort_dir_string[0] : sort_dir_string[1]), :anchor => page_anchor), :class => "sort")
  end
  
  def tail_number_country_flag(tail_number)
    country_flag(Flight.tail_country(tail_number))
  end
  
  def youtube_embed(video_id)
    html = "<div class=\"center\">
    <embed class=\"photo_gallery\" src=\"http://www.youtube.com/v/#{video_id}\" type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"425\" height=\"350\"></div>"
    html.html_safe
  end
  
end
