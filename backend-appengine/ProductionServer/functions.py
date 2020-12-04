def fib(n):    # write Fibonacci series up to n 
 a, b = 0, 1
 c = ''
 while b < n:
  a, b = b, a+b
  c = c + ' ' + str(b)
 return c


import re
# lexical token symbols
DQUOTED, SQUOTED, UNQUOTED, COMMA, NEWLINE = xrange(5)

_pattern_tuples = (
    (r'"[^"]*"', DQUOTED),
    (r"'[^']*'", SQUOTED),
    (r",", COMMA),
    (r"$", NEWLINE), # matches end of string OR \n just before end of string
    (r"[^,\n]+", UNQUOTED), # order in the above list is important
    )
_matcher = re.compile(
    '(' + ')|('.join([i[0] for i in _pattern_tuples]) + ')',
    ).match
_toktype = [None] + [i[1] for i in _pattern_tuples]
# need dummy at start because re.MatchObject.lastindex counts from 1 

def csv_split(text):
    """Split a csv string into a list of fields.
    Fields may be quoted with " or ' or be unquoted.
    An unquoted string can contain both a " and a ', provided neither is at
    the start of the string.
    A trailing \n will be ignored if present.
    """
    fields = []
    pos = 0
    want_field = True
    while 1:
        m = _matcher(text, pos)
        if not m:
            raise ValueError("Problem at offset %d in %r" % (pos, text))
        ttype = _toktype[m.lastindex]
        if want_field:
            if ttype in (DQUOTED, SQUOTED):
                fields.append(m.group(0)[1:-1])
                want_field = False
            elif ttype == UNQUOTED:
                fields.append(m.group(0))
                want_field = False
            elif ttype == COMMA:
                fields.append("")
            else:
                assert ttype == NEWLINE
                fields.append("")
                break
        else:
            if ttype == COMMA:
                want_field = True
            elif ttype == NEWLINE:
                break
            else:
                print "*** Error dump ***", ttype, repr(m.group(0)), fields
                raise ValueError("Missing comma at offset %d in %r" % (pos, text))
        pos = m.end(0)
    return fields


#----------
# Key Parameters
#----------
def testPhoneDeviceID():
    return '28D402D52B6E05899E8A2B7BB3E2103942629EDD3F2FE0C104760360FDA143CF' 

def secretKey():
    return '43870193'

def secretKey2():
    return '77777777'

def stocksPerLookup():
    return 100

def cacheTime():   #This defines the time to cache the latest stock value (in seconds)
    return 30
#----------
# Email Validation Code (from: http://code.activestate.com/recipes/65215-e-mail-address-validation/)
# 01/07/2011
#----------
def validateEmail(value):
	#logging.info('email Validation')  
	import re
	if len(value) > 5:
		if re.match("^.+\\@(\\[?)[a-zA-Z0-9\\-\\.]+\\.([a-zA-Z]{2,3}|[0-9]{1,3})(\\]?)$", value) != None:
			return 1
	return 0


#----------
# Stock/Value/Currency Validation Code
# 15/10/2011
# This accepts values such as 40.12, 40, 
#----------
def validateStock(value):
	#logging.info('email Validation')  	
	try:
		"{:.2f}".format(float(value))
		return 1
	except ValueError:
		return 0
		

#----------
# Salted Hashing Code 
# This code salts a password for storage in the main db using sha224 encryption
# 01/07/2011
#----------
def saltString():
    return 'VZmMl39CI5D08RV5AWy52VFnBmLgJf2FRQ00joRxRMw7jddbL1WyBYKocBTqU'
	
def getSaltedHash(pw):
    import hashlib
    salt = saltString()
    pw = salt + pw
    pw = hashlib.sha224(pw).hexdigest()      #Resultant Password = sha224(salt+pw) 
    return pw

#----------
# UrbanAirship Keys
# These are the auth keys for access to Urban Airship
# 01/09/2011
# Modified 21/05/2012 to have the productionEnvironment Switch
#----------
def productionEnvironment():
	return '1'
    
