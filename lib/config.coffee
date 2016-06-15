module.exports = {
  icons:
    description: 'Show shortcut icons for bookmarking and opening/hiding panel'
    type: 'boolean'
    default: true
    order: 1
  git:
    description: 'Show git modified files'
    type: 'boolean'
    default: true
    order: 2
  auto:
    title: 'Auto bookmark files'
    description: 'Auto add modified files as bookmarked'
    type: 'boolean'
    default: false
    order: 3
}
