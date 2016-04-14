GherkinTableFormatter = require '../lib/gherkin-table-formatter'
testTables = require './test-tables'
testTablesDefault = require './test-tables-default'
nonTables = require './non-tables'

describe "gherkin-table-formatter", ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('gherkin-table-formatter')

  it "should load correctly", ->
    expect(GherkinTableFormatter).toBeDefined()
    expect(GherkinTableFormatter.tableFormatter).toBeDefined()

  describe "regex tests", ->
    it "should match the regex", ->
      for table in testTables
        expect(table.test).toMatch(GherkinTableFormatter.tableFormatter.regex)

    # it "should NOT match the regex", ->
    #   for table in nonTables
    #     expect(table).not.toMatch(GherkinTableFormatter.tableFormatter.regex)

  testFormat = (formatter, modifier) -> (input, expected) ->
    modifier ?= (x) -> x
    rand = Math.random()
    expect(formatter modifier(input, rand)).toEqual(modifier(expected, rand))

  testSuiteSingle = (test, tbls) ->
    it "should properly format these tables", ->
      for table in tbls
        test table.test, table.expected

  testSuite = (test) ->
    testSuiteSingle(test, [testTables[2]])

    # for just, tbls of testTablesDefault
    #   describe "Default #{just} justification tests", ->
    #     do (just) ->
    #       beforeEach ->
    #         GherkinTableFormatter.tableFormatter.defaultTableJustification = just
    #     testSuiteSingle test, tbls

  describe "format tests", ->
    test = testFormat (input) ->
      rx = GherkinTableFormatter.tableFormatter.regex
      rx.lastIndex = 0
      GherkinTableFormatter.tableFormatter.formatTable rx.exec(input)

    beforeEach ->
      GherkinTableFormatter.tableFormatter.spacePadding = 1

    testSuite test
  #
  # describe "editor tests", ->
  #   editor = null
  #
  #   test = testFormat editorFormat = (input) ->
  #     editor.setText input
  #     GherkinTableFormatter.tableFormatter.format editor
  #     editor.getText()
  #
  #   beforeEach ->
  #     editor = atom.workspace.buildTextEditor()
  #     GherkinTableFormatter.tableFormatter.spacePadding = 1
  #     GherkinTableFormatter.tableFormatter.autoSelectEntireDocument = true
  #     GherkinTableFormatter.tableFormatter.formatOnSave = false
  #     GherkinTableFormatter.tableFormatter.markdownGrammarScopes = ['source.feature']
  #     waitsForPromise ->
  #       atom.packages.activatePackage('language-gherkin').then ->
  #         editor.setGrammar(atom.grammars.grammarForScopeName('source.feature'))
  #
  #   testSuite test

    # it "shouldn't try to format non-tables", ->
    #   for nonTable in nonTables
    #     test nonTable, nonTable
    #
    # describe "Tables at the end of document", ->
    #   modTest = testFormat editorFormat, (text, rand) ->
    #     nonTables[Math.floor(rand * nonTables.length)] + "\n" + text
    #   testSuite modTest
    #
    # describe "Tables at the beginning of document", ->
    #   modTest = testFormat editorFormat, (text, rand) ->
    #     text + "\n" + nonTables[Math.floor(rand * nonTables.length)]
    #   testSuite modTest
    #
    # it "should properly format large text", ->
    #   edtext = ""
    #   expected = ""
    #   for table in testTables
    #     text = nonTables[Math.floor(Math.random() * nonTables.length)]
    #     edtext += "\n" + text + "\n" + table.test
    #     expected += "\n" + text + "\n" + table.expected
    #   test edtext, expected
