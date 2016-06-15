{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'
$ = jQuery = require "jquery"

module.exports =
class FbSettingsView

  bookmarks: null
  shown: null

  fbContainer: null
  fbSettingsContainer: null

  # atom.deserializers.add(this)
  # @deserialize: ({data}) ->
  #   new FileBookmarkView (data)
  #
  # serialize: -> { deserializer: 'FileBookmarkView', data: @bookmarks }

  constructor: (serializedState) ->

    # @bookmarks = []
    # @bookmarks = serializedState if serializedState?

    @shown = no

    # Create root element
    @element = document.createElement 'div'
    @element.classList.add 'file-bookmark-settings', 'hidden'

    buttonsBar = document.createElement 'div'
    buttonsBar.classList.add 'file-bookmark-buttons'
    buttonsBar.innerHTML =
      """
        <button class="pull-left btn icon icon-tools settings-button">Close</button>
      """

    @element.appendChild buttonsBar

    self = this

    @fbContainer = $('.file-bookmark-container')
    @fbSettingsContainer = $('.file-bookmark-settings-container')

    @fbSettingsContainer.append @element

    @renderItems()


  renderItems: () ->
    # todoList = $('.fb-todo-list')
    # todoList.empty()

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

  show: =>
    @element.classList.remove 'hidden'
    @fbContainer.removeClass 'hidden'
    @fbContainer.addClass 'hidden'
    @fbSettingsContainer.removeClass 'hidden'
    $('.file-bookmark-icons').removeClass 'hidden'
    $('.file-bookmark-icons').addClass 'hidden'

  hide: =>
    @element.classList.remove 'hidden'
    @element.classList.add 'hidden'
    @fbContainer.removeClass 'hidden'
    @fbSettingsContainer.removeClass 'hidden'
    @fbSettingsContainer.addClass 'hidden'
    $('.file-bookmark-icons').removeClass 'hidden'

  toggleView: ->
    if @shown
      @hide()
    else
      @show()
    @shown = not @shown
