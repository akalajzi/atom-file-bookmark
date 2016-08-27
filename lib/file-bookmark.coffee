FileBookmarkView = require './file-bookmark-view'
{CompositeDisposable} = require 'atom'

fs = require "fs"
$ = jQuery = require "jquery"
_ = require 'underscore-plus'

class FileBookmark

  config: require('./config.coffee')

  show: null
  currentPath: null
  disabled: null
  git: null
  autoBookmark: null
  test: null

  MSG_ADDED: "File bookmarked"
  MSG_REMOVED: "File removed from bookmarks"

  fileBookmarkView: null
  subscriptions: null

  activate: (state) ->
    if Object.keys(state).length
      @fileBookmarkView = atom.deserializers.deserialize state.fileBookmarkViewState
    else
      @fileBookmarkView = new FileBookmarkView()
    @show = @disabled = no
    @currentPath = @_getCurrentPath()

    @subscriptions = new CompositeDisposable

    # Register commands
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:toggle-panel': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:add': => @add()
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:remove': => @remove()
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:toggle-bookmark': => @toggleBookmark()
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:toggle-shortcut-icons': => @toggleShortcutIcons()
    @subscriptions.add atom.commands.add 'atom-workspace', 'file-bookmark:load-git-modified-files': => @loadGitModifiedFiles()
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
      Promise
        .all(atom.project.getDirectories().map(
          atom.project.repositoryForDirectory.bind(atom.project)
        ))
        .then (repos) =>
          if repos.length is 0
            @fileBookmarkView.hideAddGitModifiedButton()
            return null
          else
            @fileBookmarkView.showAddGitModifiedButton()
            @git = repos
            @_handleGitListener yes
            @_handleGitStatus()
            return repos
        .catch (e) ->
          atom.notifications.addError 'Failed to get repositories.', {detail: e, dismissable: true}

    @_handleIconsConfig (atom.config.get 'file-bookmark.icons')
    @autoBookmark = atom.config.get 'file-bookmark.auto'

    # TODO: listen changes in settings and tree view activation

    $(@fileBookmarkView.element).on 'click', '.bookmark-this', => @toggleBookmark()
    $(@fileBookmarkView.element).on 'click', '.fb-toggle-icon', => @toggle()
    $(@fileBookmarkView.element).on 'click', '.fb-clear-all-btn', => @fileBookmarkView.clearBookmarks()
    $(@fileBookmarkView.element).on 'click', '.fb-add-all-btn', => @loadGitModifiedFiles()

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
    if @show then @fileBookmarkView.hide() else @fileBookmarkView.show()
    @show = not @show

  toggleShortcutIcons: =>
    showIcons = not atom.config.get 'file-bookmark.icons'
    atom.config.set 'file-bookmark.icons', showIcons

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
    if @_checkIfBookmarked @currentPath then @remove() else @add()

  add: (path=null) ->
    return if @disabled
    path = @currentPath unless path?

    unless @_checkIfBookmarked path
      paths = @fileBookmarkView.getBookmarks()
      paths.push path
      @fileBookmarkView.setBookmarks paths
      @fileBookmarkView.redrawBookmarks path
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

  loadGitModifiedFiles: =>
    return unless atom.config.get 'file-bookmark.git'
    for repo in @git
      innerRepo = repo.repo
      for filePath in Object.keys(innerRepo.getStatus())
        if innerRepo.isPathModified(filePath) or innerRepo.isPathNew(filePath)
          @add innerRepo.getWorkingDirectory() + '/' + filePath

  _checkIfBookmarked: (path) ->
    if path in @fileBookmarkView.getBookmarks() then yes else no

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
