Storage = require './Storage'

class DevNullStorage extends Storage


	getData: ->
		return {}


	getMeta: ->
		return {}


	writeData: (data, meta) ->


	read: (key) ->
		return null


	write: (key, data, dependencies = {}) ->


	remove: (key) ->


module.exports = DevNullStorage