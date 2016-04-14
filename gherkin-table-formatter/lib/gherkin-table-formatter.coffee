TableFormatter = require './table-formatter.coffee'

module.exports =
    config:
      spacePadding:
        type: 'integer'
        default: 1
        description:
          'How many spaces between left and right of each column content'
      gherkinGrammarScopes:
        type: 'array'
        default: ['source.feature']
        description:
          'File grammar scopes that will be considered Gherkin by this package (comma-separated).
          Run \'Editor: Log Cursor Scope\' command to see what grammar scope
          is used by your grammar. Top entry is usually file grammar scope.'
        items:
          type: 'string'

    activate: ->
      @tableFormatter = new TableFormatter()
      #Register command to workspace
      @command = atom.commands.add "atom-text-editor",
        "gherkin-table-formatter:format", (event) =>
          @tableFormatter.format(event.target.getModel())

    deactivate: ->
      @command.dispose()
      @tableFormatter.destroy()
