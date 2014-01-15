[![NPM version](https://badge.fury.io/js/cache-storage.png)](http://badge.fury.io/js/cache-storage)
[![Dependency Status](https://gemnasium.com/sakren/node-cache-storage.png)](https://gemnasium.com/sakren/node-cache-storage)
[![Build Status](https://travis-ci.org/sakren/node-cache-storage.png?branch=master)](https://travis-ci.org/sakren/node-cache-storage)

# cache-storage

Advanced cache storage inspired by cache in [Nette framework](http://doc.nette.org/en/caching).

Can be also used in browser for example with [simq](https://npmjs.org/package/simq).

## Installing

```
$ npm install cache-storage
```

Required node version: >= 0.9

## Creating cache

```
var Cache = require('cache-storage');
var FileStorage = require('cache-storage/Storage/FileSyncStorage');

var cache = new Cache(new FileStorage('./temp'), 'namespace');
```

You have to set storage which you want to use (their list below) and namespace for cache, because you can use
more than one independent caches.

## Available storages

### Synchronous storages

* `cache-storage/Storage/FileSyncStorage`: saving data into json files
* `cache-storage/Storage/BrowserLocalSyncStorage`: saving data into HTML5 local storage
* `cache-storage/Storage/DevNullSyncStorage`: does not save anything and load always null
* `cache-storage/Storage/MemorySyncStorage`: saving data just into storage's class properties

### Asynchronouse storages

* `cache-storage/Storage/FileAsyncStorage`
* `cache-storage/Storage/DevNullAsyncStorage`
* `cache-storage/Storage/MemoryAsyncStorage`
* `cache-storage/Storage/RedisAsyncStorage`: uses [redis](https://github.com/mranney/node_redis) package

More storages will be added in future.

### Only node storages

* `cache-storage/Storage/FileSyncStorage`
* `cache-storage/Storage/FileAsyncStorage`
* `cache-storage/Storage/RedisAsyncStorage`

### Only browser storages

* `cache-storage/Storage/BrowserLocalSyncStorage`

### Redis storage

This storage exposes some variables from original package ([redis](https://github.com/mranney/node_redis)).

```
cache.storage.selectDatabase(3, function(err) {
	console.log('changed database');
});
cache.storage.client;		// original client object from redis module
```

## Loading & saving

### Synchronous

```
var data = cache.load('some_data');

if (data === null) {
	// let's save data to cache
	data = cache.save('some_data', 'some value of some_data');
}

console.log(data);		// output: some value of some_data
```

There is also other more simple way to save data to cache if they are not in cache already.

```
var data = cache.load('some_data', function() {
	return 'some value of some_data';
});
```

When no data were found, then fallback anonymous function is called and data from return statement are used.
Cache.save function always return given data.

### Asynchronous

```
cache.load('some_data', function(err, data) {
	if (data === null) {
		cache.save('some_data', 'some value of some_data', function(err, savedData) {
			console.log(savedData);			// output: some value of some_data
		});
	}
});
```

or with fallback:
```
cache.load('some_data', function() {
	return 'some value of some_data';
}, function(data) {
	console.log(data);		// output: some value of some_data
});
```

## Removing

### Synchronous

```
cache.remove('some_data');
```

or:
```
cache.save('some_data', null);
```

### Asynchronous

```
cache.remove('some_data', function(err) {
	console.log('removed some_data');
});
```

## Expiration

You can set some conditions and information for every data which will be used for auto expiration or for your manual
expiration.

```
cache.save('some_data', 'some value of some_data', {
	files: ['./images.txt', './info.txt'],		// expiration by files
	tags: ['image', 'article'],					// tags for manual expiration
	expire: '2015-12-24 18:00',					// expire data in given date (other examples below)
	items: ['some_other_data'],					// expire if other data in cache expires
	priority: 50								// example below
});
```

### Expiration by files

If you set files to save function, then that item will expire when some of given files is changed.

This type of expiration can be used also in browser, but only with [simq](https://npmjs.org/package/simq) and with allowed
option `filesStats`. See at documentation of [simq](https://npmjs.org/package/simq).

**Second argument in `clean` method is callback with possible error, this is used just for asynchronous storages.**

### Expiration by tags

```
cache.clean({
	tags: ['image']
});
```

Now every item in cache with tag image will be removed.

### Expiration by date

There are two ways to expire data by date. First way is to set exact date in YYYY-MM-DD HH:mm format. Second way is to
set literal object with information about adding date to actual date.

```
cache.save('some_data', 'some value of some_data', {
	expire: {days: 1}
});
```

Now some_data will expire tomorrow. You can see full documentation in moment.js [documentation](http://momentjs.com/docs/#/manipulating/add/).

### Items expiration

Every cache item can also depend on other cached items. If some of these other items is invalidated, then also this main
is invalidated.

### Expiration by priority

```
cache.clean({
	priority: 100
});
```

All items with priority 100 or below will expire.

## Removing all in namespace

```
cache.clean(Cache.ALL);		// or cache.clean('all');
```

## Tests

```
$ npm test
```

## Changelog

* 2.0.0
	+ Support for asynchronous storages
	+ Appended `Sync` to old storages' names (original names are deprecated)
	+ Added RedisAsyncStorage, FileAsyncStorage, MemoryAsyncStorage and DevNullAsyncStorage
	+ Many optimizations
	+ Added many tests
	+ Using [fs-mock](https://github.com/sakren/node-fs-mock) for file system
	+ Updated dependencies
	+ Better documentation

* 1.4.1
	+ Can not use some js reserved words

* 1.4.0
	+ Bug with tests
	+ Added support for invalidating cache in browser by files (only with [simq](https://npmjs.org/package/simq))

* 1.3.0
	+ Added DevNullStorage
	+ Added MemoryStorage
	+ FileStorage throws an error on browser
	+ Refactoring storages

* 1.2.4
	+ Rewritten tests
	+ Added tests for browser
	+ Refactoring storages
	+ Bad encoding in FileStorage

* 1.2.3
	+ Shortcut for base Storage class

* 1.2.2
	+ Cache throw error if storage is not instance of Storage class

* 1.2.1
	+ FileStorage throw error if path does not exists or if it is a directory

+ 1.2.0
	+ Bugs in dependencies parser
	+ Written some mocha tests
	+ Added changelog

+ 1.1.2
	+ Added MIT license

* 1.1.1
	+ Renamed repository (cache-storage => node-cache-storage)

* 1.1.0
	+ Added support for HTML5 local storage

* 1.0.2
	+ Removed dependency on crypto

* 1.0.1
	+ Removed hard dependencies on fs and path
	+ Trying other hash methods usable in browser


* 1.0.0
	+ Initial version