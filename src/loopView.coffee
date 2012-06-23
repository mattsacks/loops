class LoopView extends Backbone.View
  constructor: (options = {}) -> 
    modoptions = _.extend {}, @defaults, options
    super(modoptions)
    @gather()

  defaults:
    templateId: 'loop-detail-template'

  el: '#loop'

  gather: ->
    @template = Hogan.compile($("##{@options.templateId}").html())
    @element  = this.$el

  render: (template = @template, @model) ->
    @element.html(template.render(model))
    @trigger('render', this, model)

  restore: (@model) ->
    @trigger('restore', @model)
