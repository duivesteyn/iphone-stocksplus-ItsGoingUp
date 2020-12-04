class Scraper(webapp.RequestHandler):

  def get(self):
    que = db.Query(Stock)
    user_list = que.fetch(limit=1000)
    doRender(self, 'scraper.htm', {'stock_list': user_list })
             

  def post(self):
    import functions
    #logging.info('Scraper - POST') 
    self.session = Session()
    
    stock = self.request.get('stock').upper() #get entered stock
    logging.info('Adding/Looking up Stock: '+stock)  #send to logging console
    result = functions.getstock(stock) #This is my stocklookup function call. from functions.py

	#First lookup db to see if it already exists, to check whether to update or add new
    que = db.Query(Stock).filter('ticker =',stock)
    
    if result == ('0.00'):
      logging.info('Stock That doesnt exist listed: '+stock+':'+result)
      msg = 'Stock That doesnt exist listed:'
      
    elif result == ('-1'):
      logging.error('Connection to Yahoo down: '+stock)
      msg = 'Connection to Yahoo down:'   
      
    else :
     #This next part checks to see if the item should be updated or added
      entity = que.get()
      if entity:
       msg = 'Entity Already Exists - Updating Value' 
       logging.info('Updated Stock  : '+stock+' - '+result)
       entity.value = result
      
      else :
       msg = 'Added New Entity'
       logging.info('Added Stock: '+stock)
       #If the download is good, update the item in the database (adding if it doesnt exist)
       entity = Stock(ticker=stock, value=result, lookupdate='', addeddate=datetime.datetime.now(),addeduser=self.session['username']);
      entity.put();
    

    #reload the page
    que = db.Query(Stock)
    list = que.fetch(limit=1000)
    doRender(self, 'scraper.htm', {'stock_list': list, 'stock' : stock, 'stockvalue' : result, 'msg': msg })

class StocksHandler(webapp.RequestHandler):

  def get(self):
    logging.debug('StocksHandler - GET')
    self.session = Session()
    que = db.Query(Stock)
    stock_list = que.fetch(limit=500)
    doRender(self, 'stocks.htm', {'stock_list': stock_list })
    
  def post(self):
    logging.debug('StocksHandler - POST') 
    self.session = Session()
    stock = self.request.get('stock').upper() 	#Get POST data, stock name, and make upper case
    stock = stock.strip()						#Strip Whitespace
	#lookup db
    que = db.Query(Stock)
    stock_list = que.fetch(limit=10000)

    # Add Stock to DB
    if stock == '':
      doRender(self,'stocks.htm',{'stock_list': stock_list, 'msg' : 'Please specify a Stock'} )
      return

    # Check if the stock already exists
    que = db.Query(Stock).filter('ticker =',stock)
    results = que.fetch(limit=1)

    if len(results) > 0 :
      doRender(self,'stocks.htm', {'stock_list': stock_list, 'msg' : 'Stock Already Exists'} )
      return

    #Validate Stock
    if functions.validatestock(stock) != 1:
     doRender(self,'stocks.htm', {'stock_list': stock_list, 'msg' : 'Stock ' + stock + ' Not Validating)' } )
     return

    newstock = Stock(ticker=stock, value='', lookupdate='', addeddate=datetime.datetime.now(),addeduser=self.session['username']);
    newstock.put();
    ####

	#update list
    que = db.Query(Stock)
    stock_list = que.fetch(limit=10000)
	#display message
	
    msg = 'Just Added %s' % (stock)
    doRender(self, 'stocks.htm', {'stock_list': stock_list, 'msg': msg} )
	#------------





