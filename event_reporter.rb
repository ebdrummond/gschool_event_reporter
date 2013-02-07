require "csv"
require "sunlight"

Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"

class EventReporter
	attr_accessor :contents, :queue

	def initialize
		@contents = []
		@queue = []
		puts "EventReporter initialized."
	end

	def run
		command = ""
		while command != "q"
			print "Enter command.  For options, enter Help.\n>"
			command = gets.chomp
			case command
			when 'help' then help
			when 'queue count' then queue_count
			when 'queue clear' then queue_clear
			when 'queue print' then queue_print
			when 'quit' then quit_loop
			else
				input = command.split(" ")
				if input[0] == "help"
					help_command(input)
				elsif input[0] == 'load'
					load(input)
				elsif input[0] == 'find'
					find(input)
				elsif input[0..1].join(" ") == 'queue save'
					queue_save(input)
				elsif input[0..1].join(" ") == 'queue print'
					queue_print_by(input)
				else
					puts "I'm sorry, I don't know #{command}."
				end
			end
		end
	end	

	def help
		puts "\nYour available commands are:"
		puts "load file"
		puts "find"
		puts "queue count"
		puts "queue clear"
		puts "queue print"
		puts "queue print attribute"
		puts "queue save"
		puts "quit"
		puts "Enter Help and one of the above commands to access command descriptions."
		puts ""
	end

	def quit_loop
		puts "Goodbye!"
		exit
	end

	def help_command(input)
		case input[1]
		when "queue" then
			case input[2..-1].join(" ")
			when 'count' then puts "Queue count determines how many records are in the current queue."
			when 'clear' then puts "Queue clear empties your current queue."
			when 'print' then puts "Queue print prints out a data table of your current queue."
			when 'print attribute' then puts "Queue print attribute prints out a data table of your current queue sorted by your chosen search criteria."
			when 'save' then puts "Save saves your current queue."
			end
		when 'find' then puts "Find loads the queue with your selected search criteria."
		when 'load' then puts "Load file loads the file you have selected.  If you do not select a file, event_attendees.csv will be loaded."
		when 'quit' then puts "Quit will quit the EventReporter program."
		end
	end

	def load(input)
		if input[1] != nil
			filename = input [1]
			file = CSV.open(filename, :headers => true)
		else
			file = CSV.open("event_attendees.csv", :headers => true)
		end

		@contents = []
		file.each do |line|
			line.each do |column_name, column_value|
				if column_value == nil
					line[column_name] = ""
				end
			end
			zipcode = Zipcode.new
			phone_number = CleanPhone.new
			line["Zipcode"] = zipcode.clean_zipcode(line["Zipcode"])
			line["HomePhone"] = phone_number.clean_phone_number(line["HomePhone"])
			line.delete("RegDate")
			line.delete(" ") #deleting first line (ID line) of csv
			@contents.push line
		end
		puts "File loaded."
	end

	def queue_count
		puts "Your queue count is #{@queue.size}."
	end

	def queue_clear
		@queue = []
		puts "Your queue has been cleared."
	end

	def find(input)
		@queue_clear

		case input[1]
		when 'first_name' then
			@queue = @contents.select { |line| line["first_Name"].downcase == input[2..-1].join(" ").downcase }
		when 'last_name' then
			@queue = @contents.select { |line| line["last_Name"].downcase == input[2..-1].join(" ").downcase }
		when 'email' then
			@queue = @contents.select { |line| line["Email_Address"].downcase == input[2..-1].join(" ").downcase }
		when 'zipcode' then
			@queue = @contents.select { |line| line["Zipcode"] == input[2..-1] }
		when 'city' then
			@queue = @contents.select { |line| line["City"].downcase == input[2..-1].join(" ").downcase }
		when 'state' then
			@queue = @contents.select { |line| line["State"].downcase == input[2..-1].join(" ").downcase }
		when 'address' then
			@queue = @contents.select { |line| line["Street"].downcase == input[2..-1].join(" ").downcase }
		when 'phone_number'then
			@queue = @contents.select { |line| line["HomePhone"] == input[2..-1].join(" ").downcase }
		end
	
		puts @queue
		queue_count
	end

	def queue_save(input)
		filename = input[3..-1].join(" ")
		File.open(filename, 'w') do |file|
			header_labels = ["first_Name", "last_Name", "Email_Address", "HomePhone", "Street", "City", "State", "Zipcode"]
			file << header_labels.join(",") + "\n"
				@queue.each do |line|
					file << line
				end
		puts "File saved."
		end
	end

	def queue_print
		header_labels = {"first_Name" => "First Name", "last_Name" => "Last Name", "Email_Address" => "E-mail Address", "HomePhone" => "Phone Number", "Street" => "Address", "City" => "City", "State" => "State", "Zipcode" => "Zipcode"}
		header_labels.each do |csv_label, nice_label|
			print nice_label + "\t\t"
		end
		print "\n"
		@queue.each do |line|
			header_labels.each do |csv_label, nice_label|
				print line[csv_label] + "\t\t"
			end
			print "\n"
		end
	end

	def queue_print_by(input)
		case input[3]
		when 'first_name' then
			@queue.sort_by!{ |line| line["first_Name"].downcase }
		when 'last_name' then
			@queue.sort_by!{ |line| line["last_Name"].downcase }
		when 'email' then
			@queue.sort_by!{ |line| line["Email_Address"].downcase }
		when 'zipcode' then
			@queue.sort_by!{ |line| line["Zipcode"] }
		when 'city' then
			@queue.sort_by!{ |line| line["City"].downcase }
		when 'state' then
			@queue.sort_by!{ |line| line["State"].downcase }
		when 'address' then
			@queue.sort_by!{ |line| line["Street"].downcase }
		when 'phone_number'then
			@queue.sort_by!{ |line| line["HomePhone"] }
		end

		queue_print
	end
end

class CleanPhone

    def clean_phone_number(number)
    	if number == nil
    		""
    	end
        number = number.delete("(")
        number = number.delete(")")
        number = number.delete("-")
        number = number.delete(".")
        number = number.delete(" ")
        #code didn't work when I tried to put these all into one function call
        if number.length <10 || number.length >11
            ""
        elsif number.length == 11
            if number[0] != 1
                ""
            else 
                number[1..10]
            end
        else 
            number
        end
    end
end

class Zipcode

    def clean_zipcode(zipcode)
        if zipcode.nil?
            "XXXXX"
        else
            "0"*(5 - zipcode.length)+zipcode
        end
    end
end



event = EventReporter.new
event.run