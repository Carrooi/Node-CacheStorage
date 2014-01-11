Storage = require './Storage'

class MemoryStorage extends Storage


	async: false

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