def uaApiApplicationKey():
     return 'fT1X2BWKSWuO-_Fi41Gvmw' #Application Key from UrbanAirship -> App Menu -> App Details to Display

def uaApiApplicationKeySecret():
     return 'ARNGiDhGRIqeC42quj4zlg' #Application Master Secret - Stocks+ Development -> from https://go.urbanairship.com/apps/ -> App Menu -> App Details to Display

def uaApiApplicationDevKey():
    return 'MxcROO8LTbKnnQUhzQlKkw' #Application Key from UrbanAirship -> App Menu -> App Details to Display

def uaApiApplicationDevKeySecret():
    return 's1dCQTEwTxiffegZKv3Rug' #Application Master Secret - Stocks+ Development -> from https://go.urbanairship.com/apps/ -> App Menu -> App Details to Display

#----------
# The following function sends a push notification to ItsGoingUp Development Build. Needs Correct Device Token. Works 27/08/2011.
#----------
def sendApplePushNotificationTestProductionKeys(void):
    # via UrbanAirShip
    import logging
    from django.http import HttpRequest
    import urllib
    import base64
    from google.appengine.api import urlfetch
    from django.utils import simplejson
    logging.debug('in sendApplePushNotificationTestProductionKeys')

    UA_API_APPLICATION_KEY = uaApiApplicationKey()  
    UA_API_APPLICATION_PUSH_SECRET = uaApiApplicationKeySecret() 
    url = 'https://go.urbanairship.com/api/push/'
    
    auth_string = 'Basic ' + base64.encodestring('%s:%s' % (UA_API_APPLICATION_KEY,UA_API_APPLICATION_PUSH_SECRET))[:-1]
    
    alertMsg = 'Test from AppEngine - Production Key'
    badgeNumber = ''
    deviceToken = testPhoneDeviceID()
    sound = 'elevatorting.caf'
        
    body = simplejson.dumps(   {"aps": {"badge": badgeNumber, "sound" : sound, "alert": alertMsg}, "device_tokens": [deviceToken]}  )
    data = urlfetch.fetch(url, headers={'content-type': 'application/json','authorization' : auth_string}, payload=body,method=urlfetch.POST)

    logging.info('Push Sent: Status: '+str(data.status_code))
    logging.debug("Push Sent: Body:" + body + " Status: "+str(data.status_code))
#----------
# The following function sends a push notification to ItsGoingUp Development Build. Needs Correct Device Token. Works 27/08/2011.
#----------
def sendApplePushNotificationTestDevelopmentKeys(void):
    # via UrbanAirShip
    import logging
    from django.http import HttpRequest
    import urllib
    import base64
    from google.appengine.api import urlfetch
    from django.utils import simplejson
    logging.debug('in sendApplePushNotificationTestProductionKeys')

    UA_API_APPLICATION_KEY = uaApiApplicationDevKey()  
    UA_API_APPLICATION_PUSH_SECRET = uaApiApplicationDevKeySecret() 
    url = 'https://go.urbanairship.com/api/push/'
    
    auth_string = 'Basic ' + base64.encodestring('%s:%s' % (UA_API_APPLICATION_KEY,UA_API_APPLICATION_PUSH_SECRET))[:-1]
    
    alertMsg = 'Test from AppEngine - Development Key'
    badgeNumber = ''
    deviceToken = testPhoneDeviceID()
    sound = 'elevatorting.caf'
        
    body = simplejson.dumps(   {"aps": {"badge": badgeNumber, "sound" : sound, "alert": alertMsg}, "device_tokens": [deviceToken]}  )
    data = urlfetch.fetch(url, headers={'content-type': 'application/json','authorization' : auth_string}, payload=body,method=urlfetch.POST)

    logging.info('Push Sent: Status: '+str(data.status_code))
    logging.debug("Push Sent: Body:" + body + " Status: "+str(data.status_code))
    
    
def application(environ, start_response):
  request = webob.Request(environ)
  response = webob.Response(request=request, conditional_response=True)
  response.content_type = 'text/plain'
  out = response.body_file
  out.write("Hello, %s!" % (request.GET.get('name', 'world'),))
  return response(environ, start_response)


