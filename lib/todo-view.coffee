{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'
$ = jQuery = require "jquery"

module.exports =
class FbTodoView

  bookmarks: null

  # atom.deserializers.add(this)
  # @deserialize: ({data}) ->
  #   new FileBookmarkView (data)
  #
  # serialize: -> { deserializer: 'FileBookmarkView', data: @bookmarks }

  constructor: (serializedState) ->

    @bookmarks = []
    @bookmarks = serializedState if serializedState?

    # Create root element
    @element = document.createElement 'div'
    @element.classList.add 'fb-todo-list', 'hidden'
    @element.innerHTML =
      """
        <span>asdf</span>
      """


    # TODO: check if is enabled on startup
    # @panel = atom.workspace.addRightPanel item: this

    self = this

    # $(@element).on 'click', '.fb-filename', ->
    #   atom.workspace.open (self._entryForElement(this))
    # $(@element).on 'click', '.fb-clear-all-btn', =>
    #   @clearBookmarks()
    # $(@element).on 'click', '.file-bookmark-remove', ->
    #   self.removeBookmark (self._entryForElement(this))

    @renderItems()


  renderItems: () ->
    todoList = $('.fb-todo-list')
    todoList.empty()

    # groupedItems = @_groupPaths @bookmarks
    # for path, files of groupedItems
    #   itemT = "<div class='file-bookmark-item'>"
    #   itemT += "<span class='fb-relative-path icon icon-file-directory'>#{path}</span>"
    #   for file in files
    #     itemT += "<span class='icon icon-x file-bookmark-remove' data-path=\"#{file.path}\"></span>"
    #     itemT += "<span class='fb-filename' data-path=\"#{file.path}\">#{file.name}</span>"
    #   itemT += "</div>"
    #   bookmarkList.append itemT

  getElement: ->
    @element

  show: () ->
    @element.classList.remove 'hidden'

  hide: () ->
    @element.classList.remove 'hidden'
    @element.classList.add 'hidden'
