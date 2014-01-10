expect = require('chai').expect

Cache = require '../../../lib/Cache'
DevNullStorage = require '../../../lib/Storage/DevNullStorage'

cache = null

describe 'DevNullStorage', ->

	describe 'saving/loading', ->

		beforeEach( ->
			cache = new Cache(new DevNullStorage, 'test')
		)

		it 'should not save true', ->
			cache.save 'true', true
			expect(cache.load 'true').to.be.null

		it 'should always return null', ->
			expect(cache.load 'true').to.be.null

		it 'should not save true and try to delete it', ->
			cache.save 'true', true
			cache.remove 'true'
			expect(cache.load 'true').to.be.null

		it 'should not save true to cache from fallback function in load', ->
			val = cache.load 'true', -> return true
			expect(val).to.be.true
			expect(cache.load 'true').to.be.null