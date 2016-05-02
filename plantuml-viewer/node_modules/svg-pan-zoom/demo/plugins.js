function SvgPanZoomPluginUnique() {

}

function svgPanZoomPluginUnique(api) {
  return new SvgPanZoomPluginUnique(api)
}

svgPanZoom.register('unique', svgPanZoomPluginUnique)

function svgPanZoomPluginShared(api) {

  // Listen for before event as this plugin will be detatched at 'plugin:remove' event
  api.on('before:plugin:remove', function(ev) {
    console.log('before:plugin:remove', ev)
  })
  api.on('after:plugin:remove', function(ev) {
    console.log('after:plugin:remove', ev)
  })

  api.on('panzoom', function(data) {
    console.log('panzoom', data.namespace, data)
  })

  api.on('pointer:move', function(data) {
    console.log('pointer:move', data.namespace, data)
    data.originalEvent.preventDefault()
  })

  api.on('render', function(ev) {
    console.log('render', ev)

    // Will make panning symetric
    // ev.data.x = ev.data.y

    // Makes everything 4 times smaller
    // ev.data.zoom /= 4

    // Once in a while swap x and y
    // Math.random() < 0.1 && (ev.data.x = ev.data.y + (ev.data.y=ev.data.x, 0))
  })

  // TODO do we actually need this?
  return {}
}

svgPanZoom.register('shared', svgPanZoomPluginShared)

function svgPanZoomPluginTweenLinear(api) {
  var fromX = 0
    , fromY = 0
    , toX = 0
    , toY = 0
    , timeLeft = 0
    , lastTime = 0
    , tweenTime = 300

  function step() {
    var timeDiff = Math.min(timeLeft, Date.now() - lastTime)
      , diff = timeDiff / timeLeft

    timeLeft -= timeDiff
    fromX = fromX + (toX - fromX) * diff
    fromY = fromY + (toY - fromY) * diff

    api.pan({
      x: fromX
    , y: fromY
    })
  }


  api.on('panzoom', function(ev) {
    if (ev.namespace === '__user') {
      ev.stopPropagation()

      fromX = api.getPan().x
      fromY = api.getPan().y
      toX = ev.data.x
      toY = ev.data.y
      timeLeft = tweenTime
      lastTime = Date.now() - 33
      step()
    }
  })

  api.on('after:render', function() {
    if (timeLeft > 0.1) {
      step()
    }
  })
}

// svgPanZoom.register('tween-linear', svgPanZoomPluginTweenLinear)

// TODO test how removing works

// instance.addPlugin(pluginName);
// instance.removePlugin(pluginName);
