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
    header.innerHTML = "Bookmarked files<button class='fb-clear-all-btn pull-right btn btn-primary inline-block-tight'>Clear</button>"
    header.classList.add 'title'

    bList = document.createElement 'div'
    bList.classList.add 'file-bookmark-list'

    qNotes = document.createElement 'div'
    qNotes.classList.add 'file-bookmark-notes'

    @container.appendChild header
    @container.appendChild bList
    @container.appendChild qNotes

    @element.appendChild @container
    @element.appendChild @fbIcons

    # TODO: check if is enabled on startup
    @panel = atom.workspace.addRightPanel item: this

    self = this

    $(@element).on 'click', '.fb-filename', ->
      atom.workspace.open(self._entryForElement(this))
    $(@element).on 'click', '.fb-clear-all-btn', =>
      @clearBookmarks()

    @renderItems()


  renderItems: () ->
    bookmarkList = $('.file-bookmark-list')
    bookmarkList.empty()

    groupedItems = @_groupPaths @bookmarks
    for path, files of groupedItems
      itemT = "<div class='file-bookmark-item'>"
      itemT += "<span class='fb-relative-path icon icon-file-directory'>#{path}</span>"
      for file in files
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

  updateBookmarkIcon: (bookmarked) ->
    @favoriteIcon.classList.remove 'fb-file-bookmarked', 'fb-file-not-bookmarked'
    if bookmarked
      @favoriteIcon.classList.add 'fb-file-bookmarked'
    else
      @favoriteIcon.classList.add 'fb-file-not-bookmarked'

  # Tear down any state and detach
  destroy: ->
    @detach() if @panel?
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
    @updateBookmarkIcon no

  _groupPaths: (paths) ->
    output = {}
    for path in paths
      item = @_splitPathnameAndFilename path
      if output[item[0]]?
        output[item[0]].push { name: item[1], path: path }
      else
        output[item[0]] = [{ name: item[1], path: path }]
    output

  _splitPathnameAndFilename: (path) ->
    split = atom.project.relativizePath path
    pathArray = split[1].split('/')
    relativePath = (_.initial pathArray).join('/')
    [relativePath, _.last pathArray]

  _entryForElement: (item) ->
    itemPath = item.getAttribute 'data-path'
    _.find @bookmarks, (entry) ->
      if (entry is itemPath)
        return itemPath

  _showLeft: ->
    $('.fb-toggle-show').addClass 'hidden'
    $('.fb-toggle-hide').removeClass 'hidden'

  _showRight: ->
    $('.fb-toggle-show').removeClass 'hidden'
    $('.fb-toggle-hide').addClass 'hidden'
