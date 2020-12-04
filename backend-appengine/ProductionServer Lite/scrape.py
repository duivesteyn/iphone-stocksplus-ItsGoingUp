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

from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app
import urllib2
from google.appengine.api import urlfetch


class MainPage(webapp.RequestHandler):
    def get(self):
        #self.response.headers['Content-Type'] = 'text/plain'
        #self.response.out.write('Hello, webapp World!')

		symbol = 'bhp.ax'

		#The right URL to use is: http://download.finance.yahoo.com/d/quotes.csv?s=bhp.ax&f=l1
		url = 'http://download.finance.yahoo.com/d/quotes.csv?s=%s&f=l1' % (symbol) 

		#get the data
		#---------------
		#result = urlfetch.fetch(url=url, headers={'Content-Type': 'application/x-www-form-urlencoded'})    #This first line is the basic lookup
		#result = urlfetch.fetch(url=url, headers={'Content-Type': 'text/plain','User-Agent': "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)"}) 		#This second line is a lookup with a useragent
		#----------------
		#The below lookup uses a randomised useragent!
		useragents = ['Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)', 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-GB; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6', 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30)', 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.1.4322)', 'Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/533.2 (KHTML, like Gecko) Chrome/8.0']
		from random import choice
		result = urlfetch.fetch(url=url, headers={'Content-Type': 'text/plain','User-Agent': choice(useragents)})
	


		if result.status_code == 200:
		 resultFinal = result.content
		 self.response.out.write('%s %s' % (symbol,resultFinal) )
		 self.response.out.write('Useragent: %s' % (choice(useragents)) )

application = webapp.WSGIApplication(
                                     [('/', MainPage)],
                                     debug=True)

def main():
    run_wsgi_app(application)

if __name__ == "__main__":
    main()

