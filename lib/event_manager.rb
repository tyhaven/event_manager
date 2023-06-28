require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

$times = {}

def clean_zip(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def get_legislator(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
    begin
        legislators = civic_info.representative_info_by_address(
            address: zip,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
        # legislator_names = legislators.map(&:name).join(', ')
    rescue
        'You can find your representatives by visitingwww.commomcause.org'
    end
end


puts 'Event Manager Initialized!'

contents = CSV.open(
    'event_attendees.csv', 
    headers: true,
    header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

def form_letter_method(row, form_letter)

    Dir.mkdir('output') unless Dir.exist?('output')

    filename = "output/thanks_#{row}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end


end

def phone_numbers(phone)
    if phone.length < 10
         "Invalid number"
     elsif phone.length == 11 && !phone.start_with?('1')
         "Invalid number"
     elsif phone.length > 11
        "Invalid number"
     elsif phone.length == 11 && phone.start_with?('1')
        phone.slice(1..10)
     elsif phone.length == 10
        phone
     end
end

def get_hour(fulltime)
    time = DateTime.strptime(fulltime, "%m/%d/%y %k:%M")
    hour = time.hour
    if $times[hour]
        $times[hour] += 1
    else 
        $times[hour] = 0
        $times[hour] += 1
    end
end


contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zip(row[:zipcode])
    legislators = get_legislator(zipcode)
    form_letter = erb_template.result(binding)
    full_time = row[:regdate]

    get_hour(full_time)
end

sorted_hours = $times.sort_by {|k, v| -v}
puts sorted_hours[0..4]

