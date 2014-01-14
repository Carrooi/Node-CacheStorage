Storage = require './Storage'

class MemoryStorage extends Storage


	data: null

	meta: null


	getData: (fn) ->
		if @data == null
			@data = {}

		fn(@data)
		return null


	getMeta: (fn) ->
		if @meta == null
			@meta = {}

		fn(@meta)
		return null


	writeData: (@data, @meta, fn) ->
		fn()
		return @


module.exports = MemoryStorage