module.exports =

##*
# The (provider) that handles indexing errors using an indie linter.
##
class IndexingProvider
    ###*
     * The service (that can be used to query the source code and contains utility methods).
    ###
    service: null

    ###*
     * The indie linter.
    ###
    indieLinter: null

    ###*
     * Contains global package settings.
    ###
    config: null

    ###*
     * Constructor.
     *
     * @param {Config} config
    ###
    constructor: (@config) ->

    ###*
     * Initializes this provider.
     *
     * @param {mixed} service
    ###
    activate: (@service) ->
        @attachListeners(@service)

    ###*
     * Deactives the provider.
    ###
    deactivate: () ->

    ###*
     * Sets the indie linter to use.
     *
     * @param {mixed} indieLinter
    ###
    setIndieLinter: (@indieLinter) ->
        @messages = []

    ###*
     * Attaches listeners for the specified base service.
     *
     * @param {mixed} service
    ###
    attachListeners: (service) ->
        service.onDidFinishIndexing (response) =>
            editor = @findTextEditorByPath(response.path)

            return if not editor?

            @semanticLint(editor)

        service.onDidFailIndexing (response) =>
            editor = @findTextEditorByPath(response.path)

            return if not editor?

            @semanticLint(editor)

    ###*
     * @param {TextEditor} editor
    ###
    semanticLint: (editor) ->
        successHandler = (response) =>
            messages = []

            if response.errors.syntaxErrors?
                for item in response.errors.syntaxErrors
                    messages.push @createLinterMessageForSyntaxErrorOutputItem(editor, item)

            if response.errors.unknownClasses?
                for item in response.errors.unknownClasses
                    messages.push @createLinterMessageForOutputItem(
                        editor,
                        item,
                        'Error',
                        "<strong>#{item.name}</strong> was not found."
                    )

            if response.warnings.unusedUseStatements? and response.errors.syntaxErrors?.length == 0
                for item in response.warnings.unusedUseStatements
                    messages.push @createLinterMessageForOutputItem(
                        editor,
                        item,
                        'Warning',
                        "<strong>#{item.name}</strong> is not used anywhere."
                    )

            if response.warnings.docblockIssues?
                for item in response.warnings.docblockIssues.varTagMissing
                    messages.push @createLinterMessageForOutputItem(
                        editor,
                        item,
                        'Warning',
                        "The docblock for <strong>#{item.name}</strong> is missing a @var tag."
                    )

                for item in response.warnings.docblockIssues.missingDocumentation
                    messages.push @createLinterMessageForOutputItem(
                        editor,
                        item,
                        'Warning',
                        "Documentation for <strong>#{item.name}</strong> is missing."
                    )

                for item in response.warnings.docblockIssues.parameterMissing
                    messages.push @createLinterMessageForOutputItem(
                        editor,
                        item,
                        'Warning',
                        "The docblock for <strong>#{item.name}</strong> is missing a @param tag for <strong>#{item.parameter}</strong>."
                    )

                for item in response.warnings.docblockIssues.parameterTypeMismatch
                    messages.push @createLinterMessageForOutputItem(
                        editor,
                        item,
                        'Warning',
                        "The docblock for <strong>#{item.name}</strong> has an incorrect @param type for <strong>#{item.parameter}</strong>."
                    )

                for item in response.warnings.docblockIssues.superfluousParameter
                    parameters = item.parameters.join(', ')

                    messages.push @createLinterMessageForOutputItem(
                        editor,
                        item,
                        'Warning',
                        "The docblock for <strong>#{item.name}</strong> contains superfluous @param tags for: <strong>#{parameters}</strong>."
                    )

                for item in response.warnings.docblockIssues.deprecatedCategoryTag
                    messages.push @createLinterMessageForOutputItem(
                        editor,
                        item,
                        'Warning',
                        "The docblock for <strong>#{item.name}</strong> contains a deprecated @category tag."
                    )

                for item in response.warnings.docblockIssues.deprecatedSubpackageTag
                    messages.push @createLinterMessageForOutputItem(
                        editor,
                        item,
                        'Warning',
                        "The docblock for <strong>#{item.name}</strong> contains a deprecated @subpackage tag."
                    )

                link = 'https://github.com/phpDocumentor/fig-standards/blob/master/proposed/phpdoc.md#710-link-deprecated'

                for item in response.warnings.docblockIssues.deprecatedLinkTag
                    messages.push @createLinterMessageForOutputItem(
                        editor,
                        item,
                        'Warning',
                        "The docblock for <strong>#{item.name}</strong> contains a deprecated @link tag. See also <a href=\"#{link}\">#{link}</a>"
                    )

            if @indieLinter
                @indieLinter.setMessages(messages)

        failureHandler = (response) =>
            if @indieLinter
                @indieLinter.setMessages([])

        options = {
            noUnknownClasses      : not @config.get('showUnknownClasses')
            noDocblockCorrectness : not @config.get('validateDocblockCorrectness')
            noUnusedUseStatements : not @config.get('showUnusedUseStatements')
        }

        @service.semanticLint(editor.getPath(), editor.getBuffer().getText(), options).then(successHandler, failureHandler)

    ###*
     * @param {TextEditor} editor
     * @param {Object}     item
     *
     * @return {Object}
    ###
    createLinterMessageForSyntaxErrorOutputItem: (editor, item) ->
        startLine = if item.startLine then item.startLine else 1
        endLine   = if item.endLine   then item.endLine   else 1

        startColumn = if item.startColumn then item.startColumn else 1
        endColumn =   if item.endColumn   then item.endColumn   else 1

        return {
            type     : 'Error'
            html     : item.message
            range    : [[startLine - 1, startColumn - 1], [endLine - 1, endColumn]]
            filePath : editor.getPath()
        }

    ###*
     * @param {TextEditor} editor
     * @param {Object}     item
     * @param {string}     type
     * @param {string}     html
     *
     * @return {Object}
    ###
    createLinterMessageForOutputItem: (editor, item, type, html) ->
        text =  editor.getBuffer().getText()

        startCharacterOffset = @service.getCharacterOffsetFromByteOffset(item.start, text)
        endCharacterOffset   = @service.getCharacterOffsetFromByteOffset(item.end, text)

        startPoint = editor.getBuffer().positionForCharacterIndex(startCharacterOffset)
        endPoint   = editor.getBuffer().positionForCharacterIndex(endCharacterOffset)

        return {
            type     : type
            html     : html
            range    : [startPoint, endPoint]
            filePath : editor.getPath()
        }

    ###*
     * Retrieves the text editor that is managing the file with the specified path.
     *
     * @param {string} path
     *
     * @return {TextEditor|null}
    ###
    findTextEditorByPath: (path) ->
        for textEditor in atom.workspace.getTextEditors()
            if textEditor.getPath() == path
                return textEditor

        return null
