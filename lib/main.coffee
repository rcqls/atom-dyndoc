url = require 'url'
path = require 'path'
fs = require 'fs'

dyndoc_viewer = null
DyndocViewer = require './dyndoc-viewer' #null # Defer until used
rendererCoffee = require './render-coffee'
rendererDyndoc = require './render-dyndoc'
DyndocTaskWriter = require './dyndoc-task-writer'

#rendererDyndoc = null # Defer until user choose mode local or server

createDyndocViewer = (state) ->
  DyndocViewer ?= require './dyndoc-viewer'
  dyndoc_viewer = new DyndocViewer(state)

isDyndocViewer = (object) ->
  DyndocViewer ?= require './dyndoc-viewer'
  object instanceof DyndocViewer

atom.deserializers.add
  name: 'DyndocViewer'
  deserialize: (state) ->
    createDyndocViewer(state) if state.constructor is Object

user_home=process.env[if process.platform=="win32" then "USERPROFILE" else "HOME"]

module.exports =
  config:
    containerName:
      type: 'string'
      default: 'dyndoc'
    dyndocHome:
      type: 'string'
      default: if fs.existsSync(path.join user_home,".dyndoc_home") then String(fs.readFileSync(path.join user_home,".dyndoc_home")).trim() else path.join user_home,"dyndoc"
    dyndocMachine:
      type: 'string'
      default: 'default'
    addToPath:
      type: 'string'
      default: '/usr/local/bin:' + path.join(user_home,"bin") # you can add anoter path with ":"
    breakOnSingleNewline:
      type: 'boolean'
      default: false
    liveUpdate:
      type: 'boolean'
      default: true
    grammars:
      type: 'array'
      default: [
        'source.dyndoc'
        'source.gfm'
        'text.html.basic'
        'text.html.textile'
      ]

  activate: (state) ->
    console.log "activate!!!"
    atom.commands.add 'atom-workspace',
      'dyndoc:eval': =>
        @eval()
      'dyndoc:task-write-dyn2tex2pdf': =>
        @writeTask("dyn2tex2pdf")
      'dyndoc:task-write-dyn2html': =>
        @writeTask("dyn2html")
      'dyndoc:task-write-dyn2html-cli': =>
        @writeTask("dyn2html-cli")
      'dyndoc:atom-dyndoc': =>
        @atomDyndoc()
      'dyndoc:coffee': =>
        @coffee()
      'dyndoc:toggle': =>
        @toggle()
      'dyndoc:toggle-break-on-single-newline': ->
        keyPath = 'dyndoc.breakOnSingleNewline'
        atom.config.set(keyPath,!atom.config.get(keyPath))


    #atom.workspaceView.on 'dyndoc:preview-file', (event) =>
    #  @previewFile(event)

    console.log "end activate!!!"

    atom.workspace.addOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'dyndoc:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        createDyndocViewer(editorId: pathname.substring(1))
      else
        createDyndocViewer(filePath: pathname)

  coffee: ->
    text = atom.workspace.getActiveTextEditor().getSelectedText()
    console.log rendererCoffee.eval text

  atomDyndoc: ->
    text = atom.workspace.getActiveTextEditor().getSelectedText()
    if text == ""
      text = atom.workspace.getActiveTextEditor().getText()
    #util = require 'util'

    text='[#require]Tools/AtomDyndoc\n[#main][#>]{#atomInit#}\n'+text
    ##console.log "text:  "+text
    text=text.replace /\#\{/g,"__AROBAS_ATOM__{"
    rendererDyndoc.eval text, atom.workspace.getActiveTextEditor().getPath(), (error, content) ->
      if error
        console.log "err: "+content
      else
        #console.log "before:" + content
        content=content.replace /__DIESE_ATOM__/g, '#'
        content=content.replace /__AROBAS_ATOM__\{/g, '#{'

        #
        console.log "echo:" + content
        #fs = require "fs"
        #fs.writeFile "/Users/remy/test_atom.coffee", content, (error) ->
        #  console.error("Error writing file", error) if error
        rendererCoffee.eval content

  eval: ->
    return unless dyndoc_viewer
    text = atom.workspace.getActiveTextEditor().getSelectedText()
    if text == ""
      text = atom.workspace.getActiveTextEditor().getText()
    dyndoc_viewer.render(text)
    #res = renderer.toText text, "toto", (error, content) ->
    #  if error
    #    console.log "err: "+content
    #  else
    #   console.log "echo:" + content

  writeTask: (mode) ->
    dyn_file = atom.workspace.getActivePaneItem().getPath()
    console.log("write task mode " + mode + " for dyn_file:"+dyn_file)
    DyndocTaskWriter.write_task dyn_file, mode

  toggle: ->
    console.log("dyndoc:toggle")
    if isDyndocViewer(atom.workspace.activePaneItem)
      atom.workspace.destroyActivePaneItem()
      return

    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    console.log("dyndoc:toggle")
    #grammars = atom.config.get('dyndoc-viewer.grammars') ? []
    #return unless editor.getGrammar().scopeName in grammars

    @addDyndocViewerForEditor(editor) unless @removeDyndocViewerForEditor(editor)

  uriForEditor: (editor) ->
    "dyndoc://editor/#{editor.id}"

  removeDyndocViewerForEditor: (editor) ->
    uri = @uriForEditor(editor)
    console.log(uri)
    previewPane = atom.workspace.paneForURI(uri)
    console.log("preview-pane: "+previewPane)
    if previewPane?
      previewPane.destroyItem(previewPane.itemForURI(uri))
      true
    else
      false

  addDyndocViewerForEditor: (editor) ->
    uri = @uriForEditor(editor)
    console.log "uri:"+uri
    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, split: 'right', searchAllPanes: true).done (DyndocViewer) ->
      if isDyndocViewer(DyndocViewer)
        #DyndocViewer.renderDyndoc()
        previousActivePane.activate()


  # previewFile: ({target}) ->
  #   filePath = $(target).view()?.getPath?() #Maybe to replace with: filePath = target.dataset.path
  #   return unless filePath

  #   for editor in atom.workspace.getEditors() when editor.getPath() is filePath
  #     @addPreviewForEditor(editor)
  #     return

  #   atom.workspace.open "dyndoc://#{encodeURI(filePath)}", searchAllPanes: true
