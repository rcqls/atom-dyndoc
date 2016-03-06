path = require 'path'

{Emitter, Disposable, CompositeDisposable} = require 'atom'
{allowUnsafeEval} = require 'loophole'
{$, $$$, ScrollView} = require 'atom-space-pen-views'

_ = require 'underscore-plus'
fs = require 'fs-plus'
# {File} = require 'pathwatcher'

rendererDyndoc = allowUnsafeEval -> require './render-dyndoc'

module.exports =
class DyndocViewer extends ScrollView
  @content: ->
    @div class: 'dyndoc asciidoc-preview native-key-bindings', tabindex: -1

  constructor: ({@editorId, filePath}) ->
    super
    @emitter = new Emitter
    @disposables = new CompositeDisposable


  attached: ->
    return if @isAttached
    @isAttached = true

    if @editorId?
      @resolveEditor(@editorId)
    else
      if atom.workspace?
        # @subscribeToFilePath(filePath)
      else
        #@subscribe atom.packages.once 'activated', =>
        #  @subscribeToFilePath(filePath)

  serialize: ->
    deserializer: 'DyndocViewer'
    filePath: @getPath()
    editorId: @editorId

  destroy: ->
    @disposables.dispose() #OLD: @unsubscribe()

  # subscribeToFilePath: (filePath) ->
  #   @file = new File(filePath)
  #   @emitter.emit 'title-changed'
  #   @handleEvents()
  #   #@renderDyndoc()

  resolveEditor: (editorId) ->
    resolve = =>
      @editor = @editorForId(editorId)

      if @editor?
        @emitter.emit 'did-title-changed' if @editor?
        @handleEvents()
      else
        # The editor this preview was created for has been closed so close
        # this preview since a preview cannot be rendered without an editor
        @parents('.pane').view()?.destroyItem(this)

    if atom.workspace?
      resolve()
    else
      @disposables.add atom.packages.onDidActivateInitialPackages(resolve)
      # OLD: @subscribe atom.packages.once 'activated', =>
      #   resolve()
      #   #@renderDyndoc()

  editorForId: (editorId) ->
    for editor in atom.workspace.getTextEditors()
      return editor if editor.id?.toString() is editorId.toString()
    null

  handleEvents: ->
    #@subscribe atom.syntax, 'grammar-added grammar-updated', _.debounce((=> @renderDyndoc()), 250)

    atom.commands.add @element,
      'core:move-up': =>
        @scrollUp()
      'core:move-down': =>
        @scrollDown()
      'dyndoc:zoom-in': =>
        zoomLevel = parseFloat(@css('zoom')) or 1
        @css('zoom', zoomLevel + .1)
      'dyndoc:zoom-out': =>
        zoomLevel = parseFloat(@css('zoom')) or 1
        @css('zoom', zoomLevel - .1)
      'dyndoc:reset-zoom': =>
        @css('zoom', 1)

    changeHandler = =>
      #@renderDyndoc()
      pane = atom.workspace.paneForURI(@getURI())
      if pane? and pane isnt atom.workspace.getActivePane()
        pane.activateItem(this)

    if @file?
      @disposables.add @file.onDidChange(changeHandler)
    else if @editor?
      @disposables.add @editor.getBuffer().onDidStopChanging =>
        changeHandler() if atom.config.get 'dyndoc-viewer.liveUpdate'
      @disposables.add  @editor.onDidChangePath => @emitter.emit 'did-title-changed'
      @disposables.add @editor.getBuffer().onDidSave =>
        changeHandler() unless atom.config.get 'dyndoc.liveUpdate'
      @disposables.add @editor.getBuffer().onDidReload =>
        changeHandler() unless atom.config.get 'dyndoc.liveUpdate'

    @disposables.add atom.config.onDidChange 'dyndoc.breakOnSingleNewline', changeHandler

  renderDyndoc: ->
    @showLoading()
    @getDyndocSource().then (source) => @renderDyndocText(source) if source?

  getDyndocSource: ->
    if @file?
      @file.read()
    else if @editor?
      Promise.resolve(@editor.getText())
    else
      Promise.resolve(null)

  render: (text) ->
    console.log("text:"+text)
    rendererDyndoc.eval text, @getPath(), (error, content) =>
      if error
        alert(content)
      else
        @loading = false
        console.log('render content:'+content)
        @html(content)
        #@trigger('dyndoc:dyndoc-changed')

  eval: (text,callback) ->
    console.log("eval text:"+text)
    output = null
    rendererDyndoc.eval text, @getPath(), (error, content) =>
      if error
        alert(content)
        ":eval_dyndoc_error"
      else
        console.log('eval content:'+content)
        callback(content)

  getTitle: ->
    if @file?
      "#{path.basename(@getPath())} Preview"
    else if @editor?
      "#{@editor.getTitle()} Preview"
    else
      "Dyndoc Preview"

  getIconName: ->
    "dyndoc"

  getURI: ->
    if @file?
      "dyndoc://#{@getPath()}"
    else
      "dyndoc://editor/#{@editorId}"

  getPath: ->
    if @file?
      @file.getPath()
    else if @editor?
      @editor.getPath()

  showError: (result) ->
    failureMessage = result?.message

    @html $$$ ->
      @h2 'Previewing dyndoc Failed'
      @h3 failureMessage if failureMessage?

  showLoading: ->
    @loading = true
    @html $$$ ->
      @div class: 'dyndoc-spinner', 'Loading dyndoc\u2026'
