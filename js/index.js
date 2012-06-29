// Generated by CoffeeScript 1.3.3
var Browser;

(function(moment) {
  return moment.fn.week = function(week) {
    var doy, mod;
    mod = moment().date(1).month(0).day() % 7;
    if (!(week != null)) {
      return Math.floor((+this.format("DDD") + mod) / 7);
    }
    doy = (this.day() - mod) + ((week - 1) * 7);
    return this.date(1).month(0).add('days', doy);
  };
})(moment);

moment;


(function(_) {
  return _.mixin({
    copy: function(properties) {
      var key, obj, value;
      obj = {};
      for (key in properties) {
        value = properties[key];
        obj[key] = Array.isArray(value) ? value.slice() : value;
      }
      return obj;
    }
  });
})(_);

_;


Browser = (function() {

  function Browser() {
    this.lUA = navigator.userAgent.toLowerCase();
    this.platform = navigator.platform.toLowerCase();
    this.UA = this.lUA.match(/(opera|ie|firefox|chrome|version)[\s\/:]([\w\d\.]+)?.*?(safari|version[\s\/:]([\w\d\.]+)|$)/) || [null, 'unknown', 0];
    this.mode = this.UA[1] === 'ie' && document.documentMode;
    this.name = this.UA[1] === 'version' ? this.UA[3] : this.UA[1];
    this.version = this.mode || parseFloat(this.UA[1] === 'opera' && this.UA[4] ? this.UA[4] : this.UA[2]);
    this.Platform = {
      name: this.lUA.match(/ip(?:ad|od|hone)/) ? 'ios' : (this.lUA.match(/(?:webos|android)/) || this.platform.match(/mac|win|linux/) || ['other'])[0]
    };
    this.Features = {
      xpath: !!document.evaluate,
      air: !!window.runtime,
      query: !!document.querySelector,
      json: !!window.JSON
    };
  }

  return Browser;

})();

$(function() {
  window.browser = new Browser();
  window.platform = browser.Platform.name;
  window.mobile = platform === 'ios' || platform === 'android' ? true : false;
  window.loops = new Loops();
  window.loopView = new LoopView({
    collection: loops
  });
  window.loopsView = new LoopsView({
    collection: loops,
    subView: loopView
  });
  window.session = new Session('loopsView', 'loopView');
  return $(document.body).addClass('show');
});
