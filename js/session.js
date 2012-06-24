// Generated by CoffeeScript 1.3.3
var Session,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

Session = (function(_super) {

  __extends(Session, _super);

  function Session() {
    var event, i, run, view, viewNames, _i, _j, _len, _len1, _ref, _ref1, _ref2;
    viewNames = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    this.viewNames = viewNames;
    Session.__super__.constructor.call(this, this.localStorage.data);
    this.save();
    _ref = this.viewNames;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      view = _ref[_i];
      _ref1 = this.viewEvents;
      for (event in _ref1) {
        run = _ref1[event];
        window[view].on(event, run, this);
      }
    }
    this.view = window[this.get('view')];
    if (!(this.view != null)) {
      view = this.viewNames[0];
      this.sync.apply(this, [
        'create', view, {
          id: 'view'
        }
      ]);
      this.set('view', this.view = window[view]);
    }
    this.views = [];
    _ref2 = this.viewNames;
    for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
      i = _ref2[_j];
      this.views.push(window[i]);
    }
    this.model = this.get('model');
    if (this.model) {
      this.view.restore(this.view.collection.get(this.model.id));
    } else {
      this.view.restore();
    }
  }

  Session.prototype.viewEvents = {
    'render': function(view, model) {
      var viewName;
      viewName = this.viewNames[this.views.indexOf(view)];
      this.sync.apply(this, [
        'update', viewName, {
          id: 'view'
        }
      ]);
      if (model != null) {
        return this.sync.apply(this, [
          'update', model, {
            id: 'model'
          }
        ]);
      } else {
        return this.sync.apply(this, [
          'delete', model, {
            id: 'model'
          }
        ]);
      }
    }
  };

  Session.prototype.localStorage = new Store('loops-session');

  Session.prototype.sync = Backbone.sync.store;

  Session.prototype.save = function() {
    return this.localStorage.save();
  };

  return Session;

})(Backbone.Model);