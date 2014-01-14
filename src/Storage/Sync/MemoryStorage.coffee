Storage = require './Storage'

class MemoryStorage extends Storage


	data: null

	meta: null


	getData: ->
		if @data == null
			@data = {}

		return @data


	getMeta: ->
		if @meta == null
			@meta = {}

		return @meta


	writeData: (@data, @meta) ->
		return @


module.exports = MemoryStorage