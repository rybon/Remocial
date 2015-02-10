angular.module('screen.directives', [])


  .directive('player', ['$rootScope', '$window', ($rootScope, $window) ->
    restrict: 'E',
    replace: true,
    template: '<iframe src="//player.vimeo.com/video/17853047?api=1&player_id=player1" id="player1" ng-src="{{playerUrl}}" width="{{playerWidth}}" height="{{playerHeight}}" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>'
    link: (scope, element, attrs) ->
      element.ready ->
        player = $window.$f(element[0])
        player.addEvent 'ready', (id) ->
          sequence = [
                ['paused','paused'],
                ['getCurrentTime','seconds'],
                ['getDuration','duration'],
                # ['getVideoEmbedCode','videoEmbedCode'],
                # ['getVideoWidth','videoWidth'],
                # ['getVideoHeight','videoHeight'],
                # ['getVideoUrl','videoUrl'],
                # ['getColor','color'],
                ['getVolume','volume']
              ]
          data = {}
          cursor = 0
          map = ->
            if cursor isnt sequence.length
              player.api sequence[cursor][0], (value, id) ->
                data[sequence[cursor][1]] = value
                cursor++
                map()
            else
              $rootScope.$broadcast 'f-ready', { 'f-data': data, 'f-id': id }
              data = {}
              cursor = 0
          map()
          $rootScope.$on 'f-refresh', (event) ->
            map()
          player.addEvent 'loadProgress', (data, id) ->
            $rootScope.$broadcast 'f-loadProgress', { 'f-data': data, 'f-id': id }
          player.addEvent 'playProgress', (data, id) ->
            $rootScope.$broadcast 'f-playProgress', { 'f-data': data, 'f-id': id }
          player.addEvent 'play', (id) ->
            $rootScope.$broadcast 'f-play', { 'f-id': id }
          player.addEvent 'pause', (id) ->
            $rootScope.$broadcast 'f-pause', { 'f-id': id }
          player.addEvent 'finish', (id) ->
            $rootScope.$broadcast 'f-finish', { 'f-id': id }
          player.addEvent 'seek', (data, id) ->
            $rootScope.$broadcast 'f-seek', { 'f-data': data, 'f-id': id }
          $rootScope.$on 'f-command', (event, args) ->
            player.api args.command, args.value
            # vimeo play bugfix
            if args.command is 'play'
              delay = (ms, func) -> window.setTimeout func, ms
              delay 0, ->
                player.api args.command, args.value
  ])


  .directive('enter', ['$rootScope', ($rootScope) ->
    scope: {},
    link: (scope, element, attrs) ->
      element.on 'keypress', (e) ->
        if e.which is 13
          $rootScope.fullScreen()
  ])
