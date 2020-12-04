#!/usr/bin/env python
#
# Copyright 2007 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#from google.appengine.ext import webapp
#from google.appengine.ext.webapp import util


#
# Sample code for using the GoogleAppEngine (Python) with UrbanAirship to send
# out iPhone (OS3.0) Push Notifications.
#
# @killingmichael 
# http://twitter.com/killingmichael
#
# Based on code by:  http://twitter.com/bryanbartow
#  
#
import logging
from django.http import HttpRequest
import urllib
import base64
from google.appengine.api import urlfetch
from django.utils import simplejson

print 'code executing'

def sendApplePushNotification(name):
    # via UrbanAirShip
    logging.info("sending notification... "+name)
    
    UA_API_APPLICATION_KEY = 'nzWh9KkERwixNIbMCBGnxA'  #Application Key from UrbanAirship -> App Menu -> App Details to Display
    UA_API_APPLICATION_PUSH_SECRET = '2q9M66NiROagoDmYHLvG4A'  #Application Secret from UrbanAirship -> App Menu -> App Details to Dispaly.
    url = 'https://go.urbanairship.com/api/push/'
    
    auth_string = 'Basic ' + base64.encodestring('%s:%s' % (UA_API_APPLICATION_KEY,UA_API_APPLICATION_PUSH_SECRET))[:-1]
    
    alertMsg = 'Hello from ' + name
    badgeNumber = 3
    deviceToken = '1AC16EA496F514E935E93DAAC049A464EF041705D30A4D809338786CB2BE1814'
    
    body = simplejson.dumps(   {"aps": {"badge": badgeNumber, "alert": alertMsg}, "device_tokens": [deviceToken]}  )
    data = urlfetch.fetch(url, headers={'content-type': 'application/json','authorization' : auth_string}, payload=body,method=urlfetch.POST)

    print data.status_code
    print body
    print data
    logging.info("Push Executed: "+str(data.status_code))

    if data.status_code == 200:
        logging.info("Remote Notification successfully sent to UrbanAirship "+str(data.status_code))
        print 'notification sent'	
    elif data.status_code == 400:
        logging.error("Remote Notification not sent! Do something smart now or not :) "+str(data.status_code))
        print 'notification not sent'

sendApplePushNotification('Ben')
print 'code executed'