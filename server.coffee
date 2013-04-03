express = require('express')
http = require('http')
connect = require('express/node_modules/connect')
sio = require('socket.io')
cookie = require('cookie')

app = express()
server = http.createServer(app)
parseSignedCookie = connect.utils.parseSignedCookie
MemoryStore = connect.middleware.session.MemoryStore

root.store = {}
root.accounts = {}

root.routes =
	getPage: (req,res) ->
		if root.store[req.csess].user?
			res.render 'page' , cookie: req.csess
		else	
			res.render 'login' , cookie: req.csess , acc:"Please Enter a User Name And Password"
	postPage: (req,res)  ->
		if req.body.name[0]? and req.body.pass[0]?
			if req.body.action == "Login"
				if root.accounts[req.body.name]? and root.accounts[req.body.name].pass == req.body.pass
					root.store[req.csess].user = req.body.name
					res.render 'inter'
				else 
					res.render 'login' , cookie: req.csess , acc:"User Name And Password Do Not Match"
			else
				if root.accounts[req.body.name]?
					res.render 'login' , cookie: req.csess , acc:"Account Already Exists"
				else
					root.accounts[req.body.name] = {list:{},pass:req.body.pass}
					root.store[req.csess].user = req.body.name
					res.render 'inter'
		else
			res.render 'login' , cookie: req.csess , acc:"Please Enter a User Name And Password"


app.configure ->
	app.set 'views', "#{__dirname}/views"
	app.set 'view engine', 'jade'

	app.use express.bodyParser()
	app.use express.cookieParser()
	app.use express.session secret:'secret',key:'express.sid',store: new MemoryStore()

	app.use (req,res,next) ->
		req.ckeys = cookie.parse(req.headers.cookie)
		req.csess = parseSignedCookie(req.ckeys['express.sid'],'secret')
		root.store[req.csess] = {} unless root.store[req.csess]?

		next()

	app.get "/", routes.getPage
	app.post "/", routes.postPage
	app.use "/" ,express.static(__dirname + '/public/')

	app.use app.router

io = sio.listen(server)

io.set 'authorization', (data,accept) ->
	unless data.headers.cookie
		return accept 'No Cookies','false'
	data.cookie = cookie.parse(data.headers.cookie)	
	data.sessionID = parseSignedCookie(data.cookie['express.sid'],'secret')
	return accept 'Error', false unless root.store[data.sessionID]?
	return accept null,true
		

io.sockets.on 'connection' , (socket, payload) ->
	session = socket.handshake.sessionID
	user = root.store[session].user
	list = root.accounts[user].list

	socket.on "addTask" , (name) ->
		list[new Date().getTime()] = {name:name,comp:false}
		socket.emit "updateList", list
	socket.on "setCompleted" , (task,comp) ->
		
		list[task].comp = comp
		socket.emit "updateList", list
	socket.on "deleteTask" , (task) ->
		delete list[task]
		socket.emit "updateList", list
	socket.on "updateList" , ->
		socket.emit "updateList", list
					

	socket.log.info 'Socket', session, 'connected'

server.listen 3000