/*
  tinker.js 0.0.1
  Copyright (c)  2014-2014 Kevin Malakoff.
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/kmalakoff/tinker
  Dependencies: js-git and Underscore.js.
*/
(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory(require("underscore"));
	else if(typeof define === 'function' && define.amd)
		define(["underscore"], factory);
	else if(typeof exports === 'object')
		exports["Tinker"] = factory(require("underscore"));
	else
		root["Tinker"] = factory(root["_"]);
})(this, function(__WEBPACK_EXTERNAL_MODULE_2__) {
return /******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;
/******/
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			exports: {},
/******/ 			id: moduleId,
/******/ 			loaded: false
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ function(module, exports, __webpack_require__) {

	module.exports = __webpack_require__(1);


/***/ },
/* 1 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  tinker.js 0.0.1
	  Copyright (c) 2013-2014 Kevin Malakoff
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/kmalakoff/tinker
	  Dependencies: js-git and Underscore.js.
	 */
	var Tinker, publish, _;

	_ = __webpack_require__(2);

	module.exports = Tinker = __webpack_require__(3);

	publish = {
	  configure: __webpack_require__(4),
	  Utils: __webpack_require__(5),
	  Queue: __webpack_require__(6),
	  Module: __webpack_require__(7),
	  _: _
	};

	_.extend(Tinker, publish);

	Tinker.modules = {
	  underscore: _
	};


/***/ },
/* 2 */
/***/ function(module, exports, __webpack_require__) {

	module.exports = __WEBPACK_EXTERNAL_MODULE_2__;

/***/ },
/* 3 */
/***/ function(module, exports, __webpack_require__) {

	module.exports = {};


/***/ },
/* 4 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  tinker.js 0.0.1
	  Copyright (c) 2013-2014 Kevin Malakoff
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/kmalakoff/tinker
	  Dependencies: js-git and Underscore.js.
	 */
	var Tinker, _;

	_ = __webpack_require__(2);

	Tinker = __webpack_require__(3);

	module.exports = function(options) {
	  var key, value, _results;
	  if (options == null) {
	    options = {};
	  }
	  _results = [];
	  for (key in options) {
	    value = options[key];
	    _results.push(Tinker[key] = value);
	  }
	  return _results;
	};


/***/ },
/* 5 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  tinker.js 0.0.1
	  Copyright (c) 2013-2014 Kevin Malakoff
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/kmalakoff/tinker
	  Dependencies: js-git and Underscore.js.
	 */
	var Utils, _;

	_ = __webpack_require__(2);

	module.exports = Utils = (function() {
	  function Utils() {}

	  return Utils;

	})();


/***/ },
/* 6 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  tinker.js 0.0.1
	  Copyright (c) 2013-2014 Kevin Malakoff
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/kmalakoff/tinker
	  Dependencies: js-git and Underscore.js.
	 */
	var Queue,
	  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

	module.exports = Queue = (function() {
	  function Queue(parallelism) {
	    this.parallelism = parallelism;
	    this._doneTask = __bind(this._doneTask, this);
	    this.parallelism || (this.parallelism = Infinity);
	    this.tasks = [];
	    this.running_count = 0;
	    this.error = null;
	    this.await_callback = null;
	  }

	  Queue.prototype.defer = function(callback) {
	    this.tasks.push(callback);
	    return this._runTasks();
	  };

	  Queue.prototype.await = function(callback) {
	    if (this.await_callback) {
	      throw new Error("Awaiting callback was added twice: " + callback);
	    }
	    this.await_callback = callback;
	    if (this.error || !(this.tasks.length + this.running_count)) {
	      return this._callAwaiting();
	    }
	  };

	  Queue.prototype._doneTask = function(err) {
	    this.running_count--;
	    this.error || (this.error = err);
	    return this._runTasks();
	  };

	  Queue.prototype._runTasks = function() {
	    var current;
	    if (this.error || !(this.tasks.length + this.running_count)) {
	      return this._callAwaiting();
	    }
	    while (this.running_count < this.parallelism) {
	      if (!this.tasks.length) {
	        return;
	      }
	      current = this.tasks.shift();
	      this.running_count++;
	      current(this._doneTask);
	    }
	  };

	  Queue.prototype._callAwaiting = function() {
	    if (this.await_called || !this.await_callback) {
	      return;
	    }
	    this.await_called = true;
	    return this.await_callback(this.error);
	  };

	  return Queue;

	})();


/***/ },
/* 7 */
/***/ function(module, exports, __webpack_require__) {

	var Module, PROPERTIES, _;

	_ = __webpack_require__(2);

	PROPERTIES = ['name', 'path', 'url', 'package_url'];

	module.exports = Module = (function() {
	  function Module(options) {
	    var key, value, _i, _len, _ref;
	    _ref = _.pick(options, PROPERTIES);
	    for (key in _ref) {
	      value = _ref[key];
	      this[key] = value;
	    }
	    for (_i = 0, _len = PROPERTIES.length; _i < _len; _i++) {
	      key = PROPERTIES[_i];
	      if (!this.hasOwnProperty(key)) {
	        throw new Error("Module missing " + key);
	      }
	    }
	  }

	  return Module;

	})();


/***/ }
/******/ ])
});
