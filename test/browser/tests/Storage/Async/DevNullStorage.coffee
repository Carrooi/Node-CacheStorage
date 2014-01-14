Cache = require 'cache-storage'
DevNullStorage = require 'cache-storage/Storage/DevNullAsyncStorage'

cache = null

describe 'DevNullAsyncStorage', ->

	describe 'saving/loading', ->

		beforeEach( ->
			cache = new Cache(new DevNullStorage, 'test')
		)

		it 'should not save true', (done) ->
			cache.save 'true', true, ->
				cache.load 'true', (err, data) ->
					expect(data).to.be.null
					done()

		it 'should always return null', (done) ->
			cache.load 'true', (err, data) ->
				expect(data).to.be.null
				done()

		it 'should not save true and try to delete it', (done) ->
			cache.save 'true', true, ->
				cache.remove 'true', ->
					cache.load 'true', (err, data) ->
						expect(data).to.be.null
						done()

		it 'should not save true to cache from fallback function in load', (done) ->
			cache.load 'true', ->
				return true
			, (err, data) ->
				expect(data).to.be.true
				cache.load 'true', (err, data) ->
					expect(data).to.be.null
					done()