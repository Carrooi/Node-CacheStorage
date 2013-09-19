Storage = require './Storage'

class MemoryStorage extends Storage


	getData: ->
		if @data == null
			@data = {}
			@meta = {}

		return @data


	writeData: (@data, @meta) ->
		return @


module.exports = MemoryStorage