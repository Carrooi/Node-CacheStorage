Storage = require './Storage'

class DevNullStorage extends Storage


	getData: (fn) ->
		fn(null, {})


	getMeta: (fn) ->
		fn(null, {})


	writeData: (data, meta, fn) ->
		fn(null)


	read: (key, fn) ->
		fn(null, null)


	write: (key, data, dependencies = {}, fn) ->
		if Object.prototype.toString.call(dependencies) == '[object Function]'
			fn = dependencies
			dependencies = {}

		fn(null)


	remove: (key, fn) ->
		fn(null)


module.exports = DevNullStorage