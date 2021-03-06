class FlightsController < ApplicationController
  before_filter :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  add_breadcrumb 'Home', 'flightlog_path'
  layout "flight_log/flight_log"
  
  def index
    add_breadcrumb 'Flights', 'flights_path'
    @logo_used = true
    
    @title = "Flights"
        
    if logged_in?
      @flights = Flight.all
      @year_range = Flight.first.departure_date.year..Flight.last.departure_date.year
    else
      @flights = Flight.visitor
      @year_range = Flight.visitor.first.departure_date.year..Flight.visitor.last.departure_date.year
    end
    
    @total_distance = total_distance(@flights)
    
    # Determine which years have flights:
    @years_with_flights = Hash.new(false)
    @flights.each do |flight|
      @years_with_flights[flight.departure_date.year] = true
    end
    @meta_description = "Maps and lists of all of Paul Bogard's flights."
    
    # Set values for sort:
    case params[:sort_category]
    when "departure"
      @sort_cat = :departure
    else
      @sort_cat = :departure
    end
    
    case params[:sort_direction]
    when "asc"
      @sort_dir = :asc
    when "desc"
      @sort_dir = :desc
    else
      @sort_dir = :asc
    end
          
    # Sort flight table:
    @flights = @flights.reverse! if @sort_dir == :desc
    
  end
  
  def show
    @logo_used = true
    if logged_in?
      @flight = Flight.find(params[:id])
      @city_pair_flights = Flight.where("(origin_airport_id = :city1 AND destination_airport_id = :city2) OR (origin_airport_id = :city2 AND destination_airport_id = :city1)", {:city1 => @flight.origin_airport.id, :city2 => @flight.destination_airport.id})
    else
      @flight = Flight.visitor.find(params[:id])
      @city_pair_flights = Flight.visitor.where("(origin_airport_id = :city1 AND destination_airport_id = :city2) OR (origin_airport_id = :city2 AND destination_airport_id = :city1)", {:city1 => @flight.origin_airport.id, :city2 => @flight.destination_airport.id})
    end
    
    # Get trips sharing this city pair:
    trip_array = Array.new
    @city_pair_flights = Array.new
    section_where_array = Array.new
    @city_pair_flights.each do |flight|
      trip_array.push(flight.trip_id)
      @sections.push( {:trip_id => flight.trip_id, :trip_name => flight.trip.name, :trip_section => flight.trip_section, :departure => flight.departure_date} )
      section_where_array.push("(trip_id = #{flight.trip_id.to_i} AND trip_section = #{flight.trip_section.to_i})")
    end
    trip_array = trip_array.uniq
    
    # Create list of trips sorted by first flight:
    if logged_in?
      @trips = Trip.find(trip_array).sort_by{ |trip| trip.flights.first.departure_date }
    else
      @trips = Trip.visitor.find(trip_array).sort_by{ |trip| trip.flights.first.departure_date }
    end
    
    # Create flight arrays for maps of trips and sections:
    @city_pair_trip_flights = Flight.where(:trip_id => trip_array)
    @city_pair_section_flights = Flight.where(section_where_array.join(' OR '))
    
    @title = @flight.airline + " " + @flight.flight_number.to_s
    @meta_description = "Details for Paul Bogard's #{@flight.airline} #{@flight.flight_number} flight on #{format_date(@flight.departure_date)}."
    
    @route_distance = route_distance_by_airport_id(@flight.origin_airport, @flight.destination_airport)
    
    add_breadcrumb 'Flights', 'flights_path'
    add_breadcrumb @title, "flight_path(#{params[:id]})"
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find a flight with an ID of #{params[:id]}. Instead, we'll give you a list of flights."
    redirect_to flights_path
  end
    
  def show_date_range
    add_breadcrumb 'Flights', 'flights_path'
    @logo_used = true
    
    if params[:year].present?
      @date_range = ("#{params[:year]}-01-01".to_date)..("#{params[:year]}-12-31".to_date)
      add_breadcrumb params[:year], "flights_path(:year => #{params[:year]})"
      @date_range_text = "in #{params[:year]}"
      @flight_list_title = params[:year] + " Flight List"
      @superlatives_title = params[:year] + " Longest and Shortest Routes"
      @superlatives_title_nav = @superlatives_title.downcase
      @title = "Flights in #{params[:year]}"
      if params[:region] == "world"
        @date_path = show_year_path(params[:year])
      else
        @date_path = show_year_region_path(:year => params[:year], :region => "world")
      end
    elsif (params[:start_date].present? && params[:end_date].present?)
      if (params[:start_date] > params[:end_date])
        raise ArgumentError.new('Start date cannot be later than end date')
      end

      @date_range = (params[:start_date].to_date)..(params[:end_date].to_date)
      add_breadcrumb "#{format_date(params[:start_date].to_date)} - #{format_date(params[:end_date].to_date)}", "flights_path(:start_date => '#{params[:start_date]}', :end_date => '#{params[:end_date]}')"
      @date_range_text = "from #{format_date(params[:start_date].to_date)} to #{format_date(params[:end_date].to_date)}"
      @flight_list_title = "Flight List for #{format_date(params[:start_date].to_date)} to #{format_date(params[:end_date].to_date)}"
      @superlatives_title = "Longest and Shortest Routes for#{format_date(params[:start_date].to_date)} to #{format_date(params[:end_date].to_date)}"
      @superlatives_title_nav = "Longest and shortest routes for#{format_date(params[:start_date].to_date)} to #{format_date(params[:end_date].to_date)}"
      @title = "Flights: #{format_date(params[:start_date].to_date)} - #{format_date(params[:end_date].to_date)}"
      if params[:region] == "world"
        @date_path = show_date_range_path(:start_date => params[:start_date], :end_date => params[:end_date])
      else
        @date_path = show_date_range_region_path(:start_date => params[:start_date], :end_date => params[:end_date], :region => "world")
      end
    else
      raise ArgumentError.new('No date parameters were given for a date range')
    end
    
    @in_text = params[:year].present? ? params[:year] : "this date range"
    @new_airport_flag = false
    @new_aircraft_flag = false
    @new_airline_tag = false
    
    @years_with_flights = years_with_flights
    @year_range = years_with_flights_range
        
    if logged_in?
      @flights = Flight.where(:departure_date => @date_range)
    else
      @flights = Flight.visitor.where(:departure_date => @date_range)
    end
    
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    
    @total_distance = total_distance(@flights)
    
    @airport_array = Airport.frequency_array(@flights)
    @airport_maximum = @airport_array.first[:frequency]
      
    # Create comparitive lists of airlines and classes:
    airline_frequency(@flights)
    aircraft_frequency(@flights)
    class_frequency(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ArgumentError
    redirect_to flights_path
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find any flights in #{@in_text}. Instead, we'll give you a list of flights."
    redirect_to flights_path
    
  end
    
  def index_aircraft
    add_breadcrumb 'Aircraft Families', 'aircraft_path'
    if logged_in?
      @flight_aircraft = Flight.where("aircraft_family IS NOT NULL").group("aircraft_family").count
    else # Filter out hidden trips for visitors
      @flight_aircraft = Flight.visitor.where("aircraft_family IS NOT NULL").group("aircraft_family").count
    end
    @title = "Aircraft"
    @meta_description = "A list of the types of planes on which Paul Bogard has flown, and how often he's flown on each."
    
    # Set values for sort:
    case params[:sort_category]
    when "aircraft"
      @sort_cat = :aircraft
    when "flights"
      @sort_cat = :flights
    else
      @sort_cat = :flights
    end
    
    case params[:sort_direction]
    when "asc"
      @sort_dir = :asc
    when "desc"
      @sort_dir = :desc
    else
      @sort_dir = :desc
    end
    
    sort_mult = (@sort_dir == :asc ? 1 : -1)
    
    @aircraft_array = Array.new
    @flight_aircraft.each do |aircraft, count| 
      @aircraft_array.push({:aircraft => aircraft, :count => count})
    end
          
    # Find maxima for graph scaling:
    @aircraft_maximum = @aircraft_array.max_by{|i| i[:count]}[:count]
    
    # Sort aircraft table:
    case @sort_cat
    when :aircraft
      @aircraft_array = @aircraft_array.sort_by { |aircraft| aircraft[:aircraft] }
      @aircraft_array.reverse! if @sort_dir == :desc
    when :flights
      @aircraft_array = @aircraft_array.sort_by { |aircraft| [sort_mult*aircraft[:count], aircraft[:aircraft]] }
    end
     
  end
    
  def show_aircraft
    @logo_used = true
    @aircraft_family = params[:aircraft_family].gsub("_", " ")
    @title = @aircraft_family
    @meta_description = "Maps and lists of Paul Bogard's flights on #{@aircraft_family} aircraft."
    @flights = Flight.where(:aircraft_family => @aircraft_family)
    @flights = @flights.visitor if !logged_in? # Filter out hidden trips for visitors
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    add_breadcrumb 'Aircraft Families', 'aircraft_path'
    add_breadcrumb @aircraft_family, show_aircraft_path(@aircraft_family.gsub(" ", "_"))
    
    @total_distance = total_distance(@flights)
    
    # Create comparitive lists of airlines and classes:
    airline_frequency(@flights)
    class_frequency(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find any flights on #{@aircraft_family} aircraft. Instead, we'll give you a list of aircraft."
    redirect_to aircraft_path
  end
    
  def index_airlines
    @logo_used = true
    add_breadcrumb 'Airlines', 'airlines_path'
    if logged_in?
      @flight_airlines = Flight.where("airline IS NOT NULL").group("airline").count
      @flight_operators = Flight.where("operator IS NOT NULL").group("operator").count
    else # Filter out hidden trips for visitors
      @flight_airlines = Flight.visitor.where("airline IS NOT NULL").group("airline").count
      @flight_operators = Flight.visitor.where("operator IS NOT NULL").group("operator").count
    end
    @title = "Airlines"
    @meta_description = "A list of the airlines on which Paul Bogard has flown, and how often he's flown on each."
    
    # Set values for sort:
    case params[:sort_category]
    when "airline"
      @sort_cat = :airline
    when "flights"
      @sort_cat = :flights
    else
      @sort_cat = :flights
    end
    
    case params[:sort_direction]
    when "asc"
      @sort_dir = :asc
    when "desc"
      @sort_dir = :desc
    else
      @sort_dir = :desc
    end
    
    sort_mult = (@sort_dir == :asc ? 1 : -1)
    
    # Prepare airline list:
    @airlines_array = Array.new
    @flight_airlines.each do |airline, count| 
      @airlines_array.push({:airline => airline, :count => count})
    end
    
    # Prepare operator list:
    @operators_array = Array.new
    @flight_operators.each do |operator, count|
      @operators_array.push({:operator => operator, :count => count})
    end
    
    # Find maxima for graph scaling:
    @airlines_maximum = @airlines_array.max_by{|i| i[:count]}[:count]
    @operators_maximum = @operators_array.max_by{|i| i[:count]}[:count]
    
    # Sort airline and operator tables:
    case @sort_cat
    when :airline
      @airlines_array = @airlines_array.sort_by { |airline| airline[:airline] }
      @operators_array = @operators_array.sort_by { |operator| operator[:operator] }
      @airlines_array.reverse! if @sort_dir == :desc
      @operators_array.reverse! if @sort_dir == :desc
    when :flights
      @airlines_array = @airlines_array.sort_by { |airline| [sort_mult*airline[:count], airline[:airline]] }
      @operators_array = @operators_array.sort_by { |operator| [sort_mult*operator[:count], operator[:operator]] }
    end
  end
    
  def show_airline
    @logo_used = true
    @airline = params[:airline].gsub("_", " ")
    @title = @airline
    @meta_description = "Maps and lists of Paul Bogard's flights on #{@airline}."
    @flights = Flight.where(:airline => @airline)
    @flights = @flights.visitor if !logged_in? # Filter out hidden trips for visitors
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    add_breadcrumb 'Airlines', 'airlines_path'
    add_breadcrumb @airline, show_airline_path(@airline.gsub(" ", "_"))
    
    @total_distance = total_distance(@flights)
    
    # Create comparitive lists of aircraft and classes:
    aircraft_frequency(@flights)
    class_frequency(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find any flights on #{@airline}. Instead, we'll give you a list of airlines."
    redirect_to airlines_path
  end
  
  def show_operator
    @logo_used = true
    @operator = params[:operator].gsub("_", " ")
    @title = @operator
    @meta_description = "Maps and lists of Paul Bogard's flights operated by #{@operator}."
    @flights = Flight.where(:operator => @operator)
    @flights = @flights.visitor if !logged_in? # Filter out hidden trips for visitors
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    add_breadcrumb 'Airlines', 'airlines_path'
    add_breadcrumb 'Flights Operated by ' + @operator, show_operator_path(@operator.gsub(" ", "_"))
    
    @total_distance = total_distance(@flights)
    
    # Create comparitive lists of airlines, aircraft and classes:
    airline_frequency(@flights)
    aircraft_frequency(@flights)
    class_frequency(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
    # Create list of fleet numbers and aircraft families:
    @fleet_family = Hash.new
    @flights.each do |flight|
      if flight.fleet_number
        @fleet_family[flight.fleet_number] = flight.aircraft_family
      end
    end
    @fleet_family = @fleet_family.sort_by{ |key, value| key }
    
    @operator_icon_path = Flight.new(:airline => @operator).airline_icon_path
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find any flights operated by #{@operator}. Instead, we'll give you a list of airlines and operators."
    redirect_to airlines_path
  end
  
  def show_fleet_number
    @logo_used = true
    @operator = params[:operator].gsub("_", " ")
    @fleet_number = params[:fleet_number]
    @title = @operator + " #" + @fleet_number
    @meta_description = "Maps and lists of Paul Bogard's flights operated on #{@operator} ##{@fleet_number}."
    @flights = Flight.where(:operator => @operator, :fleet_number => @fleet_number)
    @flights = @flights.visitor if !logged_in? # Filter out hidden trips for visitors
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    add_breadcrumb 'Airlines', 'airlines_path'
    add_breadcrumb 'Flights Operated by ' + @operator, show_operator_path(@operator.gsub(" ", "_"))
    add_breadcrumb '#' + @fleet_number, show_fleet_number_path(@operator, @fleet_number)
    
    @total_distance = total_distance(@flights)
    
    # Create comparitive lists of airlines, aircraft and classes:
    airline_frequency(@flights)
    aircraft_frequency(@flights)
    class_frequency(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find any flights operated by #{@operator} with fleet number ##{@fleet_number}. Instead, we'll give you a list of airlines and operators."
    redirect_to airlines_path
  end
    
  def index_classes
    add_breadcrumb 'Travel Classes', 'classes_path'
    if logged_in?
      @flight_classes = Flight.where("travel_class IS NOT NULL").group("travel_class").count
    else # Filter out hidden trips for visitors
      @flight_classes = Flight.visitor.where("travel_class IS NOT NULL").group("travel_class").count
    end
    @title = "Travel Classes"
    @meta_description = "A count of how many times Paul Bogard has flown in each class."
    @classes_array = Array.new
    @flight_classes.each do |travel_class, count| 
      @classes_array.push({:travel_class => travel_class, :count => count})
    end
    @classes_array = @classes_array.sort_by { |travel_class| [-travel_class[:count], travel_class[:travel_class]] }
    @classes_maximum = @classes_array.first[:count]
  end
  
  def show_class
    @logo_used = true
    @flights = Flight.where(:travel_class => params[:travel_class])
    @flights = @flights.visitor if !logged_in? # Filter out hidden trips for visitors
    @title = params[:travel_class].titlecase + " Class"
    @meta_description = "Maps and lists of Paul Bogard's #{params[:travel_class].downcase} class flights."
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    add_breadcrumb 'Travel Classes', 'classes_path'
    add_breadcrumb params[:travel_class].titlecase, show_class_path(params[:travel_class])
    
    @total_distance = total_distance(@flights)
    
    # Create comparitive lists of airlines and aircraft:
    airline_frequency(@flights)
    aircraft_frequency(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find any flights in #{@title}. Instead, we'll give you a list of travel classes."
    redirect_to classes_path
  end

  def index_tails
    add_breadcrumb 'Tail Numbers', 'tails_path'
    if logged_in?
      @flight_tail_numbers = Flight.where("tail_number IS NOT NULL").group("tail_number").count
      @flight_tail_details = Flight.where("tail_number IS NOT NULL").order("departure_utc ASC")
    else # Filter out hidden trips for visitors
      @flight_tail_numbers = Flight.visitor.where("tail_number IS NOT NULL").group("tail_number").count
      @flight_tail_details = Flight.visitor.where("tail_number IS NOT NULL").order("departure_utc ASC")
    end
    @title = "Tail Numbers"
    @meta_description = "A list of the individual airplanes Paul Bogard has flown on, and how often he's flown on each."
    
    # Set values for sort:
    case params[:sort_category]
    when "tail"
      @sort_cat = :tail
    when "flights"
      @sort_cat = :flights
    when "aircraft"
      @sort_cat = :aircraft
    when "airline"
      @sort_cat = :airline
    else
      @sort_cat = :flights
    end
    
    case params[:sort_direction]
    when "asc"
      @sort_dir = :asc
    when "desc"
      @sort_dir = :desc
    else
      @sort_dir = :desc
    end
    
    sort_mult = (@sort_dir == :asc ? 1 : -1)
    
    # Create tail number count array    
    tails_count = Array.new
    @flight_tail_numbers.each do |tail_number, count| 
      tails_count.push({:tail_number => tail_number, :count => count})
    end
    
    # Create details array, using the latest flight for each tail number.
    tails_airline_hash = Hash.new
    tails_aircraft_hash = Hash.new
    @flight_tail_details.each do |tail|
      tails_airline_hash[tail.tail_number] = tail.airline
      tails_aircraft_hash[tail.tail_number] = tail.aircraft_family
    end
    
    # Create table array
    @tail_numbers_table = Array.new
    tails_count.each do |tail|
      @tail_numbers_table.push({:tail_number => tail[:tail_number], :count => tail[:count], :aircraft => tails_aircraft_hash[tail[:tail_number]] || "", :airline => tails_airline_hash[tail[:tail_number]] || ""})
    end
    
    # Find maxima for graph scaling:
    @flights_maximum = @tail_numbers_table.max_by{|i| i[:count]}[:count]
    
    # Sort tails table:
    case @sort_cat
    when :tail
      @tail_numbers_table = @tail_numbers_table.sort_by {|tail| tail[:tail_number]}
      @tail_numbers_table.reverse! if @sort_dir == :desc
    when :flights
      @tail_numbers_table = @tail_numbers_table.sort_by {|tail| [sort_mult*tail[:count], tail[:tail_number]]}
    when :aircraft
      @tail_numbers_table = @tail_numbers_table.sort_by {|tail| [tail[:aircraft], tail[:airline]]}
      @tail_numbers_table.reverse! if @sort_dir == :desc
    when :airline
      @tail_numbers_table = @tail_numbers_table.sort_by { |tail| [tail[:airline], tail[:aircraft]]}
      @tail_numbers_table.reverse! if @sort_dir == :desc
    end
    
    
  end
  
  def show_tail
    @logo_used = true
    @flights = Flight.where(:tail_number => params[:tail_number])
    @flights = @flights.visitor if !logged_in? # Filter out hidden trips for visitors
    @flight_operators = @flights.where("operator IS NOT NULL").group("operator").count
    
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    @title = params[:tail_number]
    @meta_description = "Maps and lists of Paul Bogard's flights on tail number #{params[:tail_number]}."
    add_breadcrumb 'Tail Numbers', 'tails_path'
    add_breadcrumb @title, show_tail_path(params[:tail_number])
    
    @total_distance = total_distance(@flights)
    
    # Create comparitive list of classes:
    class_frequency(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
    # Create list of fleet numbers used by this tail:
    @operators_array = Array.new
    @flight_operators.each do |operator, count|
      @operators_array.push({:operator => operator, :count => count})
    end
    @operators_array = @operators_array.sort_by { |operator| [-operator[:count], operator[:operator]] }
    @operators_maximum = @flight_operators.length > 0 ? @operators_array.first[:count] : 1
    
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find any flights with the tail number #{params[:tail_number]}. Instead, we'll give you a list of tail numbers."
    redirect_to tails_path
  end
  

    
  def new
    @title = "New Flight"
    add_breadcrumb 'Flights', 'flights_path'
    add_breadcrumb 'New Flight', 'new_flight_path'
    @flight = Trip.find(params[:trip_id]).flights.new
  end
    
  def create
    @flight = Trip.find(params[:flight][:trip_id]).flights.new(params[:flight])
    if @flight.save
      flash[:success] = "Successfully added #{params[:flight][:airline]} #{params[:flight][:flight_number]}."
      if (@flight.tail_number.present? && Flight.where(:tail_number => @flight.tail_number).count > 1)
        flash[:success] += " You've had prior flights on this tail!"
      end
      redirect_to @flight
    else
      render 'new'
    end
  end
    
  def edit
    @flight = Flight.find(params[:id])
    add_breadcrumb 'Flights', 'flights_path'
    add_breadcrumb "#{@flight.airline} #{@flight.flight_number}", 'flight_path(@flight)'
    add_breadcrumb 'Edit Flight', 'edit_flight_path(@flight)'
  end
    
  def update
    @flight = Flight.find(params[:id])
    if @flight.update_attributes(params[:flight])
      flash[:success] = "Successfully updated flight."
      if (@flight.tail_number.present? && Flight.where(:tail_number => @flight.tail_number).count > 1)
        flash[:success] += " You've had prior flights on this tail!"
      end
      redirect_to @flight
    else
      render 'edit'
    end
  end
    
  def destroy
    Flight.find(params[:id]).destroy
    flash[:success] = "Flight destroyed."
    redirect_to flights_path
  end
    
  private
  
    def logged_in_user
      redirect_to flightlog_path unless logged_in?
    end
    
    
    
    def years_with_flights
      if logged_in?
        flights = Flight.all
      else
        flights = Flight.visitor
      end
    
      # Determine which years have flights:
      years_with_flights = Hash.new(false)
      flights.each do |flight|
        years_with_flights[flight.departure_date.year] = true
      end
      return years_with_flights
    end
    
    def years_with_flights_range
      if logged_in?
        return Flight.first.departure_date.year..Flight.last.departure_date.year
      else
        return Flight.visitor.first.departure_date.year..Flight.visitor.last.departure_date.year
      end
      return false      
    end
end
