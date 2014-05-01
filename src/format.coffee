_   = require('lodash')
DOM = require('./dom')


class Format
  @types:
    LINE: 'line'

  @EMBED_TEXT: '!' # No reason we picked ! besides it being one character (so delta cannot split it up)

  @FORMATS:
    bold:
      tag: 'B'
      prepare: 'bold'

    italic:
      tag: 'I'
      prepare: 'italic'

    underline:
      tag: 'U'
      prepare: 'underline'

    strike:
      tag: 'S'
      prepare: 'strikeThrough'

    color:
      style: 'color'
      default: '#000'
      prepare: 'foreColor'

    background:
      style: 'backgroundColor'
      default: '#fff'
      prepare: 'backColor'

    font:
      style: 'fontFamily'
      default: "'Helvetica', 'Arial', sans-serif"
      prepare: 'fontName'

    size:
      style: 'fontSize'
      default: '13px'
      prepare: 'fontSize'

    link:
      tag: 'A'
      attribute: 'href'

    image:
      tag: 'IMG'
      attribute: 'src'

    align:
      type: Format.types.LINE
      style: 'textAlign'
      default: 'left'


  constructor: (@document, @config) ->

  add: (node, value) ->
    return this.remove(node) unless value
    return node if this.value(node) == value
    if _.isString(@config.tag)
      formatNode = @document.createElement(@config.tag)
      if DOM.VOID_TAGS[formatNode.tagName]?
        node.parentNode.insertBefore(formatNode, node) if node.parentNode?
        DOM.removeNode(node)
        node = formatNode
      else
        node = DOM.wrap(formatNode, node)
    if DOM.isTextNode(node)
      node = DOM.wrap(@document.createElement(DOM.DEFAULT_INLNE_TAG), node)
    if _.isString(@config.style)
      node.style[@config.style] = value if value != @config.default
    if _.isString(@config.attribute)
      node.setAttribute(@config.attribute, value)
    if _.isString(@config.class)
      this.remove(node)
      DOM.addClass(node, @config.class + value)
    return node

  isType: (type) ->
    return type == @config.type

  match: (node) ->
    return false unless DOM.isElement(node)
    if _.isString(@config.tag) and node.tagName != @config.tag
      return false
    if _.isString(@config.style) and (!node.style[@config.style] or node.style[@config.style] == @config.default)
      return false
    if _.isString(@config.attribute) and !node.hasAttribute(@config.attribute)
      return false
    if _.isString(@config.class)
      for c in DOM.getClasses(node)
        return true if c.indexOf(@config.class) == 0
      return false
    return true

  prepare: (value) ->
    if _.isString(@config.prepare)
      @document.execCommand(@config.prepare, false, value)
    else if _.isFunction(@config.prepare)
      @config.prepare(@document, value)

  remove: (node) ->
    return unless this.match(node)
    if _.isString(@config.style)
      node.style[@config.style] = ''    # IE10 requires setting to '', other browsers can take null
      node.removeAttribute('style') unless node.getAttribute('style')  # Some browsers leave empty style attribute
    if _.isString(@config.attribute)
      node.removeAttribute(@config.attribute)
    if _.isString(@config.class)
      for c in DOM.getClasses(node)
        DOM.removeClass(node, c) if c.indexOf(@config.class) == 0
      node.removeAttribute('class') unless node.getAttribute('class')  # Some browsers leave empty style attribute
    if _.isString(@config.tag)
      node = DOM.switchTag(node, DOM.DEFAULT_INLNE_TAG)
      DOM.setText(node, Format.EMBED_TEXT) if DOM.EMBED_TAGS[@config.tag]?
    return node

  value: (node) ->
    return undefined unless this.match(node)
    if _.isString(@config.attribute)
      return node.getAttribute(@config.attribute) or undefined
    else if _.isString(@config.style) and node.style[@config.style] != @config.default
      return node.style[@config.style] or undefined
    else if _.isString(@config.class)
      for c in DOM.getClasses(node)
        return c.slice(@config.class.length) if c.indexOf(@config.class) == 0
    else if _.isString(@config.tag) and node.tagName == @config.tag
      return true
    return undefined


module.exports = Format
