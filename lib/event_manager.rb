require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone(phone_no)
  phone = ""
  idx = 0
  while idx < phone_no.length
    digit = phone_no[idx]
    if digit != nil
      if digit >= '0' && digit <= '9'
        phone = phone + digit
#        puts "Digit #{digit}, Phone: #{phone}"
      end
    end
    idx = idx + 1
  end
  if phone.length < 10
    return ""
  end
  if phone.length == 10
    return phone
  end
  if phone.length == 11
    if phone[0] == '1'
      phone = phone[1..]
      return phone
    end
    return ""    
  end
  return ""
end

def hour_range(date_time)
  begin
    reg_time = Time.strptime(date_time, "%D %H:%M")
    return reg_time.hour.to_s
  rescue
    puts date_time
    return "0"
  end
end

def dow(date_time)
  begin
    reg_time = Time.strptime(date_time, "%D %H:%M")
    return reg_time.strftime("%A")   
  rescue
    puts date_time
    return "Sunday"
  end
end
puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hour_map = {}
dow_map = {}
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_no = clean_phone(row[:homephone])
  hour = hour_range(row[:regdate])
  hour_map[hour] = hour_map[hour] == nil ? 1: hour_map[hour] + 1
  dow = dow(row[:regdate])
  dow_map[dow] = dow_map[dow] == nil ? 1: dow_map[dow] + 1
#  puts phone_no
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
end
p hour_map
p dow_map
