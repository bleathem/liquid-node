Liquid = require "../../liquid"
Promise = require "bluebird"

module.exports = class Case extends Liquid.Block
  SyntaxHelp = "Syntax Error in tag 'case' - Valid syntax: case [expression]"

  Syntax     = ///(#{Liquid.QuotedFragment.source})///

  WhenSyntax = ///
      (#{Liquid.QuotedFragment.source})
      (?:
        (?:\s+or\s+|\s*\,\s*)
        (#{Liquid.QuotedFragment.source})
      )?
    ///

  constructor: (template, tagName, markup) ->
    @blocks = []

    match = Syntax.exec markup
    throw new Liquid.SyntaxError(SyntaxHelp) unless match

    @markup = markup
    super

  unknownTag: (tag, markup) ->
    if tag in ["when", "else"]
      @pushBlock(tag, markup)
    else
      super

  render: (context) ->
    context.stack =>
      Promise.reduce(@blocks, (chosenBlock, block) ->
        return chosenBlock if chosenBlock? # short-circuit

        Promise
        .try ->
          block.evaluate context
        .then (ok) ->
          block if ok
      , null)
      .then (block) =>
        if block?
          @renderAll block.attachment, context
        else
          ""

  # private

  pushBlock: (tag, markup) ->
    if tag == "else"
      block = new Liquid.ElseCondition()
      @blocks.push block
      @nodelist = block.attach []
    else
      expressions = Liquid.Helpers.scan markup, WhenSyntax

      nodelist = []

      for value in expressions[0]
        if value
          block = new Liquid.Condition(@markup, '==', value)
          console.log block
          @blocks.push block
          @nodelist = block.attach nodelist