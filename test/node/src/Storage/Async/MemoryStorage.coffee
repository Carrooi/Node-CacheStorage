expect = require('chai').expect
path = require 'path'

fs = null

Cache = require '../../../../../lib/Cache'
MemoryStorage = require '../../../../../Storage/MemoryAsyncStorage'

cache = null

describe 'MemoryAsyncStorage', ->

	beforeEach( ->
		fs = Cache.mockFs(
			'temp': {}
			'file': ''
		)
		cache = new Cache(new MemoryStorage, 'test')
	)

	afterEach( ->
		Cache.restoreFs()
	)

	describe 'saving/loading', ->

		it 'should save true and load it', (done) ->
			cache.save 'true', true, ->
				cache.load 'true', (data) ->
					expect(data).to.be.true
					done()

		it 'should return null if item not exists', (done) ->
			cache.load 'true', (data) ->
				expect(data).to.be.null
				done()

		it 'should save true and delete it', (done) ->
			cache.save 'true', true, ->
				cache.remove 'true', ->
					cache.load 'true', (data) ->
						expect(data).to.be.null
						done()

		it 'should save true to cache from fallback function in load', (done) ->
			cache.load 'true', ->
				return true
			, (data) ->
				expect(data).to.be.true
				done()

	describe 'expiration', ->

		it.skip 'should expire "true" value after file is changed', (done) ->
			cache.save 'true', true, {files: ['/file']}, ->
				setTimeout( ->
					fs.writeFileSync('/file', '')
					cache.load 'true', (data) ->
						expect(data).to.be.null
						done()
				, 100)


		it.skip 'should remove all items with tag "article"', ->
			cache.save 'one', 'one', {tags: ['article']}
			cache.save 'two', 'two', {tags: ['category']}
			cache.save 'three', 'three', {tags: ['article']}
			cache.clean tags: ['article']
			expect(cache.load 'one').to.be.null
			expect(cache.load 'two').to.be.equal 'two'
			expect(cache.load 'three').to.be.null

		it.skip 'should expire "true" value after 1 second"', (done) ->
			cache.save 'true', true, {expire: {seconds: 1}}
			setTimeout( ->
				expect(cache.load 'true').to.be.null
				done()
			, 1100)

		it.skip 'should expire "true" value after "first" value expire', ->
			cache.save 'first', 'first'
			cache.save 'true', true, {items: ['first']}
			cache.remove 'first'
			expect(cache.load 'true').to.be.null

		it.skip 'should expire all items with priority bellow 50', ->
			cache.save 'one', 'one', {priority: 100}
			cache.save 'two', 'two', {priority: 10}
			cache.clean {priority: 50}
			expect(cache.load 'one').to.be.equal('one')
			expect(cache.load 'two').to.be.null

		it.skip 'should remove all items from cache', ->
			cache.save 'one', 'one'
			cache.save 'two', 'two'
			cache.clean 'all'
			expect(cache.load 'one').to.be.null
			expect(cache.load 'two').to.be.null