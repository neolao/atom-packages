{CompositeDisposable, Range} = require('atom')
wcswidth = require 'wcwidth'

swidth = (str) ->
  # zero-width Unicode characters that we should ignore for
  # purposes of computing string "display" width
  zwcrx = /[\u200B-\u200D\uFEFF\u00AD]/g
  wcswidth(str) - ( str.match(zwcrx)?.length or 0 )

module.exports =
class TableFormatter
  subscriptions: []

  constructor: ->
    @subscriptions = new CompositeDisposable
    @autoSelectEntireDocument = false
    @initConfig()

  readConfig: (key, callback) ->
    key = 'gherkin-table-formatter.' + key
    @subscriptions.add atom.config.onDidChange key, callback
    callback
      newValue: atom.config.get(key)
      oldValue: undefined

  initConfig: ->
    @readConfig "spacePadding", ({newValue}) =>
      @spacePadding = newValue
    @readConfig "gherkinGrammarScopes", ({newValue}) =>
      @gherkinGrammarScopes = newValue

  destroy: ->
    @subscriptions.dispose()

  format: (editor, force) ->
    if not (editor.getGrammar().scopeName in @gherkinGrammarScopes)
      return

    selectionsRanges = editor.getSelectedBufferRanges()

    bufferRange = editor.getBuffer().getRange()
    selectionsRangesEmpty =
      selectionsRanges.every (i) -> i.isEmpty()
    if force or (selectionsRangesEmpty and @autoSelectEntireDocument)
      selectionsRanges = [bufferRange]
    else
      selectionsRanges =
        for srange in selectionsRanges when not (srange.isEmpty() and
            @autoSelectEntireDocument)
          start = bufferRange.start
          end = bufferRange.end
          editor.scanInBufferRange /^$/m,
            new Range(srange.start, bufferRange.end),
            ({range}) ->
              end = range.start
          editor.backwardsScanInBufferRange /^$/m,
            new Range(bufferRange.start, srange.end),
            ({range}) ->
              start = range.start
          new Range(start, end)

    myIterator = (obj) =>
      obj.replace(@formatTable(obj.match))

    editor.getBuffer().transact =>
      for range in selectionsRanges
        editor.scanInBufferRange(@regex, range, myIterator)

  formatTable: (text) ->
    padding = (len, str = ' ') -> str.repeat len

    stripTailPipes = (str) ->
      str.trim().replace /(^\||\|$)/g, ""

    splitCells = (str) ->
      str.split '|'

    addTailPipes = (str) =>
      "|#{str}|"

    joinCells = (arr) ->
      arr.join '|'

    indent = /^\s*/.exec(text[0])[0]
    lines = text[0].trim().split('\n')

    comments = []
    data_lines = []
    for line, index in lines
      if line.trim().startsWith('#')
        comments.push(index)
      else
        data_lines.push(line)

    columns = (splitCells stripTailPipes data_lines[0]).length

    content = for line in data_lines
      cells =  splitCells stripTailPipes line
      #put all extra content into last cell
      cells[columns - 1] = joinCells cells.slice(columns - 1)
      for cell in cells
        padding(@spacePadding) +
        (cell?.trim?() ? '') +
        padding(@spacePadding)

    widths = for i in [0..columns - 1]
      Math.max 2, (swidth(cells[i]) for cells in content)...

    just = (string, col) ->
      length = widths[col] - swidth(string)
      string + padding(length)

    formatted = for cells in content
      addTailPipes joinCells (just(cells[i], i) for i in [0..columns - 1])
    formatted.splice(index, 0, lines[index].trim()) for index in comments
    formatted = for line in formatted
      indent + line
    return formatted.join('\n') + '\n'

  regex: /(?:(?:(?:.*\|.*)|(?:\s*\#.*))\n)+/
