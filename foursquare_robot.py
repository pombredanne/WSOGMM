#!/usr/bin/env python

# foursquare_robot.py
# Murtaza Gulamali (14/02/2012)
#
# Login and access the Foursquare API.  Uses the mechanize module to log in to
# Foursquare and make the client API calls.  Will probably break when Foursquare
# change their login and client authorisation pages. :P
#
# Requirements:
# + A Foursquare developer account, together with Client ID, Client Secret etc.
#   (see https://foursquare.com/oauth/)
# + A live website for login redirection (the redirect URL). This doesn't have
#   to contain any content since the GET URL itself is used.
# + mLewisLogic's Python Foursquare module.
#   (see https://github.com/mLewisLogic/foursquare)

import sys
import re
import mechanize
import cookielib
import foursquare
import requests
import time
import urllib

# personal client attributes
CLIENT_ID     = 'YOUR_CLIENT_ID'
CLIENT_SECRET = 'YOUR_CLIENT_SECRET
REDIRECT_URL  = 'YOUR_REDIRECT_URL'
VERSION       = '20120214'
USERNAME      = 'YOUR_FOURSQUARE_USERNAME'
PASSWORD      = 'YOUR_FOURSQUARE_PASSWORD'

# browser attributes
USER_AGENT    = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.63 Safari/535.7'
REFERER       = REDIRECT_URL

def get_timeseries(oauth_token, venue_id, start_date, end_date=None):
    api_endpoint = 'https://api.foursquare.com/v2/venues/timeseries'
    params = {'venueId': venue_id,
              'startAt': ('%d' % start_date),
              'endAt':  ('%d' % end_date) if end_date else ('%d' % time.time()),
              'oauth_token': oauth_token}
    url = '%s?%s' % (api_endpoint, urllib.urlencode(params))    
    response = requests.get(url, headers={'User-Agent': USER_AGENT, 'Referer': REFERER})
    return response.content
    
def get_stats(oauth_token, venue_id, start_date, end_date=None):
    api_endpoint = 'https://api.foursquare.com/v2/venues'
    params = {'startAt': ('%d' % start_date),
              'endAt':  ('%d' % end_date) if end_date else ('%d' % time.time()),
              'oauth_token': oauth_token}
    url = '%s/%s/stats?%s' % (api_endpoint, venue_id, urllib.urlencode(params))    
    response = requests.get(url, headers={'User-Agent': USER_AGENT, 'Referer': REFERER})
    return response.content
    
# create a browser
br = mechanize.Browser()

# Cookie Jar
cj = cookielib.LWPCookieJar()
br.set_cookiejar(cj)

# Browser options
br.set_handle_equiv(True)
br.set_handle_redirect(True)
br.set_handle_referer(True)
br.set_handle_robots(False)

# Follows refresh 0 but not hangs on refresh > 0
br.set_handle_refresh(mechanize._http.HTTPRefreshProcessor(), max_time=1)

# User-Agent (this is cheating, ok?)
br.addheaders = [('User-agent', USER_AGENT)]

# login to Foursquare
br.open('https://foursquare.com/login')
br.select_form(nr=2)
br.form.controls[1].value = USERNAME
br.form.controls[2].value = PASSWORD
br.submit()

# create Foursquare client
fs = foursquare.Foursquare(client_id=CLIENT_ID, client_secret=CLIENT_SECRET, redirect_uri=REDIRECT_URL)

# authenticate app and get access token
br.open(fs.oauth.auth_url())
if (br.geturl()[:len(REDIRECT_URL)]!=REDIRECT_URL):
    br.select_form(nr=2)
    br.submit(name=br.form.controls[1].name)
access_token = fs.oauth.get_token(br.geturl()[-48:])
fs.set_access_token(access_token)

# now search for venues within London (M25 region)
sw_lat, sw_lng = 51.29627609493991, -0.4833984375
ne_lat, ne_lng = 51.65551888331029, 0.21697998046875
params = {'sw': '%.5f,%.5f' % (sw_lat,sw_lng),
          'ne': '%.5f,%.5f' % (ne_lat,ne_lng),
          'intent': 'browse'}
data = fs.venues.search(params=params)

# loop over venues and print names and check-ins
for venue in data['venues']:
    print '%s [%d]' % (venue['name'],int(venue['stats']['checkinsCount']))
