Storage = require './Storage'

redis = require 'redis'
assert = require 'assert'

class RedisStorage extends Storage


	@META_KEY: '__redis__storage__meta__key__'


	client: null


	constructor: ->
		if typeof window != 'undefined'
			throw new Error 'FileStorage: Can not use this storage in browser'

		@client = redis.createClient()


	selectDatabase: (database, fn) ->
		@client.SELECT database, fn


	_read: (name, fn, defaults = null) ->
		@client.GET name, (err, data) =>
			if err
				fn(err, null)
			else if data == null
				if defaults == null
					fn(null, null)
				else
					@_write name, defaults, (err) =>
						if err
							fn(err, null)
						else
							@_read name, (err, data) ->
								if err
									fn(err, null)
								else
									fn(null, data)
			else
				fn(null, JSON.parse(data))


	_write: (name, data, fn) ->
		@client.SET name, JSON.stringify(data), (err) ->
			if err
				fn(err)
			else
				fn(null)


	_remove: (name, fn) ->
		@client.DEL name, fn


	_removeAll: (fn) ->
		@client.FLUSHDB(fn)


	getMeta: (fn) ->
		@_read RedisStorage.META_KEY, (err, data) ->
			fn(data)
		, {}



	read: (key, fn) ->
		@_read key, (err, data) =>
			if data == null
				fn(null)
			else
				@findMeta(key, (meta) =>
					@verify(meta, (state) =>
						if state
							fn(data)
						else
							@remove(key, ->
								fn(null)
							)
					)
				)


	write: (key, data, dependencies = {}, fn) ->
		@_write key, data, (err) =>
			@getMeta( (meta) =>
				meta[key] = dependencies
				@_write RedisStorage.META_KEY, meta, (err) ->
					fn()
			)


	remove: (key, fn) ->
		@getMeta( (meta) =>
			if typeof meta[key] != 'undefined'
				delete meta[key]

			@_remove key, (err) =>
				if err
					fn(err)
				else
					@_write RedisStorage.META_KEY, meta, (err) ->
						if err
							fn(err)
						else
							fn(null)
		)


	removeAll: (fn) ->
		@_removeAll(fn)


module.exports = RedisStorage