expect = require('chai').expect
path = require 'path'

Cache = require '../../../../../lib/Cache'
FileStorage = require '../../../../../Storage/FileSyncStorage'

fs = null
cache = null

describe 'FileSyncStorage', ->

	beforeEach( ->
		fs = Cache.mockFs(
			'temp': {}
			'file': ''
		)
	)

	afterEach( ->
		Cache.restoreFs()
	)

	describe '#constructor()', ->

		it 'should throw an error if path does not exists', ->
			expect( -> new FileStorage('./unknown/path') ).to.throw()

		it 'should throw an error if path is not directory', ->
			expect( -> new FileStorage('/file') ).to.throw()

	describe 'saving/loading', ->

		beforeEach( ->
			cache = new Cache(new FileStorage('/temp'), 'test')
		)

		afterEach( ->
			if fs.existsSync('/temp/__test.json')
				fs.unlinkSync('/temp/__test.json')
		)

		it 'should save true and load it', ->
			cache.save 'true', true
			expect(cache.load 'true').to.be.true

		it 'should return null if item not exists', ->
			expect(cache.load 'true').to.be.null

		it 'should save true and delete it', ->
			cache.save 'true', true
			cache.remove 'true'
			expect(cache.load 'true').to.be.null

		it 'should save true to cache from fallback function in load', ->
			val = cache.load 'true', -> return true
			expect(val).to.be.true

	describe 'expiration', ->

		beforeEach( ->
			cache = new Cache(new FileStorage('/temp'), 'test')
		)

		afterEach( ->
			if fs.existsSync('/temp/__test.json')
				fs.unlinkSync('/temp/__test.json')
		)

		it 'should expire "true" value after file is changed', (done) ->
			cache.save 'true', true, {files: ['/file']}
			setTimeout( ->
				fs.writeFileSync('/file', '')
				expect(cache.load 'true').to.be.null
				done()
			, 100)

		it 'should remove all items with tag "article"', ->
			cache.save 'one', 'one', {tags: ['article']}
			cache.save 'two', 'two', {tags: ['category']}
			cache.save 'three', 'three', {tags: ['article']}
			cache.clean tags: ['article']
			expect(cache.load 'one').to.be.null
			expect(cache.load 'two').to.be.equal 'two'
			expect(cache.load 'three').to.be.null

		it 'should expire "true" value after 1 second"', (done) ->
			cache.save 'true', true, {expire: {seconds: 1}}
			setTimeout( ->
				expect(cache.load 'true').to.be.null
				done()
			, 1100)

		it 'should expire "true" value after "first" value expire', ->
			cache.save 'first', 'first'
			cache.save 'true', true, {items: ['first']}
			cache.remove 'first'
			expect(cache.load 'true').to.be.null

		it 'should expire all items with priority bellow 50', ->
			cache.save 'one', 'one', {priority: 100}
			cache.save 'two', 'two', {priority: 10}
			cache.clean {priority: 50}
			expect(cache.load 'one').to.be.equal('one')
			expect(cache.load 'two').to.be.null

		it 'should remove all items from cache', ->
			cache.save 'one', 'one'
			cache.save 'two', 'two'
			cache.clean 'all'
			expect(cache.load 'one').to.be.null
			expect(cache.load 'two').to.be.null