expect = require('chai').expect

Cache = require '../../../lib/Cache'
BrowserLocalStorage = require '../../../lib/Storage/BrowserLocalStorage'

describe 'BrowserLocalStorage', ->

	describe '#constructor()', ->
		it 'should throws an error if local storage is not supported', ->
			expect( -> new BrowserLocalStorage ).to.throw(Error)