#!/usr/bin/ruby

# get_USNO_times.rb
# Murtaza Gulamali (11/10/2011)
#
# Get sunrise/sunset times for random locations and random dates from the
# USNO website, and write them to a file in CSV format.  Timezone information
# is obtained from AskGeo.

require 'date'
require 'rubygems'
require 'mechanize'
require 'tzinfo'
require 'json'
require 'net/http'

# repeat this many times
n = 10

# output filename
filename = 'random_data.csv'

def get_random_date
	# return random date between 01/01/1700 and 31/12/2100
	ajd = rand(2488433-2341972)+2341972.5
	return Date.new!(ajd)
end

def get_random_location
    # return random location between lat = ±82 degrees and lon = ±180 degrees
	lat = rand()*164.0-82.0
	lon = rand()*360.0-180.0
	return {
		'lat' => lat,
		'lon' => lon
	}
end

def get_timezones(dates,lats,lons)
    # return list of timezones for specified list of dates and corresponding locations
	max_pts = 4
	timezones = []
	base_url = "http://www.askgeo.com/api"
	account_id = 'YOUR_ACCOUNT_ID'
	api_key = 'YOUR_API_KEY'
	url = "#{base_url}/#{account_id}/#{api_key}/timezone.json?points="
	(0..(dates.length/max_pts)).each { |i| # iterate over groups of points
		pts = [];
		((i*max_pts)..[(i+1)*max_pts-1,dates.length-1].min).each { |j| # iterate over points
			pts.push("#{lats[j]},#{lons[j]}")
		}
		# make request to AskGeo
		resp = Net::HTTP.get_response(URI.parse(url+pts.join(';')))
		result = JSON.parse(resp.body)
		if result.has_key?('Error')
			raise "web service error"
		end
		# parse response to obtain time zone information
		(0...(result['data'].length)).each { |j|
			timezones.push({
				'desc' => result['data'][j]['timeZone'],
				'offset' => result['data'][j]['currentOffsetMs']/3600000.0
			})
		}
	}
	# get offset for specified dates (just in case DST is required)
	(0...(dates.length)).each { |i|
			tz = TZInfo::Timezone.get(timezones[i]['desc'])
			timezones[i]['offset'] = tz.period_for_local(DateTime.new!(dates[i].ajd)).utc_total_offset/3600.0
	}
	# return result
	return timezones
end

def get_formfields(date,lat,lon,offset)
    # return dictionary of form fields given specified parameters
	return {
		'FFX' => '2',
		'ID' => 'AA',
		'xxy' => date.year.to_s,
		'xxm' => date.month.to_s,
		'xxd' => date.day.to_s,
		'place' => '(blank)',
		'xx0' => ((lon<0) ? ('-1') : ('1')),
		'xx1' => (lon.abs).floor,
		'xx2' => ((lon.abs - (lon.abs).floor)*60.0).floor,
		'yy0' => ((lat<0) ? ('-1') : ('1')),
		'yy1' => (lat.abs).floor,
		'yy2' => ((lat.abs - (lat.abs).floor)*60.0).floor,
		'zz0' => ((offset<0) ? ('-1') : ('1')),
		'zz1' => offset.abs,
		'ZZZ' => 'END'
	}
end

# --------------------------------- MAIN BLOCK ---------------------------------

# create arrays of random dates and locations
dates = []
lats = []
lons = []
(1..n).each {
	dates.push(get_random_date)
	loc = get_random_location
	lats.push(loc['lat'])
	lons.push(loc['lon'])
}

# determine timezone for each date and location
tzs = get_timezones(dates,lats,lons)

# open new CSV file
of = File.new(filename,'w')
of.write("Year,Month,Day,Lat,Lon,Timezone,Offset,Begin civil twilight,Sunrise,Sun transit,Sunset,End civil twilight\n")
(0...n).each { |i| # loop over number of dates and locations
	fields = get_formfields(dates[i],lats[i],lons[i],tzs[i]['offset'])
	of.write("#{dates[i].year},#{dates[i].month},#{dates[i].day},#{lats[i]},#{lons[i]},#{tzs[i]['desc']},#{tzs[i]['offset']},")
	# setup Mechanize 
	agent = Mechanize.new { |a| a.user_agent_alias = 'Mac Safari' }
	# submit form
	page = agent.post('http://aa.usno.navy.mil/cgi-bin/aa_pap.pl',fields)
    # find everything within the <PRE> tags
	lines = page.search('pre').children.inner_text.split("\n")
	lines.each { |line| # loop over lines
		if (line.index('Begin civil twilight') or 
				line.index('Sunrise') or
				line.index('Sun transit') or
				line.index('Sunset') or
				line.index('End civil twilight'))
			if !(line.index('End civil twilight'))
				separator = ','
			else
				separator = ''
			end
            # write times to file
			of.write(line.split(" ").last+separator)
		end
	}
	of.write("\n")
}
