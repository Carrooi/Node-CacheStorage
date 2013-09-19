Storage = require './Storage'
Cache = require '../Cache'

class BrowserLocalStorage extends Storage


	@TEST_VALUE = '__--cache-storage--__'


	constructor: ->
		if !BrowserLocalStorage.isSupported()
			throw new Error 'Cache storage: Local storage is not supported'


	@isSupported: ->
		try
			localStorage.setItem(BrowserLocalStorage.TEST_VALUE, BrowserLocalStorage.TEST_VALUE)
			localStorage.getItem(BrowserLocalStorage.TEST_VALUE)
			return true
		catch e
			return false


	getName: ->
		return '__' + @cache.namespace


	getData: ->
		if @data == null
			data = localStorage.getItem(@getName())
			if data == null
				@data = {}
				@meta = {}
			else
				data = JSON.parse(data)
				@data = data.data
				@meta = data.meta
		return @data


	writeData: (@data, @meta) ->
		localStorage.setItem(@getName(), JSON.stringify(
			data: @data
			meta: @meta
		))
		return @


module.exports = BrowserLocalStorage