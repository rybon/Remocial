angular.module('mobile.directives', ['mobile.services'])


  .directive('mainScreen', [->
    restrict: 'E',
    replace: true,
    scope: {},
    templateUrl: '/templates/mobile/main-screen.html'
  ])


  .directive('searchScreen', [->
    restrict: 'E',
    replace: true,
    scope: {},
    templateUrl: '/templates/mobile/search-screen.html'
  ])


  .directive('favoritesScreen', [->
    restrict: 'E',
    replace: true,
    scope: {},
    templateUrl: '/templates/mobile/favorites-screen.html'
  ])


  .directive('playerScreen', [->
    restrict: 'E',
    replace: true,
    scope: {},
    templateUrl: '/templates/mobile/player-screen.html'
  ])


  .directive('friendsScreen', [->
    restrict: 'E',
    replace: true,
    scope: {},
    templateUrl: '/templates/mobile/friends-screen.html'
  ])


  .directive('howtoMenu', [->
    restrict: 'E',
    replace: true,
    scope: {},
    templateUrl: '/templates/mobile/howto-menu.html'
  ])


  .directive('searchMenu', [->
    restrict: 'E',
    replace: true,
    scope: {},
    templateUrl: '/templates/mobile/search-menu.html'
  ])


  .directive('favoritesMenu', [->
    restrict: 'E',
    replace: true,
    scope: {},
    templateUrl: '/templates/mobile/favorites-menu.html'
  ])


  .directive('volumeMenu', [->
    restrict: 'E',
    replace: true,
    scope: {},
    templateUrl: '/templates/mobile/volume-menu.html'
  ])


  .directive('overlaySheet', [->
    restrict: 'E',
    replace: true,
    scope: {},
    templateUrl: '/templates/mobile/overlay-sheet.html'
  ])


  .directive('alertBox', [->
    restrict: 'E',
    replace: true,
    scope: {},
    templateUrl: '/templates/mobile/alert-box.html'
  ])


  .directive('confirmBox', [->
    restrict: 'E',
    replace: true,
    scope: {},
    templateUrl: '/templates/mobile/confirm-box.html'
  ])


  .directive('promptBox', [->
    restrict: 'E',
    replace: true,
    scope: {},
    templateUrl: '/templates/mobile/prompt-box.html'
  ])


  .directive('screen', ['$rootScope', 'uiManager', 'utils', ($rootScope, uiManager, utils) ->
    scope: {},
    link: (scope, element, attrs) ->

      scope.isCurrent = false
      scope.isShown = false
      scope.isHidden = false
      scope.isMenuOpen = false
      scope.isMenuRight = false
      scope.isMenuSmall = false

      scope.style = utils.inferCorrectPositionAttributeFromUserAgent navigator.userAgent

      uiManager.registerScreen attrs.id, attrs.transition
      if attrs.id is 'main-screen'
        scope.isCurrent = true
        scope.isShown = true
        uiManager.initializeScreenStack attrs.id

      $rootScope.$on 'changeScreen', (event, data) ->
        # navigating FROM this screen
        if scope.isShown
          scope.isCurrent = false
          scope.isHidden = true
          utils.delay uiManager.getTransitionTime(), ->
            scope.$apply ->
              scope.isShown = false
        # navigating TO this screen
        else if data.id is attrs.id
          scope.isCurrent = true
          scope.isShown = true
          utils.delay uiManager.getTransitionTime(), ->
            scope.$apply ->
              scope.isHidden = false
      $rootScope.$on 'back', (event, data) ->
        # navigating FROM this screen
        if data.currentId is attrs.id
          scope.isCurrent = false
          scope.isShown = false
          scope.isMenuOpen = false
          utils.delay uiManager.getTransitionTime(), ->
            # reset (remove) all classes
            scope.$apply ->
              scope.isCurrent = false
              scope.isShown = false
              scope.isHidden = false
              scope.isMenuOpen = false
              scope.isMenuRight = false
              scope.isMenuSmall = false
        # navigating TO this screen
        else if data.previousId is attrs.id
          scope.isCurrent = true
          scope.isShown = true
          scope.isHidden = false
      $rootScope.$on 'openMenu', (event, data) ->
        if data.screenId is attrs.id
          scope.isMenuOpen = true
          scope.isMenuRight = if data.right then data.right else false
          scope.isMenuSmall = if data.small then data.small else false
      $rootScope.$on 'closeMenu', (event, data) ->
        scope.isMenuOpen = false
        scope.isMenuRight = false
        scope.isMenuSmall = false
  ])


  .directive('menu', ['$rootScope', 'uiManager', 'utils', ($rootScope, uiManager, utils) ->
    scope: {},
    link: (scope, element, attrs) ->
      scope.isShown = false
      scope.isMenuRight = if attrs.right then true else false
      scope.isMenuSmall = if attrs.small then true else false
      uiManager.registerMenu attrs.id, attrs.transition, scope.isMenuRight, scope.isMenuSmall
      $rootScope.$on 'openMenu', (event, data) ->
        if data.id is attrs.id
          scope.isShown = true
      $rootScope.$on 'closeMenu', (event, data) ->
        if data
          scope.isShown = false
        else
          utils.delay uiManager.getTransitionTime(), ->
            scope.$apply ->
              scope.isShown = false
      $rootScope.$on 'changeScreen', (event, data) ->
        utils.delay uiManager.getTransitionTime(), ->
          scope.$apply ->
            scope.isShown = false
            $rootScope.$broadcast 'closeMenu', true
  ])


  .directive('overlay', ['$rootScope', ($rootScope) ->
    scope: {},
    link: (scope, element, attrs) ->
      scope.isShown = false
      $rootScope.$on 'showBox', (event, data) ->
        scope.isShown = true
      $rootScope.$on 'closeBox', (event, data) ->
        scope.isShown = false
  ])


  .directive('box', ['$rootScope', 'connectionManager', 'uiManager', ($rootScope, connectionManager, uiManager) ->
    scope: {},
    link: (scope, element, attrs) ->
      scope.isShown = false
      $rootScope.$on 'prompt', (event, data) ->
        if attrs['box'] is 'prompt'
          resetPrompt()
          scope.isShown = true
        else
          scope.isShown = false
      $rootScope.$on 'confirm', (event, data) ->
        if attrs['box'] is 'confirm'
          scope.message = ''
          action = null
          scope.isShown = true
        else
          scope.isShown = false
      $rootScope.$on 'alert', (event, data) ->
        if attrs['box'] is 'alert'
          scope.message = ''
          scope.isShown = true
        else
          scope.isShown = false

      action = null
      scope.message = ''
      $rootScope.$on 'modalData', (event, data) ->
        scope.message = data.message
        action = data.action if data.action

      digitSize = 4
      code = ''
      resetPrompt = ->
        code = ''
        scope.firstDigit = '&nbsp;'
        scope.secondDigit = '&nbsp;'
        scope.thirdDigit = '&nbsp;'
        scope.fourthDigit = '&nbsp;'

      if attrs['box'] is 'prompt'
        resetPrompt()
        scope.addNumber = (number) ->
          if code.length < digitSize
            code += number
            if code.length is 1
              scope.firstDigit = code[0]
            else if code.length is 2
              scope.secondDigit = code[1]
            else if code.length is 3
              scope.thirdDigit = code[2]
            else if code.length is 4
              scope.fourthDigit = code[3]
          if code.length is digitSize
            connectionManager.connect parseInt code
            uiManager.handleLink 'dismiss'
        scope.removeNumber = ->
          if code.length
            code = code.substring 0, code.length - 1
            if code.length is 3
              scope.fourthDigit = '&nbsp;'
            else if code.length is 2
              scope.thirdDigit = '&nbsp;'
            else if code.length is 1
              scope.secondDigit = '&nbsp;'
            else if code.length is 0
              scope.firstDigit = '&nbsp;'
      else if attrs['box'] is 'confirm'
        scope.ok = ->
          action()
          uiManager.handleLink 'dismiss'
  ])


  .directive('option', ['$rootScope', 'videosManager', ($rootScope, videosManager) ->
    scope: {},
    link: (scope, element, attrs) ->
      scope.isCurrent = false
      if attrs.option is videosManager.getSearchQueryParameter('sort')
        scope.isCurrent = true
      scope.sort = (option) ->
        videosManager.setSearchQueryParameter('sort', option)
        $rootScope.$broadcast 'sortChanged', option
        videosManager.handleSearch()
      scope.$on 'sortChanged', (event, option) ->
        if option is attrs.option
          scope.isCurrent = true
        else
          scope.isCurrent = false
  ])


  .directive('video', ['$rootScope', 'uiManager', 'videosManager', ($rootScope, uiManager, videosManager) ->
    (scope, element, attrs) ->
      scope.selected = false
      attrs.$observe 'video', (id) ->
        if videosManager.getCurrentVideo().id is id
          scope.selected = true
      scope.selectVideo = (index) ->
        videosManager.setCurrentVideoIndex index
      scope.$on 'videoSelected', (event, data) ->
        if videosManager.getCurrentVideo().id is attrs.video and scope.selected is false
          scope.selected = true
        else if videosManager.getCurrentVideo().id is attrs.video and scope.selected is true and not data.isPlayerTransfer
          uiManager.handleLink 'player-screen'
        else
          scope.selected = false
  ])


  .directive('friend', ['$rootScope', 'facebookManager', ($rootScope, facebookManager) ->
    (scope, element, attrs) ->
      friendId = 0
      lastCheck = 0
      scope.female = false
      scope.online = false
      attrs.$observe 'friend', (id) ->
        friendId = id
      attrs.$observe 'gender', (gender) ->
        if gender is 'female'
          scope.female = true
      $rootScope.$on 'ss-userStatus', (event, id) ->
        if id is friendId
          if not scope.online
            facebookManager.incrementOnlineFriendsCounter()
          scope.online = true
          lastCheck = new Date().getTime()
      $rootScope.$on 'refreshUsers', (event, timestamp) ->
        if (timestamp - 10000) > lastCheck
          if scope.online
            facebookManager.decrementOnlineFriendsCounter()
          scope.online = false
  ])


  .directive('playback', ['$rootScope', '$document', 'playerManager', ($rootScope, $document, playerManager) ->
    scope: {},
    link: (scope, element, attrs) ->
      sliding = false
      totalDuration = 0
      $document.ready ->
        api = $('#playback').rangeinput({progress:true,speed:0}).data('rangeinput')
        api.change (event, value) ->
          sliding = true
          playerManager.seek Math.round((value / 100) * totalDuration)
        scope.$on 'ss-playerStatus', (event, data) ->
          if data['event'] is 'ready'
            sliding = false
            api.setValue 0
            totalDuration = Math.round data.duration
          else if data['event'] is 'update'
            if not sliding
              api.setValue Math.round(data['playProgress'].percent * 100)
          else if data['event'] is 'seek'
            sliding = false
          else if data['event'] is 'finish'
            sliding = false
            api.setValue 0
        scope.$on 'videoSelected', ->
          sliding = false
          api.setValue 0
        scope.$on 'playProgress', (event, percentagePlayed) ->
          if not sliding
            api.setValue percentagePlayed
  ])


  .directive('volumeIcon', [->
    scope: {},
    link: (scope, element, attrs) ->
      scope.connected = false
      scope.mute = true
      scope.lowVolume = false
      scope.highVolume = false
      scope.$on 'connected', ->
        scope.connected = true
      scope.$on 'disconnected', ->
        scope.connected = false
      scope.$on 'mute', ->
        scope.mute = true
        scope.lowVolume = false
        scope.highVolume = false
      scope.$on 'lowVolume', ->
        scope.mute = false
        scope.lowVolume = true
        scope.highVolume = false
      scope.$on 'highVolume', ->
        scope.mute = false
        scope.lowVolume = false
        scope.highVolume = true
  ])


  .directive('volume', ['$document', 'playerManager', ($document, playerManager) ->
    scope: {},
    link: (scope, element, attrs) ->
      $document.ready ->
        api = $('#volume').rangeinput({progress:true,speed:0,vertical:true,css:{input:'volumeRange',slider:'volumeSlider',progress:'volumeProgress',handle:'volumeHandle'}}).data('rangeinput')
        api.change (event, value) ->
          playerManager.setVolume value
        scope.$on 'volumeChanged', ->
          api.setValue playerManager.getVolume()
  ])


  .directive('tap', ['uiManager', (uiManager) ->
    (scope, element, attrs) ->
      href = attrs.href || ''
      screenId = $(element).closest('section').attr('id')
      element.fastClick (e) ->
        uiManager.handleLink href, screenId
        scope.$apply attrs['tap']
  ])


  .directive('key', [->
    (scope, element, attrs) ->
      element.on 'keypress', (event) ->
        if event.which is 13
          element.trigger 'blur'
      element.on 'blur', (event) ->
        scope.$apply attrs['key']
  ])


  .directive('cancel', [->
    (scope, element, attrs) ->
      element.on 'submit', (event) ->
        false
  ])
