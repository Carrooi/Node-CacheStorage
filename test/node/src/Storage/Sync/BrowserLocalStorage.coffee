expect = require('chai').expect

Cache = require '../../../../../lib/Cache'
BrowserLocalStorage = require '../../../../../Storage/BrowserLocalSyncStorage'

describe 'BrowserLocalSyncStorage', ->

	describe '#constructor()', ->
		it 'should throws an error if local storage is not supported', ->
			expect( -> new BrowserLocalStorage ).to.throw(Error)