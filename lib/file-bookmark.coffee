FileBookmarkView = require './file-bookmark-view'
# FbSettingsView = require './settings-view.coffee'
{CompositeDisposable} = require 'atom'

fs = require "fs"
$ = jQuery = require "jquery"
_ = require 'underscore-plus'

class FileBookmark

  # TODO: bookmark forever - make files available in all projects
  # TODO: quick settings icon

  config: require('./config.coffee')

  show: null
  todo: null
  currentPath: null
  disabled: null
  git: null
  autoBookmark: null

  MSG_ADDED: "File bookmarked"
  MSG_REMOVED: "File removed from bookmarks"

  fileBookmarkView: null
  fbSettingsView: null
  subscriptions: null

  activate: (state) ->
    if Object.keys(state).length
      @fileBookmarkView = atom.deserializers.deserialize state.fileBookmarkViewState
    else
      @fileBookmarkView = new FileBookmarkView()
    @show = @disabled = @todo = no
    @currentPath = @_getCurrentPath()

    @git = atom.project.getRepositories()

    @subscriptions = new CompositeDisposable

    # Register commands
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:toggle-panel': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:add': => @add()
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:remove': => @remove()
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:toggle-bookmark': => @toggleBookmark()
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:toggle-shortcut-icons': => @toggleShortcutIcons()
    # @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:toggle-todo-list': => @toggleTodoList()
    # @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:test': => @testShit()
    # tooltips
    @tooltipDelay = {
      show: 100
      hide: 100
    }
    @subscriptions.add atom.tooltips.add @fileBookmarkView.favoriteIcon, {
      title: 'Bookmark'
      delay: @tooltipDelay
      placement: 'left'
    }
    @subscriptions.add atom.tooltips.add $('.fb-toggle-icon'), {
      title: 'Toggle panel'
      delay: @tooltipDelay
      placement: 'left'
    }
    @subscriptions.add atom.tooltips.add @fileBookmarkView.treeToggleIcon, {
      title: 'Toggle tree view'
      delay: @tooltipDelay
      placement: 'bottom'
    }

    @subscriptions.add atom.workspace.onDidChangeActivePaneItem => @_handleChangeActivePane()
    @subscriptions.add atom.packages.onDidActivateInitialPackages => @_handleDependencies()
    if atom.config.get 'file-bookmark.git'
      @_handleGitListener yes
      @_handleGitStatus()
    @_handleIconsConfig (atom.config.get 'file-bookmark.icons')
    @autoBookmark = atom.config.get 'file-bookmark.auto'

    # TODO: listen changes in settings and tree view activation

    $(@fileBookmarkView.element).on 'click', '.bookmark-this', => @toggleBookmark()
    $(@fileBookmarkView.element).on 'click', '.fb-toggle-icon', => @toggle()
    # $(@fileBookmarkView.element).on 'click', '.settings-button', => @toggleSettingsView()

    self = this
    $(@fileBookmarkView.element).on 'click', '.file-bookmark-remove', ->
      self.remove (self.fileBookmarkView._entryForElement(this))

    @fileBookmarkView.hide()

  deactivate: ->
    @subscriptions.dispose()
    @fileBookmarkView.destroy()

  serialize: ->
    fileBookmarkViewState: @fileBookmarkView.serialize()

  toggle: =>
    if @show
      @fileBookmarkView.hide()
    else
      @fileBookmarkView.show()
    @show = not @show

  toggleShortcutIcons: =>
    showIcons = not atom.config.get 'file-bookmark.icons'
    atom.config.set 'file-bookmark.icons', showIcons

  toggleTodoList: =>
    if @todo
      @fileBookmarkView.hideTodo()
      @todo = no
    else
      @fileBookmarkView.showTodo()
      @todo = yes

  testShit: ->
    @_handleGitStatus()

  toggleSettingsView: ->
    # TODO: create when everything else is loaded
    @fbSettingsView = new FbSettingsView() unless @fbSettingsView?
    @fbSettingsView.toggleView()

  observeConfigChanges: =>
    atom.config.observe 'file-bookmark.icons', value ->
      @_handleIconsConfig value
    atom.config.observe 'file-bookmark.git', value ->
      @_handleGitListener value
    atom.config.observe 'file-bookmark.auto', value ->
      @autoBookmark = value

  _hideShortcutIcons: =>
    @fileBookmarkView.fbIcons.classList.remove 'hidden'
    @fileBookmarkView.fbIcons.classList.add 'hidden'

  _showShortcutIcons: =>
    @fileBookmarkView.fbIcons.classList.remove 'hidden'

  toggleFileTree: ->
    # TODO: isPackageActive doing problems on non-dev instance?
    # if atom.packages.isPackageActive 'tree-view'
    atom.commands.dispatch atom.views.getView(atom.workspace), 'tree-view:toggle'

  toggleBookmark: ->
    return if @disabled
    if @_checkIfBookmarked @currentPath
      @remove()
    else
      @add()

  add: ->
    return if @disabled
    unless @_checkIfBookmarked @currentPath
      paths = @fileBookmarkView.getBookmarks()
      paths.push @currentPath
      @fileBookmarkView.setBookmarks paths
      @fileBookmarkView.redrawBookmarks @currentPath
      @_handleGitStatus()

  remove: (path=null) =>
    return if @disabled
    unless path?
      path = @currentPath
    if @_checkIfBookmarked path
      paths = @fileBookmarkView.getBookmarks().filter (item) => item isnt path
      @fileBookmarkView.setBookmarks paths
      @fileBookmarkView.redrawBookmarks path
      @_handleGitStatus()

  _checkIfBookmarked: (path) ->
    if path in @fileBookmarkView.getBookmarks()
      return yes
    else
      return no

  _getEditors: -> atom.workspace.getTextEditors()

  _getActiveEditor: -> atom.workspace.getActiveTextEditor()

  _pathExists: (path) -> fs.existsSync path

  _getCurrentPath: -> @_getActiveEditor()?.getPath()

  _handleChangeActivePane: =>
    if @_getActiveEditor()?
      @disabled = no
      @_showShortcutIcons()
    else
      # prevent bookmarking
      @disabled = yes
      @_hideShortcutIcons()
      return

    @currentPath = @_getCurrentPath()
    if @_pathExists @currentPath
      @fileBookmarkView.updateBookmarkIcon @currentPath
      @fileBookmarkView.highlightActiveFile @currentPath

  _handleDependencies: ->
    if atom.packages.isPackageActive 'tree-view'
      $(@fileBookmarkView.element).on 'click', '.fb-tree-toggle', => @toggleFileTree()
    else
      $('.file-bookmark-tree-toggle-icon').addClass 'hidden'

  _handleGitStatus: =>
    return unless atom.config.get 'file-bookmark.git'

    for path in @fileBookmarkView.getBookmarks()
      isModified = isNew = no
      @git.forEach (repo) =>
        isModified ||= repo?.isPathModified(path)
        isNew ||= repo?.isPathNew(path)

        if isModified
          @fileBookmarkView.updateModifiedPath path
        else if isNew
          @fileBookmarkView.updateNewPath path
        else
          @fileBookmarkView.clearGitStatus path

  _handleGitListener: (register) =>
    @observer = atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave =>
        @_handleGitStatus()
        @add() if @autoBookmark
    if register
      @subscriptions.add @observer
    else
      @subscriptions.remove @observer
      @observer.dispose()

  _handleIconsConfig: (configValue) =>
    @fileBookmarkView.fbIcons.classList.remove 'hidden'
    if configValue
      @_handleChangeActivePane()
    else
      @fileBookmarkView.fbIcons.classList.add 'hidden'


module.exports = new FileBookmark()
