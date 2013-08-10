(function () {

	var should = require('should');
	var fs = require('fs');

	var Cache = require('../lib/Cache');
	var FileStorage = require('../lib/Storage/FileStorage');

	var path = __dirname + '/data/temp/__test.json';
	var cache;

	describe('Cache', function() {

		beforeEach(function() {
			cache = new Cache(new FileStorage('./data/temp'), 'test');
		});

		afterEach(function() {
			if (fs.existsSync(path)) {
				fs.unlinkSync(path);
			}
		});

		describe('public API', function() {

			it('should save true and load it', function() {
				cache.save('true', true);
				cache.invalidate();
				cache.load('true').should.be.true;
			});

			it('should return null if item not exists', function() {
				should.not.exists(cache.load('true'));
			});

			it('should save true and delete it', function() {
				cache.save('true', true);
				cache.invalidate();
				cache.remove('true');
				should.not.exists(cache.load('true'));
			});

			it('should save true to cache from fallback function in load', function() {
				cache.load('true', function() {
					return true;
				}).should.be.true;
			});

			it('should expire "true" value after file is changed', function() {
				cache.save('true', true, {files: [__dirname + '/data/file']});
				cache.invalidate();
				fs.writeFileSync(__dirname + '/data/file', ' ');
				should.not.exists(cache.load('true'));
			});

			it('should remove all items with tag "article"', function() {
				cache.save('one', 'one', {tags: ['article']});
				cache.save('two', 'two', {tags: ['category']});
				cache.save('three', 'three', {tags: ['article']});
				cache.clean({tags: ['article']});
				cache.invalidate();
				should.not.exists(cache.load('one'));
				cache.load('two').should.be.equal('two');
				should.not.exists(cache.load('three'));
			});

			it('should expire "true" value after 1 second"', function(done) {
				cache.save('true', true, {expire: {seconds: 1}});
				cache.invalidate();
				setTimeout(function() {
					should.not.exists(cache.load('true'));
					done();
				}, 1100);
			});

			it('should expire "true" value after "first" value expire', function() {
				cache.save('first', 'first');
				cache.save('true', true, {items: ['first']});
				cache.invalidate();
				cache.remove('first');
				should.not.exists(cache.load('true'));
			});

			it('should expire all items with priority bellow 50', function() {
				cache.save('one', 'one', {priority: 100});
				cache.save('two', 'two', {priority: 10});
				cache.invalidate();
				cache.clean({priority: 50});
				cache.load('one').should.be.equal('one');
				should.not.exists(cache.load('two'));
			});

			it('should remove all items from cache', function() {
				cache.save('one', 'one');
				cache.save('two', 'two');
				cache.invalidate();
				cache.clean('all');
				should.not.exists(cache.load('one'));
				should.not.exists(cache.load('two'));
			});

		});

	});

})();