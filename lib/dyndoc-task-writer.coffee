path = require 'path'
fs = require 'fs'

module.exports =

  task_type: (code) ->
    re = /(?:\:cmd\s*\=\>|cmd\:)\s*\"([^\s,]*)\"\s*\,/
    res = re.exec code
    return if res then res[1].replace /\ /,"" else null

  write_task: (filename, mode) ->
    ext = path.extname filename
    dir = path.dirname filename
    base = path.basename filename,ext
    user_home = process.env[if process.platform == "win32" then "USERPROFILE" else "HOME"]
    default_file = path.join(user_home,".dyntask","share")
    default_file = path.join(default_file,"tasks","task_" + mode + ".rb")
    content = fs.readFileSync(default_file).toString('utf-8')
    #console.log "content:"+content
    task = @task_type(content)
    if task
      task_filename = path.join(dir,base+".task_"+task)
      content = content.replace /\%basename\%/g,"%"+base
      fs.writeFileSync task_filename, content
