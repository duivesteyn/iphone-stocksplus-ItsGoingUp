import os
#from google.appengine.dist import use_library
#use_library('django', '1.2')
import logging
import wsgiref.handlers
from google.appengine.ext import webapp
from google.appengine.ext.webapp import template
from util.sessions import Session
from google.appengine.ext import db
import time
from random import choice
import random  
from django.http import HttpRequest			#for PushNotifications
import urllib								#for PushNotifications
import base64								#for PushNotifications
from google.appengine.api import urlfetch	#for PushNotifications
from django.utils import simplejson			#for PushNotifications
#from webob import Request					#for Getting Web Request Data
from google.appengine.api import memcache

import functions  							#my functions class
debug = 0
economyMode = 1

#URL Scraper Tools	
import urllib2
from google.appengine.api import urlfetch
import datetime

# Database - User Model
class User(db.Model):
  account = db.StringProperty()
  password = db.StringProperty()
  name = db.StringProperty()
  addDate = db.DateTimeProperty()

# Database - Stock Alert Matrix (See Evernote)
class Alert(db.Model):
  userReference = db.StringProperty()
  ticker = db.StringProperty()
  value = db.StringProperty()
  alert = db.StringProperty()
  alertAboveBelow = db.StringProperty()

# Database - User Model
class Device(db.Model):
  userAlias = db.StringProperty()
  deviceToken = db.StringProperty()
  numberOfNotificationsSent = db.IntegerProperty()  
  registerDate = db.DateTimeProperty()
  lastSeenDate = db.DateTimeProperty(auto_now=True)
  deviceType = db.StringProperty() 
  deviceVersion = db.StringProperty()

# Database - Notification Register Database
class Notification(db.Model):
  notificationUniqueID = db.StringProperty()
  notificationUser = db.StringProperty()
  notificationUserAlias = db.StringProperty()
  notificationTicker = db.StringProperty()
  notificationSetPoint = db.StringProperty()
  notificationRepeat = db.StringProperty()  
  notificationActivityDate = db.DateTimeProperty() #This parameter accounts for repeat notifications 
  notificationAboveOrBelow = db.StringProperty()
  notificationSetDate = db.DateTimeProperty()

# Database - Notification Register Database
class NotificationArchive(db.Model):
  notificationUniqueID = db.StringProperty()
  notificationUser = db.StringProperty()
  notificationTicker = db.StringProperty()
  notificationSetPoint = db.StringProperty() 
  notificationActionTime = db.DateTimeProperty() #This parameter accounts for repeat notifications
  notificationAboveOrBelow = db.StringProperty()
  notificationSetDate = db.DateTimeProperty()

# A helper to do the rendering and to add the necessary
# variables for the _base.htm template
def doRender(handler, tname = 'index.htm', values = { }):
  temp = os.path.join(
      os.path.dirname(__file__),
      'templates/' + tname)
  if not os.path.isfile(temp):
    return False

  # Make a copy of the dictionary and add the path and session
  newval = dict(values)
  newval['path'] = handler.request.path
  handler.session = Session()
  if 'username' in handler.session:
     newval['username'] = handler.session['username']

  outstr = template.render(temp, newval)
  handler.response.out.write(outstr)
  return True
  
    
