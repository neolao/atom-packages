;(function(){
  function PluginPanZoom(api) {
    this.api = api

  }


  function pluginPanZoom(api) {
    return new SvgPanZoomPluginUnique(api)
  }

  svgPanZoom.register('panzoom', pluginPanZoom)
})();
