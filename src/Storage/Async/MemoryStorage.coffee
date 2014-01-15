Storage = require './Storage'

class MemoryStorage extends Storage


	data: null

	meta: null


	getData: (fn) ->
		if @data == null
			@data = {}

		fn(null, @data)


	getMeta: (fn) ->
		if @meta == null
			@meta = {}

		fn(null, @meta)


	writeData: (@data, @meta, fn) ->
		fn(null)


module.exports = MemoryStorage