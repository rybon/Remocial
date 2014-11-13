angular.module('screen.controllers', [])


  .controller('ScreenController', ['$scope', '$rootScope', '$window', 'pubsub', 'rpc', ($scope, $rootScope, $window, pubsub, rpc) ->
    # $window.onbeforeunload = ->
    #   rpc 'rtc.disconnectScreenFromRemote'
    readyData = false
    step = 1
    secondsPlayed = 0
    playerData = {}
    resetPlayerStatus = ->
      readyData = false
      step = 1
      secondsPlayed = 0
      playerData = {}

    $scope.remoteConnected = false
    $scope.videoSelected = false
    $scope.remoteConnectedAndVideoSelected = false
    $scope.$watch 'remoteConnected', (newBoolean) ->
      if newBoolean and $scope.videoSelected
        $scope.remoteConnectedAndVideoSelected = true
      else
        $scope.remoteConnectedAndVideoSelected = false
    $scope.$watch 'videoSelected', (newBoolean) ->
      if newBoolean and $scope.remoteConnected
        $scope.remoteConnectedAndVideoSelected = true
      else
        $scope.remoteConnectedAndVideoSelected = false
    $scope.ready = false
    $scope.screenCode = false
    $scope.screenCode = rpc 'rtc.requestCodeForScreen'
    $scope.$on 'ss-remoteConnected', ->
      $scope.remoteConnected = true
      if readyData
        rpc 'rtc.sendPlayerStatusToRemote', readyData
    $scope.$on 'ss-remoteDisconnected', ->
      $window.location.reload()
    $scope.$on 'ss-playerCommand', (event, data) ->
      $scope.$emit 'f-command', data

    $scope.$on 'f-ready', (event, data) ->
      resetPlayerStatus()
      $scope.ready = true
      readyData = data['f-data']
      readyData['id'] = data['f-id']
      readyData['event'] = 'ready'
      if $scope.remoteConnected
        rpc 'rtc.sendPlayerStatusToRemote', readyData
    $scope.$on 'f-loadProgress', (event, data) ->
      playerData['loadProgress'] = data['f-data']
      playerData['id'] = data['f-id']
    $scope.$on 'f-playProgress', (event, data) ->
      playerData['playProgress'] = data['f-data']
      playerData['id'] = data['f-id']
      playerData['event'] = 'update'
      if (playerData['playProgress']['seconds'] - step) > secondsPlayed
        secondsPlayed = playerData['playProgress']['seconds']
        if secondsPlayed is playerData['playProgress']['duration']
          resetPlayerStatus()
        else if $scope.remoteConnected
            rpc 'rtc.sendPlayerStatusToRemote', playerData
    $scope.$on 'f-play', (event, data) ->
      if $scope.remoteConnected
        rpc 'rtc.sendPlayerStatusToRemote', { event: 'play', id: data['f-id'] }
    $scope.$on 'f-pause', (event, data) ->
      if $scope.remoteConnected
        rpc 'rtc.sendPlayerStatusToRemote', { event: 'pause', id: data['f-id'] }
    $scope.$on 'f-finish', (event, data) ->
      resetPlayerStatus()
      if $scope.remoteConnected
        rpc 'rtc.sendPlayerStatusToRemote', { event: 'finish', id: data['f-id'] }
    $scope.$on 'f-seek', (event, data) ->
      secondsPlayed = data['f-data']['seconds']
      if $scope.remoteConnected
        rpc 'rtc.sendPlayerStatusToRemote', { event: 'seek', seek: data['f-data'], id: data['f-id'] }

    $scope.playerId = 'player1'
    $scope.videoId = 17853047
    $scope.playerUrl = '//player.vimeo.com/video/' + $scope.videoId + '?api=1&player_id=' + $scope.playerId
    $scope.$on 'ss-selectVideo', (event, id) ->
      $scope.videoId = id
      $scope.playerUrl = '//player.vimeo.com/video/' + $scope.videoId + '?api=1&player_id=' + $scope.playerId
      $rootScope.$emit 'f-refresh'
      $scope.videoSelected = true

    $scope.getWindowWidth = ->
      $(window).width()
    $scope.getWindowHeight = ->
      $(window).height()
    $scope.$watch $scope.getWindowWidth, (newWidth) ->
      $scope.playerWidth = newWidth
    $scope.$watch $scope.getWindowHeight, (newHeight) ->
      $scope.playerHeight = newHeight
    $window.onresize = ->
      $scope.$apply()

    full = false
    if screenfull.enabled
      document.addEventListener screenfull.raw.fullscreenchange, ->
        full = screenfull.isFullscreen
    $rootScope.fullScreen = ->
      if screenfull.enabled
        if full
          screenfull.exit()
          full = false
        else
          screenfull.request()
          full = true
    $scope.fullScreen = $rootScope.fullScreen
  ])
