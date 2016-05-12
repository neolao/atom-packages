AbstractProvider = require './AbstractProvider'

module.exports =

##*
# Provides code navigation for class constants.
##
class ClassConstantProvider extends AbstractProvider
    ###*
     * @inheritdoc
    ###
    eventSelectors: '.constant.other.class'

    ###*
     * Convenience method that returns information for the specified term.
     *
     * @param {TextEditor} editor
     * @param {Point}      bufferPosition
     * @param {string}     term
     *
     * @return {Promise}
    ###
    getInfoFor: (editor, bufferPosition, term) ->
        successHandler = (member) =>
            return null unless member
            return null unless member.declaringStructure.filename

            return member

        failureHandler = () ->
            # Do nothing.

        return @getClassConstantAt(editor, bufferPosition, term).then(successHandler, failureHandler)

    ###*
     * Returns the class constant used at the specified location.
     *
     * @param {TextEditor} editor         The text editor to use.
     * @param {Point}      bufferPosition The cursor location of the member.
     * @param {string}     name           The name of the member to retrieve information about.
     *
     * @return {Promise}
    ###
    getClassConstantAt: (editor, bufferPosition, name) ->
        successHandler = (className) =>
            return @getClassConstant(className, name)

        failureHandler = () ->
            # Do nothing.

        return @service.getResultingTypeAt(editor, bufferPosition, true).then(successHandler, failureHandler)

    ###*
     * Retrieves information about the specified constant of the specified class.
     *
     * @param {string} className The full name of the class to examine.
     * @param {string} name      The name of the constant to retrieve information about.
     *
     * @return {Promise}
    ###
    getClassConstant: (className, name) ->
        successHandler = (classInfo) =>
            if name of classInfo.constants
                return classInfo.constants[name]

        failureHandler = () ->
            # Do nothing.

        return @service.getClassInfo(className).then(successHandler, failureHandler)

    ###*
     * @inheritdoc
    ###
    isValid: (editor, bufferPosition, term) ->
        successHandler = (info) =>
            return if info then true else false

        failureHandler = () ->
            return false

        @getInfoFor(editor, bufferPosition, term).then(successHandler, failureHandler)

    ###*
     * @inheritdoc
    ###
    gotoFromWord: (editor, bufferPosition, term) ->
        successHandler = (info) =>
            return if not info?

            atom.workspace.open(info.declaringStructure.filename, {
                initialLine    : (info.declaringStructure.startLineMember - 1),
                searchAllPanes: true
            })

        failureHandler = () ->
            # Do nothing.

        @getInfoFor(editor, bufferPosition, term).then(successHandler, failureHandler)