class LoginHandler(webapp.RequestHandler):

  def get(self):
    logging.info('Login Page Rendered')

    #Environment (testing or production)
    ereturn = functions.productionEnvironment()
    if ereturn == '0': environment = "Dev Environment" 
    if ereturn == '1': environment = "Prod Environment" 
    logging.info('ereturn: '+ereturn)
 
    doRender(self, 'loginscreen.htm',{'environment':environment})

  def post(self):
    logging.info('Login Attempt')
    self.session = Session()
    acct = self.request.get('account')
    pw = self.request.get('password')
    #logging.info('Checking account='+acct+' pw='+pw)

    self.session.delete_item('username')      

    if pw == '' or acct == '':
      doRender(
          self,
          'loginscreen.htm',
          {'error' : 'Please specify Email and Password'} )
      return

    logging.info('password: ' + pw)
    
    if pw != '' :					#Salts Password for db check
     pw = functions.getSaltedHash(pw)
    
    logging.info('password: ' + pw)
          
    que = db.Query(User)
    que = que.filter('account =',acct)
    que = que.filter('password = ',pw)

    results = que.fetch(limit=1)

    if len(results) > 0 :
      self.session['username'] = acct
      doRender(self,'index.htm',{ } )
    else:
      doRender(self,'loginscreen.htm',{'error' : 'Incorrect password'} )




class ApplyHandler(webapp.RequestHandler):

  def get(self):
    doRender(self, 'applyscreen.htm')

  def post(self):
    self.session = Session()
    name = self.request.get('name')
    acct = self.request.get('account')
    pw = self.request.get('password')
    code = self.request.get('code')
    #logging.info('Adding account='+acct)

    if code <> functions.secretKey():
      doRender(
          self,
          'applyscreen.htm',
           {'error' : 'Please input correct code'} )
      return
      
    if pw == '' or acct == '' or name == '':
      doRender(
          self,
          'applyscreen.htm',
           {'error' : 'Please fill in all fields'} )
      return

    # Check if the user already exists
    que = db.Query(User).filter('account =',acct)
    results = que.fetch(limit=1)

    emailValid = functions.validateEmail(acct)  #validate email (function from functions.py)
    if emailValid == 0:
      logging.info('email Validation:'  + str(emailValid) )
      doRender(self,'loginscreen.htm',{'error' : 'Please enter a valid email'} )
      return  
     
    if len(results) > 0 :
      doRender(self,'applyscreen.htm',{'error' : 'Account Already Exists'} )
      return
         
    # Create the User object and log the user in
    pw = functions.getSaltedHash(pw)
    logging.info('created password: ' + pw)
    newuser = User(name=name, account=acct, password=pw,addDate=datetime.datetime.now());  
    newuser.put();
    self.session['username'] = acct

    emailbody = "New Account Created on Itsgoingup\nName:" + name + '\nEmail: ' + acct + '\Code: ' + code
    functions.sendAdminEmail('newaccount',emailbody)

    doRender(self,'index.htm',{ })

class MembersHandler(webapp.RequestHandler):
  def get(self):
    self.session = Session()
    que = db.Query(User)
    user_list = que.fetch(limit=500)

	#Environment (testing or production)
    ereturn = functions.productionEnvironment()
    if ereturn == '0': environment = "Dev Environment" 
    if ereturn == '1': environment = "Production Environment" 

    doRender( self, 'memberscreen.htm',  {'user_list': user_list,'environment':environment})

class DevicesHandler(webapp.RequestHandler):
  def get(self):
    self.session = Session()
    que = db.Query(Device)
    device_list = que.fetch(limit=2000)

    deviceCount = db.GqlQuery("SELECT * FROM Device").count()  #get number of Registered Devices
    query = db.GqlQuery("SELECT * FROM Device")     #Total Number of Sent Notifications
    notificationTotalSentCount = 0
    for device in query:
	  notificationTotalSentCount = notificationTotalSentCount + device.numberOfNotificationsSent
	
	#Environment (testing or production)
    ereturn = functions.productionEnvironment()
    if ereturn == '0': environment = "Dev Environment" 
    if ereturn == '1': environment = "Production Environment" 

    doRender(self, 'devices.htm', {'notificationTotalSentCount':notificationTotalSentCount,'deviceCount': deviceCount,'device_list': device_list,'environment':environment})
		
class NotificationsHandler(webapp.RequestHandler):
  def get(self):
    self.session = Session()

	#Environment (testing or production)
    ereturn = functions.productionEnvironment()
    if ereturn == '0': environment = "Dev Environment" 
    if ereturn == '1': environment = "Production Environment" 

    que = db.Query(Notification)
    notification_list = que.fetch(limit=500000)
    doRender(self, 'notifications.htm', {'notification_list': notification_list,'environment':environment})

