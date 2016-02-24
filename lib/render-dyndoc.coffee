exports.eval = (text='', filePath, callback) ->

	decode_cmd = (cmd) ->
	  regexp = /^__send_cmd__\[\[([a-zA-Z0-9_]*)\]\]__([\s\S]*)/m
	  res = cmd.match(regexp)
	  {"cmd": res[1], "content": res[2]}

	end_token = "__[[END_TOKEN]]__"

	#text=text.replace /\#\{/g,"__AROBAS_ATOM__{"

	net = require 'net'
	#util = require 'util'
	host = "127.0.0.1"
	port = "7777"
	console.log("Host:Port="+host+":"+port)

	client = net.connect {port: port, host: host}, () ->
		result=''
		#console.log (util.inspect '__send_cmd__[[dyndoc]]__' + text + end_token)
		client.write '__send_cmd__[[dyndoc]]__' + text + end_token + '\n'

		client.on 'data', (data) ->
			#console.log "data:" + data.toString()
			data2=data.toString().split(end_token)
			last=data2.pop()
			result += data2.join("")
			#console.log("last:<<"+last+">>")
			if last == ""
				#console.log("<<"+result+">>")
				resCmd = decode_cmd(result)
				if resCmd["cmd"] != "windows_platform"
					#console.log("data: "+resCmd["content"])
					callback(null, resCmd["content"])
					client.end()
			else
				result += last

	  	client.on 'error', (err) ->
	    	#console.log('error:', err.message)
	    	callback error,err.message
