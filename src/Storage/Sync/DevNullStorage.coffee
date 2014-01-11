Storage = require './Storage'

class DevNullStorage extends Storage


	async: false


	getData: ->
		return {}


	getMeta: ->
		return {}


	writeData: (data, meta) ->
		return @


	read: (key) ->
		return null


	write: (key, data, dependencies = {}) ->
		return @


	remove: (key) ->
		return @


module.exports = DevNullStorage