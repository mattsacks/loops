// Generated by CoffeeScript 1.3.3
var LoopView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

LoopView = (function(_super) {

  __extends(LoopView, _super);

  function LoopView(options) {
    var modoptions;
    if (options == null) {
      options = {};
    }
    modoptions = _.extend({}, this.defaults, options);
    LoopView.__super__.constructor.call(this, modoptions);
    this.gather();
    this.attach();
  }

  LoopView.prototype.defaults = {
    loopTemplate: $('#loop-detail-template').html(),
    menuTemplate: $('#loop-menu-template').html()
  };

  LoopView.prototype.el = '#loop';

  LoopView.prototype.events = {};

  LoopView.prototype.gather = function() {
    this.templates = {
      loop: this.options.loopTemplate,
      menu: this.options.menuTemplate
    };
    this.element = this.$el;
    this.els = {
      "delete": $('#delete'),
      menu: $('#loop-menu'),
      buttons: $('#loop-buttons'),
      amountSpace: $('#amount-space')
    };
    return this.expandedConfig = {
      'day': ['today', 'hours', 'days'],
      'week': ['thisWeek', 'weeks'],
      'month': ['months']
    };
  };

  LoopView.prototype.attach = function() {
    var run, selector, thiz, _ref,
      _this = this;
    thiz = this;
    _.bindAll(this, 'edit', 'mod');
    this.clickEvent = window.mobile === true ? "tap" : "click";
    this.buttonEvents = {
      '#subtract': {
        method: "mod",
        args: ["amount", -1]
      },
      '#add': {
        method: "mod",
        args: ["amount", 1]
      }
    };
    _ref = this.buttonEvents;
    for (selector in _ref) {
      run = _ref[selector];
      this.els.buttons.on(this.clickEvent, selector, _.bind.apply(_, [this[run.method], this].concat(__slice.call(run.args))));
    }
    this.els.amountSpace.on(this.clickEvent, _.bind(this.edit, this));
    this.element.on(this.clickEvent, '.view', _.bind(this.viewChange, this));
    this.element.on(this.clickEvent, '.current', function(e) {
      var index, range;
      index = thiz.els.currents.indexOf(this);
      range = _.keys(thiz.expandedConfig)[index];
      thiz.model.set({
        range: range,
        period: thiz.expandedConfig[range][0]
      });
      return thiz.render();
    });
    this.els["delete"].on(this.clickEvent, _.bind(this.menu, this, 'delete', ''));
    return $(document).on(this.clickEvent, "body.menu", function(e) {
      var $body, el, id, operation, _base, _name;
      el = $(e.target);
      id = el.attr('id');
      $body = $(document.body);
      if (!$body.hasClass('viewing')) {
        $body.removeClass(_this.menuClass);
      } else if ($body.hasClass('mod')) {
        '';

      } else if (el.parent().attr('id') !== 'menu-buttons' && !el.hasClass('button')) {
        $body.removeClass(_this.menuClass);
      }
      if (el.is('.loop-item')) {
        return;
      }
      operation = $body.attr('class').match(/menu-(\w+)/)[1];
      return typeof (_base = _this.helpers[operation])[_name = "on" + id] === "function" ? _base[_name]() : void 0;
    });
  };

  LoopView.prototype.amountTemplate = function() {
    var amount;
    amount = this.model.get('amount');
    return "<input id='amount-template' type='tel' placeholder='" + amount + "' />";
  };

  LoopView.prototype.edit = function(prop) {
    var blurSave, input, template,
      _this = this;
    if ($('amount-template').length !== 0) {
      return;
    }
    template = this.amountTemplate();
    this.els.amount.html(template);
    input = this.els.amount.find('input');
    blurSave = function() {
      var amount, val;
      val = input.attr('value');
      amount = _this.model.get('amount');
      val = val === '' ? amount : +val;
      input.off('blur', blurSave);
      if (/^\d+$/.test(val) && val !== amount) {
        _this.model.set('amount', val);
        _this.els.amount.html(val);
      } else {
        _this.els.amount.html(amount);
      }
      return _this.mod('amount', 0);
    };
    input.on('blur', function() {
      return blurSave();
    });
    return input.focus();
  };

  LoopView.prototype.mod = function(prop, amount) {
    var val;
    val = (this.model.get(prop) || 0) + amount;
    if (val <= 0) {
      val = 0;
    }
    this.els[prop].html(val);
    this.model.set(prop, val);
    if (val <= 0) {
      return $(document.body).removeClass(this.menuClass || '');
    } else {
      return this.menu('save', 'mod');
    }
  };

  LoopView.prototype.menu = function(operation, menu) {
    var html;
    if (menu == null) {
      menu = '';
    }
    this.menuClass = "menu menu-" + operation + " " + menu;
    html = Mustache.render(this.templates.menu, this.helpers[operation]);
    this.els.menu.html(html);
    return $(document.body).addClass(this.menuClass);
  };

  LoopView.prototype["delete"] = function() {
    var $parent, els, properRemove;
    $parent = $("#" + (this.model.get('id')));
    properRemove = function(e) {
      var $this;
      $this = $(this);
      if ($this.is('li')) {
        $this.remove();
      } else {
        $this.html('');
      }
      return $this.off(e.type, properRemove);
    };
    els = $parent.add(this.element);
    els.on({
      'webkitTransitionEnd': properRemove,
      'transitionEnd': properRemove
    });
    loopsView.view({
      target: $parent
    });
    els.addClass('delete');
    return this.collection.remove(this.model.get('id'));
  };

  LoopView.prototype.save = function() {
    var data, point;
    point = {
      val: this.model.get('amount'),
      time: +new Date()
    };
    data = this.model.get('data');
    data[this.currentPoint || point.time] = point.val;
    this.model.set('data', data);
    this.collection.save();
    this.cancel();
    return this.render();
  };

  LoopView.prototype.cancel = function() {
    this.model.set('amount', 0);
    this.els.amount.html(0);
    $(document.body).removeClass(this.menuClass);
    return this.menuClass = '';
  };

  LoopView.prototype.viewChange = function(e) {
    var $el, view;
    $el = $(e.target);
    view = $el.data('range');
    this.element.find('.view.active').removeClass('active');
    $el.addClass('active');
    return this.trigger('viewChange', this.model.set('period', view));
  };

  LoopView.prototype.getModelData = function() {
    return this.latestModelData = this.model.collect();
  };

  LoopView.prototype.getCurrentData = function() {
    var current, data, interesting, todaysData;
    data = this.latestModelData || this.getModelData();
    interesting = [data.weeks, data.months];
    current = _.map(interesting, function(x) {
      return _.last(x);
    });
    todaysData = {
      sum: _.reduce(data.today, (function(a, b) {
        return a + b.sum;
      }), 0),
      headline: 'Today',
      by: 'today'
    };
    data.thisWeek = this.model.migrate({
      thisWeek: function(p) {
        return moment(+p.time).day();
      }
    }, {
      thisWeek: {
        by: 'This Week',
        points: [],
        sum: 0
      }
    }, {
      thisWeek: _.range(7)
    }, _.last(data.weeks).points).thisWeek;
    return _.flatten([todaysData, current]);
  };

  LoopView.prototype.render = function(template, model) {
    if (template == null) {
      template = this.templates.loop;
    }
    this.model = model != null ? model : this.model;
    if (!(this.helpers != null)) {
      this.helpers = this.defineHelpers();
    }
    if (this.model.get('amount') !== 0) {
      this.menu('save', 'mod');
    }
    this.latestTemplateData = _.extend({
      modelData: this.getModelData(),
      currentData: this.getCurrentData()
    }, this.helpers, this.model.attributes);
    this.element.html(Mustache.render(template, this.latestTemplateData));
    this.postRender();
    return this.trigger('render', this, {
      model: this.model
    });
  };

  LoopView.prototype.postRender = function() {
    return _.extend(this.els, {
      amount: this.element.find('#amount'),
      currents: this.element.find('.current')
    });
  };

  LoopView.prototype.restore = function(model, expandedDetail) {
    this.model = model;
    this.expandedDetail = expandedDetail;
    return this.trigger('restore', this.model);
  };

  LoopView.prototype.defineHelpers = function() {
    var thiz,
      _this = this;
    thiz = this;
    return {
      "delete": {
        oncancel: function() {
          return $(document.body).removeClass(_this.menuClass);
        },
        cancel: "Cancel",
        onsave: _.bind(this["delete"], this),
        save: "Delete"
      },
      save: {
        oncancel: _.bind(this.cancel, this),
        cancel: "Cancel",
        onsave: _.bind(this.save, this),
        save: "Save"
      },
      currents: function() {
        var collection, _i, _len, _ref;
        _ref = this.currentData;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          collection = _ref[_i];
          collection.headline || (collection.headline = (function() {
            switch (collection.by) {
              case 'by week':
                return 'This Week';
              case 'by month':
                return 'This Month';
            }
          })());
        }
        return this.currentData;
      },
      active: function() {
        var period, range, val;
        range = thiz.model.get('range');
        period = thiz.model.get('period');
        val = /[\w+\s\w+]$/.test('' + this) ? period === this.concat() : range === 'day' && this.by === 'today' ? true : range === this.by.split(' ')[1];
        if (val === true) {
          return 'active';
        } else {
          return '';
        }
      },
      amount: function() {
        return _this.model.attributes.amount || 0;
      },
      views: function() {
        var views;
        views = _this.expandedConfig[_this.model.get('range')];
        if (views.length === 1) {
          return [];
        } else {
          return views;
        }
      },
      rangeLabel: function() {
        return thiz.latestModelData['' + this][0].by;
      }
    };
  };

  return LoopView;

})(Backbone.View);
