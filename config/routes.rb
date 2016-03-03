Portfolio::Application.routes.draw do

  resources :users
  resources :sessions, :only => [:new, :create, :destroy]

  root :to => 'pages#home'
  
  match '/projects', :to => 'pages#projects'
  match '/resume', :to => 'pages#resume'
  match '/about', :to => 'pages#about'
  match '/other', :to => 'pages#other'
  
  #match '/signup', :to => 'users#new'
  #match '/login', :to => 'sessions#new'
  match '/logout', :to => 'sessions#destroy', :via => :delete
  
  match '/computers', :to => 'pages#computers'
  match '/computer_history', :to => 'pages#computer_history'
  match '/cooking', :to => 'pages#cooking'
  match '/current_home', :to => 'pages#current_home'
  match '/ebdb', :to => 'pages#ebdb'
  match '/flight_log', :to => 'pages#flight_log'
  match '/gps_log', :to => 'pages#gps_log'
  match '/gps_logging_garmin', :to => 'pages#gps_logging_garmin'
  match '/gps_logging_iphone', :to => 'pages#gps_logging_iphone'
  match '/hotel_internet_quality', :to => 'pages#hotel_internet_quality'
  match '/itinerary/', :to => 'pages#itinerary'
  match '/modeling/', :to => 'pages#modeling'
  match '/stephenvlog/', :to => 'pages#stephenvlog'
  match '/tulsa_penguins', :to => 'pages#tulsa_penguins'
  match '/turn_signal_counter', :to => 'pages#turn_signal_counter'
  match '/visor_cam', :to => 'pages#visor_cam'
  
  match '/pax_prime_2012', :to => 'pages#pax_prime_2012'
  
  # Permanently redirect legacy flight log routes to Flight Historian:
  
  match '/flightlog',       :to => redirect('http://www.flighthistorian.com/', :status => 301)
  match '/flightlog/*all',  :to => redirect('http://www.flighthistorian.com/', :status => 301)
  
  match '/flights',         :to => redirect('http://www.flighthistorian.com/flights', :status => 301)
  match '/flights/*all',    :to => redirect('http://www.flighthistorian.com/flights', :status => 301)

  match '/trips',           :to => redirect('http://www.flighthistorian.com/trips', :status => 301)
  match '/trips/*all',      :to => redirect('http://www.flighthistorian.com/trips', :status => 301)
  
  match '/aircraft',        :to => redirect('http://www.flighthistorian.com/aircraft', :status => 301)
  match '/aircraft/*all',   :to => redirect('http://www.flighthistorian.com/aircraft', :status => 301)
  
  match '/airlines',        :to => redirect('http://www.flighthistorian.com/airlines', :status => 301)
  match '/airlines/*all',   :to => redirect('http://www.flighthistorian.com/airlines', :status => 301)
  match '/operators/*all',  :to => redirect('http://www.flighthistorian.com/airlines', :status => 301)
  
  match '/airports',        :to => redirect('http://www.flighthistorian.com/airports', :status => 301)
  match '/airports/*all',   :to => redirect('http://www.flighthistorian.com/airports', :status => 301)
  
  match '/classes',         :to => redirect('http://www.flighthistorian.com/classes', :status => 301)
  match '/classes/*all',    :to => redirect('http://www.flighthistorian.com/classes', :status => 301)
  
  match '/tails',           :to => redirect('http://www.flighthistorian.com/tails', :status => 301)
  match '/tails/*all',      :to => redirect('http://www.flighthistorian.com/tails', :status => 301)
  
  match '/routes',          :to => redirect('http://www.flighthistorian.com/routes', :status => 301)
  match '/routes/*all',     :to => redirect('http://www.flighthistorian.com/routes', :status => 301)
  
end
