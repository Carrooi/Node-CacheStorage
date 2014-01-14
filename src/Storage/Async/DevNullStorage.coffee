Storage = require './Storage'

class DevNullStorage extends Storage


	getData: (fn) ->
		fn({})
		return null


	getMeta: (fn) ->
		fn({})
		return null


	writeData: (data, meta, fn) ->
		fn()
		return @


	read: (key, fn) ->
		fn(null)
		return null


	write: (key, data, dependencies = {}, fn) ->
		if Object.prototype.toString.call(dependencies) == '[object Function]'
			fn = dependencies
			dependencies = {}

		fn()
		return @


	remove: (key, fn) ->
		fn()
		return @


module.exports = DevNullStorage