{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'
$ = jQuery = require "jquery"

module.exports =
class FileBookmarkView

  bookmarks: null

  atom.deserializers.add(this)
  @deserialize: ({data}) ->
    new FileBookmarkView (data)

  serialize: -> { deserializer: 'FileBookmarkView', data: @bookmarks }

  constructor: (serializedState) ->

    @bookmarks = []
    @bookmarks = serializedState if serializedState?

    # Create root element
    @element = document.createElement 'div'
    @element.classList.add('file-bookmark','file-bookmark-right','file-bookmark-vertical')

    @container = document.createElement 'div'
    @container.classList.add 'file-bookmark-container', 'file-bookmark-260px'
    @settingsContainer = document.createElement 'div'
    @settingsContainer.classList.add 'file-bookmark-settings-container', 'file-bookmark-260px', 'hidden'

    @fbIcons = document.createElement 'div'
    @fbIcons.classList.add 'file-bookmark-icons', 'panel-open'

    @favoriteIcon = document.createElement 'div'
    @favoriteIcon.classList.add 'file-bookmark-toggle-icon'
    @favoriteIcon.innerHTML = "<span class='bookmark-this fb-icon icon icon-heart'></span>"
    @fbIcons.appendChild @favoriteIcon

    toggleIcon = document.createElement 'div'
    toggleIcon.classList.add 'file-bookmark-toggle-icon'
    toggleIcon.innerHTML =
      """
        <span class='fb-toggle-icon fb-toggle-hide fb-icon icon icon-arrow-right'></span>
        <span class='fb-toggle-icon fb-toggle-show fb-icon icon icon-arrow-left hidden'></span>
      """
    @fbIcons.appendChild toggleIcon

    @treeToggleIcon = document.createElement 'div'
    @treeToggleIcon.classList.add 'file-bookmark-tree-toggle-icon'
    @treeToggleIcon.innerHTML = "<span class='fb-tree-toggle fb-icon icon icon-three-bars'></span>"
    @fbIcons.appendChild @treeToggleIcon

    header = document.createElement 'div'
    header.innerHTML =
      """
        Bookmarked files<button class='fb-clear-all-btn pull-right btn btn-primary inline-block-tight'>Clear</button>
      """
    header.classList.add 'title'

    toolbar = document.createElement 'div'
    toolbar.innerHTML =
      """
        <div class='block'>
          <button class='fb-add-all-btn btn btn-sm icon icon-repo-pull inline-block-tight'>
            Add all git modified files
          </button>
        </div>
      """

    bList = document.createElement 'div'
    bList.classList.add 'file-bookmark-list'

    @container.appendChild header
    @container.appendChild toolbar
    @container.appendChild bList

    @element.appendChild @container
    @element.appendChild @settingsContainer
    @element.appendChild @fbIcons

    # TODO: check if is enabled on startup
    @panel = atom.workspace.addRightPanel item: this

    self = this

    $(@element).on 'click', '.fb-filename', ->
      atom.workspace.open (self._entryForElement(this))

    @renderItems()


  renderItems: () ->
    bookmarkList = $('.file-bookmark-list')
    bookmarkList.empty()

    groupedItems = @_groupPaths @bookmarks
    for path, files of groupedItems
      itemT = "<div class='file-bookmark-item'>"
      itemT += "<span class='fb-relative-path icon icon-file-directory'>#{path}</span>"
      for file in files
        itemT += "<span class='icon icon-x file-bookmark-remove' data-path=\"#{file.path}\"></span>"
        itemT += "<span class='fb-filename' data-path=\"#{file.path}\">#{file.name}</span>"
      itemT += "</div>"
      bookmarkList.append itemT

  show: ->
    @container.classList.remove 'hidden'
    @fbIcons.classList.remove 'panel-closed'
    @fbIcons.classList.add 'panel-open'
    @_showLeft()

  hide: ->
    @container.classList.add 'hidden'
    @fbIcons.classList.remove 'panel-open'
    @fbIcons.classList.add 'panel-closed'
    @_showRight()

  showAddGitModifiedButton: ->
    $('.fb-add-all-btn').removeClass('hidden');

  hideAddGitModifiedButton: ->
    $('.fb-add-all-btn').addClass('hidden');


  redrawBookmarks: (path) ->
    @renderItems()
    @updateBookmarkIcon path
    @highlightActiveFile path

  updateBookmarkIcon: (path) ->
    @favoriteIcon.classList.remove 'fb-file-bookmarked', 'fb-file-not-bookmarked'
    if path in @bookmarks
      @favoriteIcon.classList.add 'fb-file-bookmarked'
    else
      @favoriteIcon.classList.add 'fb-file-not-bookmarked'

  # Tear down any state and detach
  destroy: ->
    @panel.destroy() if @panel?
    @element.remove()

  getElement: ->
    @element

  getBookmarks: ->
    @bookmarks

  setBookmarks: (paths) ->
    @bookmarks = paths

  clearBookmarks: ->
    @bookmarks = []
    @renderItems()
    @updateBookmarkIcon ''

  highlightActiveFile: (path) ->
    $(@element).find('.fb-filename').removeClass 'fb-selected'
    $(@element).find('.file-bookmark-remove').removeClass 'fb-selected'
    $(@element).find("[data-path=\"#{path}\"]").addClass 'fb-selected'

  updateModifiedPath: (path) ->
    # find and color
    fileElement = @_findPathElement path
    fileElement.addClass 'status-modified'

  updateNewPath: (path) ->
    # find and color
    fileElement = @_findPathElement path
    fileElement.addClass 'status-added'

  clearGitStatus: (path) ->
    fileElement = @_findPathElement path
    fileElement.removeClass 'status-modified', 'status-added'

  _findPathElement: (path) ->
    $(@element).find("[data-path=\"#{path}\"]")

  _groupPaths: (paths) ->
    output = {}
    for path in paths
      item = @_splitPathnameAndFilename path
      return output unless item?
      if output[item[0]]?
        output[item[0]].push { name: item[1], path: path }
        output[item[0]].sort @_sortFilenameCallback
      else
        output[item[0]] = [{ name: item[1], path: path }]
    output

  _sortFilenameCallback: (a, b) ->
    return 1 if (a.name > b.name)
    return -1 if (a.name < b.name)
    return 0

  _splitPathnameAndFilename: (path) ->
    split = atom.project.relativizePath path
    return null unless split[1]? # Cannot bookmark folders (for now), just files.
    pathArray = split[1].split('/')
    relativePath = (_.initial pathArray).join('/')
    [relativePath, _.last pathArray]

  _entryForElement: (item) ->
    itemPath = item.getAttribute 'data-path'
    _.find @bookmarks, (entry) ->
      if (entry is itemPath)
        return itemPath

  _showLeft: ->
    $(@element).find('.fb-toggle-show').addClass 'hidden'
    $(@element).find('.fb-toggle-hide').removeClass 'hidden'

  _showRight: ->
    $(@element).find('.fb-toggle-show').removeClass 'hidden'
    $(@element).find('.fb-toggle-hide').addClass 'hidden'
