Storage = require './Storage'
Cache = require '../../Cache'

class BrowserLocalStorage extends Storage


	@TEST_VALUE = '__--cache-storage--__'


	allData: null

	data: null

	meta: null


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


	loadData: ->
		if @allData == null
			data = localStorage.getItem(@getName())
			if data == null
				@allData = {data: {}, meta: {}}
			else
				@allData = JSON.parse(data)

		return @allData


	getData: ->
		if @data == null
			@data = @loadData().data

		return @data


	getMeta: ->
		if @meta == null
			@meta = @loadData().meta

		return @meta


	writeData: (@data, @meta) ->
		localStorage.setItem(@getName(), JSON.stringify(
			data: @data
			meta: @meta
		))


module.exports = BrowserLocalStorage