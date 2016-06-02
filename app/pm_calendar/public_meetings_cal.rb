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
		@packageCancelled = []
		@weekDayArray = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"] # [0, 1, 2, 3, 4, 5, 6]	
		@weekDayNameArray = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"] # [0, 1, 2, 3, 4, 5, 6]
		@countDayArray = ["", "first", "second", "third", "fourth", "fifth"] # [0, 1, 2, 3, 4, 5]
    end

    def query
		LOGGER.info "Started calendar update"
		puts 'querying now...'
		open(@url) do |cal|
			@cal=Icalendar.parse(cal)
		end
	  ########## Creating Cancelled meeting array ##############
	  @cal.each do |c|
			c.events.each do |event|
				if event.dtstart.to_datetime.hour != 0 and event.summary.upcase.index('Canceled'.upcase) != nil or event.summary.upcase.index('Cancelled'.upcase) != nil then
					cancelledTitle = "#{event.summary}".gsub('Canceled - ','').gsub('Canceled- ','').gsub('Canceled-','').gsub('Canceled : ','').gsub('Canceled: ','').gsub('Canceled:','').gsub('Canceled ','').gsub('Cancelled - ','').gsub('Cancelled- ','').gsub('Cancelled-','').gsub('Cancelled : ','').gsub('Cancelled: ','').gsub('Cancelled:','').gsub('Cancelled ','').gsub('CANCELED - ','').gsub('CANCELED- ','').gsub('CANCELED-','').gsub('CANCELED : ','').gsub('CANCELED: ','').gsub('CANCELED:','').gsub('CANCELED ','').gsub('CANCELLED - ','').gsub('CANCELLED- ','').gsub('CANCELLED-','').gsub('CANCELLED : ','').gsub('CANCELLED: ','').gsub('CANCELLED:','').gsub('CANCELLED ','').gsub(' - Canceled','').gsub('- Canceled','').gsub('-Canceled','').gsub(' : Canceled','').gsub(': Canceled','').gsub(':Canceled','').gsub(' Canceled','').gsub(' - Cancelled','').gsub('- Cancelled','').gsub('-Cancelled','').gsub(' : Cancelled','').gsub(': Cancelled','').gsub(':Cancelled','').gsub(' Cancelled','').gsub(' - CANCELED','').gsub('- CANCELED','').gsub('-CANCELED','').gsub(' : CANCELED','').gsub(': CANCELED','').gsub(':CANCELED','').gsub(' CANCELED','').gsub(' - CANCELLED','').gsub('- CANCELLED','').gsub('-CANCELLED','').gsub(' : CANCELLED','').gsub(': CANCELLED','').gsub(':CANCELLED','').gsub(' CANCELLED','').gsub('Canceled','').gsub('Cancelled','').gsub('CANCELED','').gsub('CANCELLED','').strip
					matchingDateTime = DateTime.new(event.dtstart.year, event.dtstart.month, event.dtstart.day, event.dtstart.to_datetime.hour, event.dtstart.to_datetime.min)
					@packageCancelled << "#{cancelledTitle}=#{matchingDateTime}=#{event.location}"
				end
			end
      end
	  #################### End ############################
      @cal.each do |c|
          c.events.each do |event|
            @duration = ((((event.dtend.to_datetime - event.dtstart.to_datetime )*24)*60)*60)
			checkingTitle = "#{event.summary}".strip # making trim because same way is added in cencelled array

			matchingDateTime = DateTime.new(event.dtstart.year, event.dtstart.month, event.dtstart.day, event.dtstart.to_datetime.hour, event.dtstart.to_datetime.min)
			checkingCancelled = "#{checkingTitle}=#{matchingDateTime}=#{event.location}"
			if @packageCancelled.index(checkingCancelled) == nil then
				cal_events ={
				  :Title => event.summary,
				  :Start => event.dtstart.strftime("%m/%d/%Y %I:%M %p"),
				  :End => event.dtend.strftime("%m/%d/%Y %I:%M %p"),
				  :Duration =>  hm(@duration),
				  :Description => event.description,
				  :Where => event.location,
				  :Attendees => 'Public Meetings',
				  :Recurrence => ''
				}
				@package << cal_events
			end
			
			countRrule = 0
			eventFrequency = ""

			if event.rrule.size != 0 and event.dtstart.to_datetime.hour != 0 then
				#puts " #{event.rrule[0].until} -- #{event.dtstart} --- #{event.dtend} --- #{event.summary} "
				#puts "**#{event.rrule[0].frequency}**"
				eventFrequency = event.rrule[0].frequency
				actualStart = event.dtstart	
				actualEnd = event.dtend
				
				if eventFrequency == "MONTHLY" then
					by_day = "#{event.rrule[0].by_day}"  #'["4TH"]'
					dayMeeting = by_day[3, 2]	#return substring of 2 char start from 3
					weekMeeting = by_day[2, 1]  #return substring of 1 char start from 2
					#puts by_day
					#puts dayMeeting
					if event.rrule[0].until == nil and weekMeeting != "-" then
						todayDate = DateTime.now
						countRrule = (todayDate.to_datetime.year * 12 + todayDate.to_datetime.month) - (event.dtstart.year * 12 + event.dtstart.month)
						recurrenceFrequency = "#{eventFrequency.capitalize} on the #{@countDayArray[Integer(weekMeeting)]} #{@weekDayNameArray[@weekDayArray.index(dayMeeting)]}"
						for i in 0..(countRrule+11) do 
							date = Date.new(actualStart.year, actualStart.month, 1) + 1.months
							dayDate = date.wday
							dayCal = @weekDayArray.index(dayMeeting)
			#puts "dayCal --> #{dayCal} <> dayDate --> #{dayDate} -- #{actualStart}"
							dayNew = 0
							if dayDate == dayCal
								dayNew = 1
							elsif dayDate > dayCal			
								dayNew = 7 - (dayDate - dayCal - 1)
							else
								dayNew = (dayCal - dayDate + 1)
							end
							#puts dayNew
							dayNew = dayNew + ((Integer(weekMeeting) - 1) * 7)
							actualStart = DateTime.new(actualStart.year, actualStart.month, dayNew, event.dtstart.hour, event.dtstart.min, event.dtstart.sec, event.dtstart.zone) + 1.months  
							actualEnd = DateTime.new(actualEnd.year, actualEnd.month, dayNew, event.dtend.hour, event.dtend.min, event.dtend.sec, event.dtend.zone) + 1.months 

							matchingDateTime = DateTime.new(actualStart.year, actualStart.month, actualStart.day, actualStart.to_datetime.hour, actualStart.to_datetime.min)
							checkingCancelled = "#{checkingTitle}=#{matchingDateTime}=#{event.location}"
							if @packageCancelled.index(checkingCancelled) == nil then
							cal_events ={
								  :Title => event.summary,
								  :Start => actualStart.strftime("%m/%d/%Y %I:%M %p"),
								  :End => actualEnd.strftime("%m/%d/%Y %I:%M %p"),
								  :Duration =>  hm(@duration),
								  :Description => event.description,
								  :Where => event.location,
								  :Attendees => 'Public Meetings',
								  :Recurrence => recurrenceFrequency
								}	
								@package << cal_events
							end
						end
					elsif weekMeeting != "-" then
						recurrenceFrequency = "#{eventFrequency.capitalize} on the #{@countDayArray[Integer(weekMeeting)]} #{@weekDayNameArray[@weekDayArray.index(dayMeeting)]}"
						countRrule = (event.rrule[0].until.to_datetime.year * 12 + event.rrule[0].until.to_datetime.month) - (event.dtstart.year * 12 + event.dtstart.month)
						for j in 0..countRrule-1 do 
							date = Date.new(actualStart.year, actualStart.month, 1) + 1.months
							dayDate = date.wday
							dayCal = @weekDayArray.index(dayMeeting)
							dayNew = 0
							if dayDate == dayCal
								dayNew = 1
							elsif dayDate > dayCal			
								dayNew = 7 - (dayDate - dayCal - 1)
							else
								dayNew = (dayCal - dayDate + 1)
							end
							#puts dayNew
							dayNew = dayNew + ((Integer(weekMeeting) - 1) * 7)
							actualStart = DateTime.new(actualStart.year, actualStart.month, dayNew, event.dtstart.hour, event.dtstart.min, event.dtstart.sec, event.dtstart.zone)  + 1.months 
							actualEnd = DateTime.new(actualEnd.year, actualEnd.month, dayNew, event.dtend.hour, event.dtend.min, event.dtend.sec, event.dtend.zone)   + 1.months
							
							matchingDateTime = DateTime.new(actualStart.year, actualStart.month, actualStart.day, actualStart.to_datetime.hour, actualStart.to_datetime.min)
							checkingCancelled = "#{checkingTitle}=#{matchingDateTime}=#{event.location}"
							if @packageCancelled.index(checkingCancelled) == nil then
							cal_events ={
								  :Title => event.summary,
								  :Start => actualStart.strftime("%m/%d/%Y %I:%M %p"),
								  :End => actualEnd.strftime("%m/%d/%Y %I:%M %p"),
								  :Duration =>  hm(@duration),
								  :Description => event.description,
								  :Where => event.location,
								  :Attendees => 'Public Meetings',
								  :Recurrence => recurrenceFrequency
								}
								@package << cal_events
							end
						end						
					end
					elsif eventFrequency == "WEEKLY" then
						by_day = "#{event.rrule[0].by_day}"  #'["4TH"]'
						dayMeeting = by_day[2, 2]	#return substring of 2 char start from 3
						if event.rrule[0].count == nil then
							recurrenceFrequency = "#{eventFrequency.capitalize} on #{@weekDayNameArray[@weekDayArray.index(dayMeeting)]}"
						else
							recurrenceFrequency = "#{eventFrequency.capitalize} on #{@weekDayNameArray[@weekDayArray.index(dayMeeting)]}, #{event.rrule[0].count} times"
						end
						if event.rrule[0].until == nil then
							todayDate = DateTime.now
							countRrule = (todayDate.to_datetime.year * 12 + todayDate.to_datetime.month) - (event.dtstart.year * 12 + event.dtstart.month)
							for i in 0..(countRrule*4) do 
								actualStart = actualStart + 7.days
								actualEnd = actualEnd + 7.days
								
								matchingDateTime = DateTime.new(actualStart.year, actualStart.month, actualStart.day, actualStart.to_datetime.hour, actualStart.to_datetime.min)
								checkingCancelled = "#{checkingTitle}=#{actualStart}=#{event.location}"
								if @packageCancelled.index(checkingCancelled) == nil then
								cal_events ={
									  :Title => event.summary,
									  :Start => actualStart.strftime("%m/%d/%Y %I:%M %p"),
									  :End => actualEnd.strftime("%m/%d/%Y %I:%M %p"),
									  :Duration =>  hm(@duration),
									  :Description => event.description,
									  :Where => event.location,
									  :Attendees => 'Public Meetings',
									  :Recurrence => recurrenceFrequency
									}	
									@package << cal_events
								end
							end
						else
							countRrule = (event.rrule[0].until.to_datetime.year * 12 + event.rrule[0].until.to_datetime.month) - (event.dtstart.year * 12 + event.dtstart.month)
							for j in 0..(countRrule*4) do 
								actualStart = actualStart + 7.days
								actualEnd = actualEnd + 7.days
								
								matchingDateTime = DateTime.new(actualStart.year, actualStart.month, actualStart.day, actualStart.to_datetime.hour, actualStart.to_datetime.min)
								checkingCancelled = "#{checkingTitle}=#{actualStart}=#{event.location}"
								if @packageCancelled.index(checkingCancelled) == nil then
								cal_events ={
									  :Title => event.summary,
									  :Start => actualStart.strftime("%m/%d/%Y %I:%M %p"),
									  :End => actualEnd.strftime("%m/%d/%Y %I:%M %p"),
									  :Duration =>  hm(@duration),
									  :Description => event.description,
									  :Where => event.location,
									  :Attendees => 'Public Meetings',
									  :Recurrence => recurrenceFrequency
									}	
									@package << cal_events
								end
							end
						end					
					end
				end
			end
		end
		push_to_socrata3
	end
	####################### SAVE public meeting to Socrata open data #######################################
    def push_to_socrata
		#puts @package
      
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
