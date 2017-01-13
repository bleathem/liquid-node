Liquid = require "../../liquid"

module.exports = class Include extends Liquid.Tag
  Syntax = /([\.a-z0-9\/\\_-]+)/i
  SyntaxHelp = "Syntax Error in 'include' -
                    Valid syntax: include [templateName]"

  constructor: (template, tagName, markup, tokens) ->
    match = Syntax.exec(markup)
    throw new Liquid.SyntaxError(SyntaxHelp) unless match

    @attributes = {}
    Liquid.Helpers.scan(markup, Liquid.TagAttributes).forEach (attr) =>
      @attributes[attr[0]] = attr[1]

    @filepath = match[1]
    @subTemplate = template.engine.fileSystem.readTemplateFile(@filepath)
      .then (src) ->
        template.engine.parse(src)


    super

  render: (context) ->
    attributes = @attributes
    @subTemplate.then (i) ->
      context.stack ->
        Promise.resolve().then ->
          include = {}
          for k, v of attributes
            context.set k, context.resolve v
            include[k] = context.resolve v
          context.set 'include', include
          i.render context