#NOTE: This class is in response to new pricing in appengine. This class is a hybrid mix of the previous stocks/notification checking model. It uses real time lookups of stocks, then acts on notifications. No stock values are stored. (This cuts down dramatically on datastore writes)	
class NewNotificationEngine(webapp.RequestHandler):
  def get(self):
    self.session = Session()
    que = db.Query(Notification)
    notification_list = que.fetch(limit=500000)
    notificationCount = db.GqlQuery("SELECT * FROM Notification").count()  								#get number of Notifications to Send

    if notificationCount <> 0: 
     logging.info('Hybrid Notification Engine - Starting\n') 
     lookupStartTime = time.time()      																#Start Timer
     li=[]	#empty array

     #Now Prepare stock lookup array (carefully checking memcache for recent lookups)
     for notification in Notification.all(): 												 			#get all stocks in 1 big list from notifications set (all in an array)														
	  tickerToAdd = notification.notificationTicker
	  li.append(tickerToAdd)							
     random.shuffle(li)
	
     #Now Prepare to execute stock price lookups for all stocks
     listsOfStocksToParse = map(None, *(iter(li),) * functions.stocksPerLookup())   					 #[(0, 1, 2), (3, 4, 5), (6, 7, 8), (9, None, None)] (Extract into Lots of 100) 
     actualListOfStocksToParse = []
     for i in range(0, len(listsOfStocksToParse)): 														 
       listOfStocksToParse= listsOfStocksToParse[i]
       stockurlstring=''
       for k in range(0,len(listOfStocksToParse)):
	     if listOfStocksToParse[k] is not None:
	      data = memcache.get(str(listOfStocksToParse[k])) 
	      logging.debug('memcache for stock exists - ' + str(data))
	      
	      if data == None and listOfStocksToParse[k] not in actualListOfStocksToParse: #i.e. memcache doesnt exist for this stock
	       if listOfStocksToParse[k] not in actualListOfStocksToParse:
	        actualListOfStocksToParse.append(listOfStocksToParse[k].strip())
	        if stockurlstring == '': stockurlstring = listOfStocksToParse[k].strip()            	  		#Add to lookup string. URL Forming If/Else statement
	        else: stockurlstring = stockurlstring + "+" + listOfStocksToParse[k].strip()  
	
       logging.debug('stockurlstring: ' + stockurlstring)
       logging.debug('actualListOfStocksToParse' + str(actualListOfStocksToParse))
   
       url = 'http://download.finance.yahoo.com/d/quotes.csv?s=%s&f=l1' % (stockurlstring)
       result = urlfetch.fetch(url=url, headers={'Content-Type': 'text/plain','User-Agent': 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)'}) 		#Useragent was choice(useragents), its now set as constant

       if result.status_code == 200:   																	#Check status is good (HTTP 200)
        resultText = result.content.rstrip() 															#rstrip takes out the delivered linefeed/caridgereturn
        resultText = resultText.split("\n")
       else:
        resultText = -1																					#if error return -1
        logging.error('Connection Down. To:Yahoo! with Status: '+ str(result.status_code) + 'Result was'+str(result))    #log it  
        emailbody = "Error with Status:" + str(result.status_code) + '\nResult: ' + str(result)
        functions.sendAdminEmail('error',emailbody)
        return

       #Run through list again and put them all into memcache
       for k in range(0,len(actualListOfStocksToParse)):														#Run through list again and put them all into memcache
        stock = actualListOfStocksToParse[k]
        if stock <> None: 
	     logging.info('k:' + str(k) + 'stockValue' + str(resultText[k]))  																			#Dont process type None
	     stockValue = resultText[k].split()                      										#splits up list into just number variable   
	     stockValue = stockValue[-1]  	
	     stockValue.split(",")
	     memcache.add(stock, stockValue, functions.cacheTime())											#memcache this sucker (default cachetime was 120s)
	     logging.info('Hybrid Notification Engine - Stock Value Fetch - '+stock +' '+stockValue +"  " + str(k+1) + "/" + str(len(listOfStocksToParse)))   #debug code      	     
	   #Done :) All Stocks are now available in memcache 	     
	     	
       
     notificationStartTime = time.time()  #get time for performance 
     logging.info('Hybrid Notification Engine - Stock Lookup Complete') 
     logging.info('Hybrid Notification Engine: Processing Notifications')  
     for notification in Notification.all():											#get data from Datastore
      logging.info('Hybrid Notification Engine: Reviewing Notification: %s for DeviceToken %s for Stock: %s at setpoint %s looking for %s' % (notification.notificationUniqueID, notification.notificationUser,notification.notificationTicker,notification.notificationSetPoint,notification.notificationAboveOrBelow))
      stock = notification.notificationTicker
      aboveOrBelowCheck = notification.notificationAboveOrBelow

      stockValue = memcache.get(stock)  												#Check Memcache for stock value (saves a trip out to yahoo) #stockValue= functions.getstock(stock)
      if stockValue is None:
       stockValue = functions.getstock(stock)											#This is in case of emergency, (extra added stock for some crazy reason, unlikely to execute)
       memcache.add(stock, stockValue, functions.cacheTime())
       logging.info('Had to manually lookup Stock and add to Memcache for a notification ' + str(stock) + ' ' + str(stockValue))    

      stockValueInFloat = float(stockValue)												#This all needs conversion to floats.
      notificationValueInFloat = float(notification.notificationSetPoint)
      logging.debug('Notification Engine: Stock Price: ' + str(stockValueInFloat))
      logging.debug('Notification Engine: SetPoint: ' + str(notificationValueInFloat))

      notificationsSent = 0

      if (aboveOrBelowCheck == 'A' and stockValueInFloat >= notificationValueInFloat) or (aboveOrBelowCheck == 'B' and stockValueInFloat < notificationValueInFloat): 
       #lDeeper Check - Looking at last repeat too.
       if (aboveOrBelowCheck == 'A') : logging.info('Notification Active: Received Parameters: ' + aboveOrBelowCheck + ' ' + stockValue + ' >= ' + notification.notificationSetPoint)
       if (aboveOrBelowCheck == 'B') : logging.info('Notification Active: Received Parameters: ' + aboveOrBelowCheck + ' ' + stockValue + ' < ' + notification.notificationSetPoint)
       logging.info('Notification Active: Stock ' + str(stock) + ' is ' + stockValue + ' is above target ' + notification.notificationSetPoint +'. Above:' + aboveOrBelowCheck)
       logging.debug('Notification Active: Checking Last Sent Date')
       lastUpdated = notification.notificationActivityDate
       notificationRepeat = notification.notificationRepeat
	   #can be ['No','Hr','D','W']
       if notificationRepeat == 'No': timeRequredToElapse = 0
       if notificationRepeat == 'Hr' : timeRequredToElapse = 60*60 #1hr
       if notificationRepeat == 'D' : timeRequredToElapse = 60*60*24 #1day
       if notificationRepeat == 'W' : timeRequredToElapse = 60*60*24*7 #1week
       logging.debug('Time required to elapse: ' + str(timeRequredToElapse))
       timeDiff = datetime.datetime.now() - lastUpdated #BugFixed Here - was previously notification.notificationSetDate 
       logging.debug('Time elapsed: ' + str(timeDiff.seconds)) #check repeat time against current time.
       if (notification.notificationSetDate == lastUpdated or float(timeDiff.seconds) > timeRequredToElapse) :
        logging.debug('Notification Active: Sending Notification and Updating notificationActivityDate')
        if (aboveOrBelowCheck == 'A') : functions.sendApplePushNotification(notification.notificationUser,'Stock: ' + stock + ' is above your target: ' + notification.notificationSetPoint + '\n'+ stock + ' is currently: ' + stockValue,1,'beep') #sends notification..
        if (aboveOrBelowCheck == 'B') : functions.sendApplePushNotification(notification.notificationUser,'Stock: ' + stock + ' is below your target: ' + notification.notificationSetPoint + '\n'+ stock + ' is currently: ' + stockValue,1,'beep') #sends notification..

        notificationsSent += 1

        #Incrementing Device Total of Notifications
        logging.debug('incrementing notification')
        que = db.Query(Device).filter('deviceToken =',notification.notificationUser)								#Get Existing Device
        entity = que.get()                                 															#Get the Entity
        previousReceived = entity.numberOfNotificationsSent
        entity.numberOfNotificationsSent = previousReceived + 1														#x = x +1
        entity.put();																								#Save

	    #Lookup UserID from DeviceToken   	
        queryListOfUsers = db.GqlQuery("SELECT * FROM Device WHERE deviceToken = :dID", dID=notification.notificationUser)
        userCount = queryListOfUsers.count() 	
        listOfUsers = queryListOfUsers.fetch(userCount)
        if userCount > 0: 
         userAlias = listOfUsers[0].userAlias   # get array object0 (the first one)

        #If Notification Is Set to No Repeat, Add to NotificationArchive and Delete.	
        if notificationRepeat == 'No': 
         logging.debug('archiving notification')
	     #add Notification to NotificationArchive
         entity = NotificationArchive(notificationUniqueID=notification.notificationUniqueID,notificationUser=userAlias,notificationTicker=notification.notificationTicker, notificationSetPoint=notification.notificationSetPoint, notificationActionTime=datetime.datetime.now(), notificationAboveOrBelow=notification.notificationAboveOrBelow,notificationSetDate=notification.notificationSetDate);
         entity.put();																								#Add the Archive Notification
         que = db.Query(Notification).filter('notificationUniqueID =',notification.notificationUniqueID)			#Get Existing Notification 
         entity = que.get()                                 														#Get the Entity
         entity.delete();																							#Delete
        else :
         logging.debug('updating notificationActivityDate')
         que = db.Query(Notification).filter('notificationActivityDate =',notification.notificationActivityDate)	#Get Existing Notification 
         entity = que.get()                                 														#Get the Entity
         entity.notificationActivityDate = datetime.datetime.now()													#Update the Entity ActivityDate
         entity.put();																								#Save

     #End Timer
     engineStopTime = time.time()
     logging.info('Hybrid Notification Engine: Done')
     engineTime = round(float(engineStopTime - lookupStartTime),3)						#Engine Time - Full Time
     notificationSendingTime = round(float(engineStopTime - notificationStartTime),3)	#notificationSendingTime - Time taken sending Notifications
     stockLookupTime = round(float(notificationStartTime - lookupStartTime),3)			#stockLookupTime		 - Time taken to lookup stocks
     engineRate = round(float(notificationCount/float(engineTime)),3)
     logging.info('Hybrid Notification Engine: ' + str(notificationCount) + ' Notifications checked in '+ str(engineTime)+' sec, ' + str(notificationsSent) + ' Notification Sent with speed: '+str(engineRate)+' Notifications/sec')


    doRender(self, 'notifications.htm', {'msg' : 'Notification Engine Executed', 'notification_list': notification_list})

class StatsHandler(webapp.RequestHandler):
  def get(self):
    self.session = Session()
    logging.info('In StatsHandler')

    #Stock Stats
    #TBA
    stockCount = ''

    #Environment (testing or production)
    ereturn = functions.productionEnvironment()
    if ereturn == '0':
     environment = "Dev Environment" 
    if ereturn == '1':
     environment = "Prod Environment" 
    logging.info('ereturn: '+ereturn)
 
    #Notification Stats
    query = db.GqlQuery("SELECT * FROM Notification")
    notificationCount = query.count()

    #Total Number of Sent Notifications
    query = db.GqlQuery("SELECT * FROM Device")
    notificationTotalSentCount = 0
    for device in query:
	 notificationTotalSentCount = notificationTotalSentCount + device.numberOfNotificationsSent
	 logging.debug(str(notificationTotalSentCount))

    #Device Stats
    query = db.GqlQuery("SELECT * FROM Device")
    deviceCount = query.count()

    doRender(self, 'stats.htm', {'environment': environment,'stockCount':stockCount,'notification_count': notificationCount, 'notification_totalcount':notificationTotalSentCount,'device_count': deviceCount })
	
class NotifyDevPhone(webapp.RequestHandler):
  def get(self):
    self.session = Session()
    que = db.Query(Notification)
    notification_list = que.fetch(limit=500)
    #functions.sendApplePushNotificationTest('test') #old boring code
    functions.sendApplePushNotification(functions.testPhoneDeviceID(),'Test Sent from itsgoingup server (/notifications)','','submarine.caf') 
    doRender(self,'notifications.htm',{'msg' : 'Notification Sent - Check Development Phone','notification_list': notification_list})
	
class RegisterDevice(webapp.RequestHandler):
  def get(self):
    logging.debug('in Register Device (GET)')
    doRender(self,'index.htm',
    {'msg' : 'Called RegisterDevice-GET'})

  def post(self):
    newToken = self.request.get('deviceToken').upper()
    deviceType = self.request.get('deviceType')										#Get device type from POST data (09 June 2012 added) 
    deviceVersion = self.request.get('deviceVersion')	
    logging.debug('in Register Device (POST)')
    logging.info('Devices: Requested Adding Device: ' + newToken + ' of type: ' + deviceType)

    if len(newToken) <> 64 :														#Check if Token Length <>64char
      logging.error('Devices: Incorrect Device Token: ' + newToken + ' / ' + deviceType)		#If <>64char, Log Error
      doRender(self,'index.htm',{ 'msg' : 'Incorrect Device Token'} ) 				#Render Error
      return
	
    # Check if the ID already exists
    que = db.Query(Device).filter('deviceToken =',newToken)
    results = que.fetch(limit=1)

    if len(results) > 0 :
      logging.info('Devices: Previously Registered Device Spotted: ' + newToken)	#log: Existing Device Spotted
      que = db.Query(Device).filter('deviceToken =',newToken)						#Get Existing User 
      entity = que.get()                                 							#Get the Entity
      entity.lastSeenDate = datetime.datetime.now()									#Update Last Seen Time 
      entity.deviceVersion = deviceVersion											#Add/Update the Device Version (09 June 2012 added)
      entity.deviceType = deviceType											  	#Add/Update the Device Version (10 June 2012 added)
      entity.put();																	#Update Database Item
      doRender(self, 'devices.htm', { 'msg' : 'Device Already Registered'} )
      return

    # Set User Alias 'User1, User2, User3'
    deviceCount = db.GqlQuery("SELECT * FROM Device").count()  #get number of Registered Devices
    userName = 'User' + str(deviceCount+1)

    newNotificationCount = 0
    newDevice = Device(userAlias=userName, deviceToken=newToken, deviceType=deviceType, deviceVersion=deviceVersion, lastSeenDate='', numberOfNotificationsSent=newNotificationCount, registerDate=datetime.datetime.now());  
    newDevice.put();
    doRender(self,'index.htm',
    {'msg' : 'Devices: Registered New Device with DeviceToken: '+newToken})

class SetNotification(webapp.RequestHandler):
	
  def post(self):
    token = self.request.get('deviceToken').upper()
    ticker = self.request.get('ticker').upper()
    setPoint = self.request.get('setPoint')
    aboveOrBelow = self.request.get('aboveOrBelow')
    repeat = self.request.get('repeat')
    notificationUniqueID = self.request.get('notificationID')
    deleteNotification = self.request.get('delete')
    userAlias = 'n/a'

    logging.debug('in SetNotification POST') 

    #Delete Notification If Reqested
    if (deleteNotification == '1') :
     query = db.Query(Notification).filter('notificationUser =',token).filter('notificationUniqueID =',notificationUniqueID) 	#Check to see if the Notification Already Exists
     results = query.fetch(limit=1) 	
     if len(results) > 0 : 
      entity = query.get()                                 																		#Get the Entity											
      entity.delete();	
      logging.info('Deleting Notification: ' + notificationUniqueID + ' / ' + token)
     doRender(self,'index.htm',{'msg' : 'Notification Deleted'})   #Return
     return
 
	#Lookup UserID from DeviceToken   	
    queryListOfUsers = db.GqlQuery("SELECT * FROM Device WHERE deviceToken = :dID", dID=token)
    userCount = queryListOfUsers.count() 	
    listOfUsers = queryListOfUsers.fetch(userCount)
    if userCount > 0: 
     userAlias = listOfUsers[0].userAlias   # get array object0 (the first on)
     logging.debug('UserAlias/count data: ' + str(userAlias))
    
    logging.info('Received Notification Set from: user:' + userAlias + ' token: '+ token + ' ticker: ' + ticker + ' setPoint: ' + setPoint + ' aboveOrBelow: ' + aboveOrBelow + ' repeat: ' + repeat + ' uniqueID: ' + notificationUniqueID)

    #Validation on Ticker - #PERFORMANCE PROBLEMS - Enable/Disable THIS - Econ
    if economyMode == 0: 
     if functions.validatestock(ticker) != 1:				
      logging.info('Set Notification: Incorrect Parameters Received: Ticker:' + ticker) #Validates ticker
      doRender(self,'index.htm',{'msg' : 'Incorrect Parameters Received'})   #Return
      return	
		
    #Internal Validation (Check against abuse)
    #maybe todo; validate against SetPoint. currently will accept bad setpoints. This needs to be internally verified in app.
    if (len(token) <> 64 or len(notificationUniqueID) <> 12 or len(ticker) == 0  or len(setPoint) == 0  or (repeat not in ['No','Hr','D','W']) or (aboveOrBelow not in ['A','B']) ): 
     logging.info('Set Notification: Incorrect Parameters Received: ' + userAlias + ' / ' +  token +' / ' + ticker + ' / ' + setPoint + ' / ' + aboveOrBelow+ ' / ' + repeat) #Validates all inputs against what they should be
     doRender(self,'index.htm',{'msg' : 'Incorrect Parameters Received'})   #Return
     return

    #Check to see if the Notification Already Exists with same setpoint
    setPoint = "%.3f" % float(setPoint)
    que = db.Query(Notification).filter('notificationUser =',token).filter('notificationUniqueID =',notificationUniqueID).filter('notificationTicker =',ticker).filter('notificationSetPoint =',setPoint).filter('notificationAboveOrBelow =',aboveOrBelow).filter('notificationRepeat =',repeat) 	#Check to see if the Notification Already Exists
    results = que.fetch(limit=1) 	
    if len(results) > 0 : 
     logging.info('Set Notification: Previously Registered Notification Received: ' + notificationUniqueID + ' / ' + token +' / ' + ticker + ' / ' + setPoint + ' / ' + aboveOrBelow) #Already Exists
     doRender(self,'index.htm',{'msg' : 'Notification Already Exists'})   #Return
     return

    #Check to see if notification was updated, if so, update in Notification table
    query = db.Query(Notification).filter('notificationUser =',token).filter('notificationUniqueID =',notificationUniqueID) 	#Check to see if the Notification Already Exists
    results = query.fetch(limit=1) 	
    if len(results) > 0 : 
     entity = query.get()                                 														#Get the Entity
     entity.notificationSetPoint = setPoint
     entity.notificationTicker = ticker
     entity.notificationAboveOrBelow = aboveOrBelow	
     entity.notificationRepeat = repeat												
     entity.put();	
     logging.info('Set Notification: Updating a Previously Registered Notification: ' + notificationUniqueID + ' / ' + token +' / ' + ticker + ' / ' + setPoint + ' / ' + aboveOrBelow) #Already Exists
     doRender(self,'index.htm',{'msg' : 'Notification Updated'})   #Return
     return

    #Finally add it to the DB if there is nothing wrong with it. 
    currentTime = datetime.datetime.now()
    setPoint = "%.3f" % float(setPoint)
    newNotification = Notification(notificationUserAlias=userAlias, notificationUniqueID=notificationUniqueID, notificationUser=token, notificationTicker=ticker, notificationSetPoint=setPoint, notificationAboveOrBelow=aboveOrBelow, notificationRepeat=repeat, notificationSetDate=currentTime, notificationActivityDate=currentTime);  
    newNotification.put();
    doRender(self,'index.htm',{'msg' : 'Notification Set'})

class LogoutHandler(webapp.RequestHandler):

  def get(self):
    self.session = Session()
    self.session.delete_item('username')
    doRender(self, 'index.htm')

class DataEngine(webapp.RequestHandler):
  #def get(self):
  def post(self):
    logging.debug('DataEngine - Requested')
    code = self.request.get('passphrase')
    
    if code == functions.secretKey() or code == functions.secretKey2() :
     deviceCount = db.GqlQuery("SELECT * FROM Device").count()  #get number of Registered Devices
     logging.info('Data: Number of Devices Registered: ' + str(deviceCount))

     stockCount = 0  #get number of Stocks # this is depreciated now, not relevant to code.
     logging.info('Data: Number of Stocks Registered: ' + str(stockCount))

     notificationCount = db.GqlQuery("SELECT * FROM Notification").count()  #get number of SetNotifications
     logging.info('Data: Number of Notification Set Points Registered: ' + str(notificationCount))

     query = db.GqlQuery("SELECT * FROM Device")   #Total Number of Sent Notifications
     notificationTotalSentCount = 0
     for device in query:
	  notificationTotalSentCount = notificationTotalSentCount + device.numberOfNotificationsSent

    #Output:    f#Stocks #Devices #NotificationsSet #NotificationsSent
     self.response.out.write(str('notused') + ' ' + str(deviceCount) + ' ' + str(notificationCount) + ' ' + str(notificationTotalSentCount))

class MainHandler(webapp.RequestHandler):

  def get(self):
	
	 #Environment (testing or production)
    ereturn = functions.productionEnvironment()
    if ereturn == '0': environment = "Dev Environment" 
    if ereturn == '1': environment = "Production Environment" 
    logging.info("-------")
    logging.info("Starting Engine")
    logging.info("Environment: "+ environment)
    logging.info("-------")

    if doRender(self,self.request.path) :
      return
    doRender(self,'index.htm',{'environment':environment})

def main():
  application = webapp.WSGIApplication([
     ('/login', LoginHandler),
     ('/apply', ApplyHandler),
     ('/members', MembersHandler),
     ('/devices', DevicesHandler),
     ('/notifications', NotificationsHandler),
     ('/stats', StatsHandler),
     ('/tasks/notificationSender',NewNotificationEngine),
     ('/notify/devPhone',NotifyDevPhone),
     ('/receive/registerdevice',RegisterDevice),
     ('/receive/setnotification',SetNotification),
     ('/receive/serverstatistics',DataEngine),
     ('/logout', LogoutHandler),
     ('/.*', MainHandler)],
     debug=True)
  wsgiref.handlers.CGIHandler().run(application)

if __name__ == '__main__':
  main()