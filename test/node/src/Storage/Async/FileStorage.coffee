expect = require('chai').expect
path = require 'path'
async = require 'async'

Cache = require '../../../../../lib/Cache'
FileStorage = require '../../../../../Storage/FileAsyncStorage'

fs = null
cache = null

describe 'FileAsyncStorage', ->

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

		it 'should save true and load it', (done) ->
			cache.save 'true', true, ->
				cache.load 'true', (err, data) ->
					expect(data).to.be.true
					done()

		it 'should return null if item not exists', (done) ->
			cache.load 'true', (err, data) ->
				expect(data).to.be.null
				done()

		it 'should save true and delete it', (done) ->
			cache.save 'true', true, ->
				cache.remove 'true', ->
					cache.load 'true', (err, data) ->
						expect(data).to.be.null
						done()

		it 'should save true to cache from fallback function in load', (done) ->
			cache.load 'true', ->
				return true
			, (err, data) ->
				expect(data).to.be.true
				done()

	describe 'expiration', ->

		beforeEach( ->
			cache = new Cache(new FileStorage('/temp'), 'test')
		)

		afterEach( ->
			if fs.existsSync('/temp/__test.json')
				fs.unlinkSync('/temp/__test.json')
		)

		it 'should expire "true" value after file is changed', (done) ->
			cache.save 'true', true, {files: ['/file']}, ->
				setTimeout( ->
					fs.writeFileSync('/file', '')
					cache.load 'true', (err, data) ->
						expect(data).to.be.null
						done()
				, 100)

		it 'should remove all items with tag "article"', (done) ->
			data = [
				['one', null, ['article']]
				['two', 'two', ['category']]
				['three', null, ['article']]
			]
			async.eachSeries(data, (item, cb) ->
				cache.save item[0], item[0], {tags: item[2]}, -> cb()
			, ->
				cache.clean(tags: ['article'], ->
					async.eachSeries(data, (item, cb) ->
						cache.load item[0], (err, data) ->
							expect(data).to.be.equal(item[1])
							cb()
					, ->
						done()
					)
				)
			)

		it 'should expire "true" value after 1 second"', (done) ->
			cache.save 'true', true, {expire: {seconds: 1}}, ->
				setTimeout( ->
					cache.load 'true', (err, data) ->
						expect(data).to.be.null
						done()
				, 1100)

		it 'should expire "true" value after "first" value expire', (done) ->
			cache.save 'first', 'first', ->
				cache.save 'true', true, {items: ['first']}, ->
					cache.remove 'first', ->
						cache.load 'true', (err, data) ->
							expect(data).to.be.null
							done()

		it 'should expire all items with priority bellow 50', (done) ->
			cache.save 'one', 'one', {priority: 100}, ->
				cache.save 'two', 'two', {priority: 10}, ->
					cache.clean {priority: 50}, ->
						cache.load 'one', (err, data) ->
							expect(data).to.be.equal('one')
							cache.load 'two', (err, data) ->
								expect(data).to.be.null
								done()

		it 'should remove all items from cache', (done) ->
			cache.save 'one', 'one', ->
				cache.save 'two', 'two', ->
					cache.clean 'all', ->
						cache.load 'one', (err, data) ->
							expect(data).to.be.null
							cache.load 'two', (err, data) ->
								expect(data).to.be.null
								done()