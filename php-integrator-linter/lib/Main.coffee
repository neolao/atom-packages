module.exports =
    ###*
     * Configuration settings.
    ###
    config:
        showUnknownClasses:
            title       : 'Show unknown classes'
            description : '''
                Highlights class names that could not be found. This will also work for docblocks.
            '''
            type        : 'boolean'
            default     : true
            order       : 1

        showUnusedUseStatements:
            title       : 'Show unused use statements'
            description : '''
                Highlights use statements that don't seem to be used anywhere. This will also look inside docblocks.
            '''
            type        : 'boolean'
            default     : true
            order       : 2

        validateDocblockCorrectness:
            title       : 'Validate docblock correctness'
            description : '''
                Analyzes the correctness of docblocks of structural elements such as classes, methods and properties.
                This will show various problems with docblocks such as missing parameters, incorrect parameter types
                and missing documentation.
            '''
            type        : 'boolean'
            default     : true
            order       : 3

    ###*
     * The name of the package.
    ###
    packageName: 'php-integrator-linter'

    ###*
     * The name of the package.
    ###
    packageName: 'php-integrator-linter'

    ###*
     * The configuration object.
    ###
    configuration: null

    ###*
     * List of linters.
    ###
    providers: []

    ###*
     * List of indie linters.
    ###
    indieProviders: []

    ###*
     * The semantic lint provider.
    ###
    semanticLintProvider: null

    ###*
     * Activates the package.
    ###
    activate: ->
        AtomConfig           = require './AtomConfig'
        SemanticLintProvider = require './SemanticLintProvider'

        @configuration = new AtomConfig(@packageName)

        @semanticLintProvider = new SemanticLintProvider(@configuration)

        @indieProviders.push(@semanticLintProvider)

    ###*
     * Deactivates the package.
    ###
    deactivate: ->
        @deactivateProviders()

    ###*
     * Activates the providers using the specified service.
    ###
    activateProviders: (service) ->
        for provider in @providers
            provider.activate(service)

        for provider in @indieProviders
            provider.activate(service)

    ###*
     * Deactivates any active providers.
    ###
    deactivateProviders: () ->
        for provider in @providers
            provider.deactivate()

        @providers = []

        for provider in @indieProviders
            provider.deactivate()

        @indieProviders = []

    ###*
     * Sets the php-integrator service.
     *
     * @param {mixed} service
     *
     * @return {Disposable}
    ###
    setService: (service) ->
        @activateProviders(service)

        {Disposable} = require 'atom'

        return new Disposable => @deactivateProviders()

    ###*
     * Sets the linter indie service.
     *
     * @param {mixed} service
     *
     * @return {Disposable}
    ###
    setLinterIndieService: (service) ->
        #indexingIndieLinter = null
        semanticIndieLinter = null

        if service
            semanticIndieLinter = service.register({name : @packageName, scope: 'file',    grammarScopes: ['source.php']})

        @semanticLintProvider.setIndieLinter(semanticIndieLinter)

    ###*
     * Retrieves a list of supported autocompletion providers.
     *
     * @return {array}
    ###
    getProviders: ->
        return @providers