#----------
# More General PushNotification Code
#----------
def sendApplePushNotification(deviceToken,alertMsg,badgeNumber,sound):
    # via UrbanAirShip
    import logging
    from django.http import HttpRequest
    import urllib
    import base64
    from google.appengine.api import urlfetch
    from django.utils import simplejson
    logging.debug('in sendApplePushNotification')

    UA_API_APPLICATION_KEY = uaApiApplicationKey()  
    UA_API_APPLICATION_PUSH_SECRET = uaApiApplicationKeySecret() 
    url = 'https://go.urbanairship.com/api/push/'
    
    auth_string = 'Basic ' + base64.encodestring('%s:%s' % (UA_API_APPLICATION_KEY,UA_API_APPLICATION_PUSH_SECRET))[:-1]
    
    #alertMsg = 'Test from AppEngine'
    #badgeNumber = ''
    #deviceToken = testPhoneDeviceID()
    sound = 'elevatorting.caf'
    
    body = simplejson.dumps(   {"aps": {"badge": badgeNumber, "sound" : sound, "alert": alertMsg}, "device_tokens": [deviceToken]}  )
    data = urlfetch.fetch(url, headers={'content-type': 'application/json','authorization' : auth_string}, payload=body,method=urlfetch.POST)

    logging.info('Push Sent: Status: '+str(data.status_code))
    logging.debug("Push Sent: Body:" + body + " Status: "+str(data.status_code))
def application(environ, start_response):
  request = webob.Request(environ)
  response = webob.Response(request=request, conditional_response=True)
  response.content_type = 'text/plain'
  out = response.body_file
  out.write("Hello, %s!" % (request.GET.get('name', 'world'),))
  return response(environ, start_response)

#The below function scrapes a stock off yahoo for the cheap :P Cool heh  
#Features:
#       - Random Useragent
#       - Returns -1 if an error, 0.00 if not a real stock, and otherwise the stock value
#Usage:  result = functions.getstock(stock) 

# This version looks up 1 stock at a time (in separate API calls to y!)
#----------
def getstock(stock):
    from google.appengine.api import urlfetch
    import logging
    #---------------  
    #The right URL to use is: http://download.finance.yahoo.com/d/quotes.csv?s=bhp.ax&f=l1
    url = 'http://download.finance.yahoo.com/d/quotes.csv?s=%s&f=l1' % (stock)
    useragents = ['Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)', 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-GB; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6', 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30)', 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.1.4322)', 'Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/533.2 (KHTML, like Gecko) Chrome/8.0']
    from random import choice
    result = urlfetch.fetch(url=url, headers={'Content-Type': 'text/plain','User-Agent': choice(useragents)})
    if result.status_code == 200:   			#Check status is good (HTTP 200)
     resultText = result.content.rstrip() 		#rstrip takes out the delivered linefeed/caridgereturn
     #logging.info('Raw data is:'+resultText)    #log it
    else: 
     resultText = -1							#if error return -1
     logging.error('Connection Error. To:Yahoo! with Status: '+str(result.status_code))    #log it

    return resultText
#-----------------

#----------
# Stock Validation Check (Single Stock) Returns =1 if Validation is ok, =0 if not OK
#----------
def validatestock(stock):
 import logging
 stockValue = getstock(stock)
 if stockValue == '0.00' or stockValue =='-1':
  logging.error('Invalid Stock Added: ' + stock)
  validationcode=0
 else:
  validationcode=1
 return validationcode


#----
#Send Admin Email
#---

def sendAdminEmail(emailtype,body):
 import logging
 from google.appengine.api import mail

 user_address = "admin@norgeapps.com"
 sender_address = "Itsgoingup <admin@itsgoingup.appspotmail.com>"
 emailbody = body

 if emailtype == 'newaccount': 
  subject = "ItsGoingUp Backend: New Administrator Signup"
  mail.send_mail(sender_address, user_address, subject, emailbody)
  logging.info('Sending Mail')
 elif emailtype == 'error': 
  subject = "ItsGoingUp Backend: Error"
  mail.send_mail(sender_address, user_address, subject, emailbody)
  logging.info('Sending Mail')

