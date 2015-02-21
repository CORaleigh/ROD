#public_meetings_cal.rb

require 'net/https'
require 'hashie'
require 'rubygems'
require 'soda/client'
require 'configatron'      #configatron for private usernames, passwords ...'
require 'date'
require 'open-uri'
require 'icalendar'
require_relative '../../lib/cal_logger.rb'
require_relative '../../lib/defaults.rb'
require_relative '../../lib/helpers.rb'

class Calendar

  def initialize
    @client = SODA::Client.new({
      :domain => 'data.raleighnc.gov',
      :app_token => configatron.app_token,
      :username => configatron.client_username,
      :password => configatron.client_pass,
      :content_type => 'text/plain',
     # :mime_type => 'JSON',
      :ignore_ssl => true
      })
      @view_id = 'snpm-8ugp'
      @url = "https://www.google.com/calendar/ical/bbu0e1ro8btjdop8c5ie6spjpo%40group.calendar.google.com/public/basic.ics"
      @package = []
    end

    def query
      LOGGER.info "Started calendar update"
      puts 'querying now...'
      open(@url) do |cal|
        @cal=Icalendar.parse(cal)
      end
      @cal.each do |c|
          c.events.each do |event|
            @duration = ((((event.dtend.to_datetime - event.dtstart.to_datetime )*24)*60)*60)
            cal_events ={
              :Title => event.summary,
              :Start => event.dtstart.strftime("%m/%d/%Y %I:%M %p"),
              :End => event.dtend.strftime("%m/%d/%Y %I:%M %p"),
              :Duration =>  hm(@duration),
              :Description => event.description,
              :Where => event.location,
              :Attendees => 'Public Meetings'
            }
            @package << cal_events
          end
      end
      push_to_socrata
    end
    def push_to_socrata
      puts @package
      
      response = @client.put(@view_id, @package)

      puts '.........all inspections...........'
      puts response["Errors"].to_s + 'Errors'
      puts response["Rows Deleted"].to_s + ' Rows Deleted'
      puts response["Rows Created"].to_s + ' Rows Created'
      puts response["Rows Updated"].to_s + ' Rows Updated'
      LOGGER.info "Update complete"
      LOGGER.info "................. #{response["Errors"]} Errors"
      LOGGER.info "................. #{response["Rows Deleted"]} Rows Deleted"
      LOGGER.info "................. #{response["Rows Created"]} Rows Created"
      LOGGER.info "................. #{response["Rows Updated"]} Rows Updated"

    end
end
   

    Calendar.new.query
