root = global ? window

class taskList extends Backbone.View
	initialize: ->
		@model = {}
		@render()
	render: =>
		template = ""

		template = template + """
			<ul>
		"""
		for i,k of @model
			template = template + """
			<li id = #{i}> 
				<input onchange="socket.emit('setCompleted',#{i},$('##{i} input[type=checkbox]').prop('checked')) "  #{ if k.comp then 'checked' else ' '} type="checkbox" name="vehicle" value="completed">
				<button onclick="socket.emit('deleteTask',#{i})">*</button>
				#{k.name}

			</li>
			"""
		template = template + """
			</ul>
			<input id="taskInput" type="text"></input>
				<button onclick="
					if($('#taskInput').val().length > 0 ) {
					socket.emit('addTask',$('#taskInput').val());
					$('#taskInput').val('');					
					}
				">Add Task</button>
				<button onclick="reccomend()">Find out what i'll probably end up doing next</button>
		"""
		$(@el).html(template)

$ ->
	root.socket = io.connect()
	socket.on "updateList", (payload) ->
		root.list.model = payload
		root.list.render()
	
	root.list = new taskList el:"#list"
	socket.emit "updateList"

	root.reccomend = ->
		getProcrastinateItem  = (list) ->
			a = (i for k,i of list) # copy list
			c = Math.pow(2,a.length)-1  # get the total number of possibilites
			cy = c+1 # required to work out possibility ranges
			# produce possibility ranges as an array - results are stored in t
			t = [] 
			for i in [a.length..1]
				cy = (cy)/2 
				t.unshift cy
			sed = Math.floor(Math.random()*c)+1  # lets choose our random numb!
			numb = i for i,k of t when sed >= k # finds the ordinal of the item based on range that the random number fits in
			return a[numb]
		
		x = getProcrastinateItem(root.list.model)
		if x?
			alert "You most likley will #{x.name} next "
		else
			alert "The first thing you should do is add a task!"
