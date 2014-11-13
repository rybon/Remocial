angular.module('mobile.controllers', ['mobile.services'])


  .controller('MainController', ['$scope', '$rootScope', '$window', '$document', 'pubsub', 'rpc', 'facebookManager', 'connectionManager', 'videosManager', 'utils', ($scope, $rootScope, $window, $document, pubsub, rpc, facebookManager, connectionManager, videosManager, utils) ->
    $scope.connect = ->
      connectionManager.requestConnect()
    $scope.disconnect = ->
      connectionManager.requestDisconnect()
    $scope.connecting = false
    $scope.$on 'connecting', ->
      $scope.connecting = true
      $scope.connected = false
    $scope.$on 'disconnecting', ->
      $scope.connecting = true
      $scope.connected = false
    $scope.connected = false
    $scope.$on 'connected', ->
      $scope.connecting = false
      $scope.connected = true
    $scope.$on 'disconnected', ->
      $scope.connecting = false
      $scope.connected = false

    $scope.login = ->
      facebookManager.login()
    $scope.logout = ->
      facebookManager.logout()
    $scope.loggedIn = false
    $scope.$on 'loggedIn', ->
      $scope.facebookName = facebookManager.getUserName()
      $scope.loggedIn = true
    $scope.$on 'loggedOut', ->
      $scope.loggedIn = false
      $scope.facebookName = ''

    $scope.currentVideo = false
    $scope.currentVideoTitle = ''
    $scope.$on 'videoSelected', ->
      $scope.currentVideoTitle = videosManager.getCurrentVideo().title
      $scope.currentVideo = true

    $scope.showSearch = ->
      videosManager.prepareSearch()
    $scope.showFavorites = ->
      videosManager.handleFavorites()
  ])


  .controller('SearchController', ['$scope', '$rootScope', 'pubsub', 'rpc', 'videosManager', ($scope, $rootScope, pubsub, rpc, videosManager) ->
    $scope.searchQuery = ''
    $scope.searchResults = []
    $scope.searchLoading = false
    $scope.searchLoadingMessage = ''
    $scope.searchEmpty = true
    $scope.searchEmptyMessage = ''
    $scope.searchError = false
    $scope.searchErrorMessage = ''

    $scope.searchClearIcon = false
    $scope.$watch 'searchQuery', (newQuery) ->
      if newQuery isnt ''
        $scope.searchClearIcon = true
        queryIsEmpty = false
      else
        $scope.searchClearIcon = false
        queryIsEmpty = true

    $scope.$on 'searching', ->
      $scope.searchResults = []
      $scope.searchLoading = true
      $scope.searchLoadingMessage = 'Searching for \'' + videosManager.getSearchQueryParameter('query') + '\'...'
      $scope.searchEmpty = false
      $scope.searchEmptyMessage = 'Sorry, nothing found for \'' + videosManager.getSearchQueryParameter('query') + '\'.'
      $scope.searchError = false
      $scope.searchErrorMessage = 'Sorry, there was an error while searching for \'' + videosManager.getSearchQueryParameter('query') + '\'. Please try again.'
    $scope.$on 'ss-searchResults', (event, data) ->
      $scope.searchResults = data.videos.video
      if not $scope.searchResults.length
        $scope.searchEmpty = true
      else
        $scope.searchEmpty = false
      $scope.searchLoading = false
    $scope.$on 'ss-searchErrors', (event, data) ->
      $scope.searchEmpty = false
      $scope.searchError = true
      $scope.searchResults = []
      $scope.searchLoading = false
    $scope.search = ->
      unless queryIsEmpty
        videosManager.setSearchQueryParameter('query', $scope.searchQuery)
        videosManager.handleSearch()
        queryIsEmpty = false
    $scope.clearSearchQuery = ->
      $scope.searchQuery = ''
      videosManager.setSearchQueryParameter('query', $scope.searchQuery)
      queryIsEmpty = true
  ])


  .controller('SearchMenuController', ['$scope', '$rootScope', 'pubsub', 'rpc', 'storageManager', 'videosManager', ($scope, $rootScope, pubsub, rpc, storageManager, videosManager) ->
    $scope.userId = videosManager.getSearchQueryParameter('userId')
    $scope.userClearIcon = false
    $scope.$watch 'userId', (newUserId) ->
      videosManager.setSearchQueryParameter('userId', newUserId)
      if newUserId isnt ''
        $scope.userClearIcon = true
      else
        $scope.userClearIcon = false
    $scope.clearUser = ->
      videosManager.setSearchQueryParameter('userId', '')
      $scope.userId = videosManager.getSearchQueryParameter('userId')
      videosManager.handleSearch()

    $scope.page = videosManager.getSearchQueryParameter('page')
    $scope.$watch 'page', (newPage) ->
      videosManager.setSearchQueryParameter('page', newPage)

    $scope.perPage = videosManager.getSearchQueryParameter('perPage')
    $scope.$watch 'perPage', (newPerPage) ->
      videosManager.setSearchQueryParameter('perPage', newPerPage)

    $scope.$on 'ss-searchResults', ->
      $scope.page = videosManager.getSearchQueryParameter('page')

    $scope.search = ->
      videosManager.handleSearch()
    $scope.flushSearch = ->
      storageManager.flushSearchCache()
  ])


  .controller('SearchFooterController', ['$scope', '$rootScope', 'pubsub', 'videosManager', ($scope, $rootScope, pubsub, videosManager) ->
    $scope.searchLoading = true
    $scope.searchWithUser = false

    $scope.searchQuery = videosManager.getSearchQueryParameter('query')
    $scope.searchSort = videosManager.getSearchQueryParameter('sort')
    $scope.searchUserId = videosManager.getSearchQueryParameter('userId')
    $scope.searchTotal = videosManager.getSearchTotal()
    $scope.searchPage = videosManager.getSearchQueryParameter('page')
    $scope.searchPages = videosManager.getPagesTotal()
    $scope.beginPage = videosManager.getBeginPage()
    $scope.endPage = videosManager.getEndPage()

    $scope.showPreviousPage = false
    $scope.showNextPage = false
    $scope.previousPage = ->
      videosManager.previousPage()
    $scope.nextPage = ->
      videosManager.nextPage()

    $scope.$on 'searching', ->
      $scope.showPreviousPage = false
      $scope.showNextPage = false
      $scope.searchLoading = true
    $scope.$on 'ss-searchResults', (event, data) ->
      $scope.showPreviousPage = videosManager.hasPreviousPage()
      $scope.showNextPage = videosManager.hasNextPage()
      $scope.searchQuery = videosManager.getSearchQueryParameter('query')
      $scope.searchSort = videosManager.getSearchQueryParameter('sort')
      $scope.searchUserId = videosManager.getSearchQueryParameter('userId')
      if $scope.searchUserId isnt ''
        $scope.searchWithUser = true
      else
        $scope.searchWithUser = false
      $scope.searchTotal = videosManager.getSearchTotal()
      $scope.searchPage = videosManager.getSearchQueryParameter('page')
      $scope.searchPages = videosManager.getPagesTotal()
      $scope.beginPage = videosManager.getBeginPage()
      $scope.endPage = videosManager.getEndPage()
      if videosManager.getVideoResultsLength()
        $scope.searchLoading = false
      else
        $scope.searchLoading = true
    $scope.$on 'ss-searchErrors', (event, data) ->
      $scope.showPreviousPage = false
      $scope.showNextPage = false
      $scope.searchLoading = true
  ])

  .controller('FavoritesController', ['$scope', ($scope) ->
    $scope.videoResults = []
    $scope.noFavorites = true
    $scope.$on 'favoritesResults', (event, data) ->
      $scope.videoResults = data
      if data.length
        $scope.noFavorites = false
      else
        $scope.noFavorites = true
  ])

  .controller('FavoritesMenuController', ['$scope', '$rootScope', 'storageManager', ($scope, $rootScope, storageManager) ->
    $scope.flushFavorites = ->
      storageManager.removeAllFavorites()
  ])


  .controller('PlayerController', ['$scope', '$rootScope', 'pubsub', 'rpc', 'storageManager', 'connectionManager', 'videosManager', 'playerManager', ($scope, $rootScope, pubsub, rpc, storageManager, connectionManager, videosManager, playerManager) ->
    $scope.connected = false
    $scope.$on 'connected', ->
      $scope.connected = true
    $scope.$on 'disconnected', ->
      $scope.connected = false
    $scope.connect = ->
      connectionManager.requestConnect()

    $scope.isMuted = false
    $scope.lowVolume = false
    $scope.highVolume = false
    $scope.$on 'mute', ->
      $scope.isMuted = true
      $scope.lowVolume = false
      $scope.highVolume = false
    $scope.$on 'lowVolume', ->
      $scope.isMuted = false
      $scope.lowVolume = true
      $scope.highVolume = false
    $scope.$on 'highVolume', ->
      $scope.isMuted = false
      $scope.lowVolume = false
      $scope.highVolume = true

    $scope.currentTitle = videosManager.getCurrentVideo().title
    $scope.currentThumbnail = videosManager.getCurrentVideo().thumbnails.thumbnail[1]['_content']
    $scope.currentDescription = videosManager.getCurrentVideo().description.replace(/\n/g,'<br />')
    $scope.currentName = videosManager.getCurrentVideo().owner.realname
    $scope.currentUsername = videosManager.getCurrentVideo().owner.username
    $scope.currentPortrait = videosManager.getCurrentVideo().owner.portraits.portrait[0]['_content']
    $scope.currentDate = videosManager.getCurrentVideo().upload_date
    $scope.currentModifiedDate = videosManager.getCurrentVideo().modified_date
    $scope.currentLink = videosManager.getCurrentVideo().urls.url[1]['_content']
    $scope.currentHD = videosManager.getCurrentVideo().is_hd
    $scope.currentNumberOfComments = videosManager.getCurrentVideo().number_of_comments
    $scope.currentNumberOfLikes = videosManager.getCurrentVideo().number_of_likes
    $scope.currentNumberOfPlays = videosManager.getCurrentVideo().number_of_plays
    $scope.$on 'videoSelected', (event, data) ->
      $scope.currentTitle = videosManager.getCurrentVideo().title
      $scope.currentThumbnail = videosManager.getCurrentVideo().thumbnails.thumbnail[1]['_content']
      $scope.currentDescription = videosManager.getCurrentVideo().description.replace(/\n/g,'<br />')
      $scope.currentName = videosManager.getCurrentVideo().owner.realname
      $scope.currentUsername = videosManager.getCurrentVideo().owner.username
      $scope.currentPortrait = videosManager.getCurrentVideo().owner.portraits.portrait[0]['_content']
      $scope.currentDate = videosManager.getCurrentVideo().upload_date
      $scope.currentModifiedDate = videosManager.getCurrentVideo().modified_date
      $scope.currentLink = videosManager.getCurrentVideo().urls.url[1]['_content']
      $scope.currentHD = videosManager.getCurrentVideo().is_hd
      $scope.currentNumberOfComments = videosManager.getCurrentVideo().number_of_comments
      $scope.currentNumberOfLikes = videosManager.getCurrentVideo().number_of_likes
      $scope.currentNumberOfPlays = videosManager.getCurrentVideo().number_of_plays
      if data.isPlayerTransfer
        $scope.play = data.play
        $scope.pause = data.pause
        $scope.isRepeated = data.isRepeated
        $scope.isMuted = data.isMuted
        if data.pause
          $rootScope.$broadcast 'playProgress', data.percentagePlayed
      else
        checkStatusOfPlayer()
        resetPlayer()
        checkStatusOfPlayer()
        $scope.ready = false

    $scope.totalDuration = 0
    resetPlayer = ->
      $scope.play = false
      $scope.pause = false
      $scope.secondsPlayed = 0
      $scope.percentagePlayed = 0
      $scope.percentageLoaded = 0
      $scope.seekToSeconds = 0
      $scope.seekToPercentage = 0
      $scope.lastAction = ''
      $scope.playbackFinished = false
      $scope.displayInfo = false
    resetPlayer()

    $scope.toggleInfo = ->
      $scope.displayInfo = not $scope.displayInfo

    $scope.command = (command) ->
      if command is 'play'
        $scope.play = true
        $scope.pause = false
        playerManager.play()
      else if command is 'pause'
        $scope.pause = true
        $scope.play = false
        playerManager.pause()
    $scope.previous = ->
      videosManager.previousVideo()
    $scope.next = ->
      videosManager.nextVideo()
    $scope.repeat = ->
      $scope.isRepeated = not $scope.isRepeated
      if $scope.isRepeated
        playerManager.repeat true
      else
        playerManager.repeat false
    $scope.favorite = ->
      if storageManager.isFavorite videosManager.getCurrentVideo().id
        storageManager.removeFavorite videosManager.getCurrentVideo().id
        $scope.isFavorited = false
      else
        storageManager.addFavorite videosManager.getCurrentVideo().id, videosManager.getCurrentVideo()
        $scope.isFavorited = true

    $scope.volume = playerManager.getVolume()
    $scope.$on 'volumeChanged', ->
      $scope.volume = playerManager.getVolume()
    $scope.mute = ->
      $scope.isMuted = not $scope.isMuted
      playerManager.mute()

    $scope.isRepeated = false
    $scope.isFavorited = false
    checkStatusOfPlayer = ->
      if $scope.isRepeated
        playerManager.repeat true
      else
        playerManager.repeat false
      if storageManager.isFavorite videosManager.getCurrentVideo().id
        $scope.isFavorited = true
      else
        $scope.isFavorited = false
      if $scope.volume is 0
        $scope.isMuted = true
      else
        $scope.isMuted = false

    $scope.$on 'ss-playerStatus', (event, data) ->
      switch data['event']
        when 'ready'
          resetPlayer()
          $scope.totalDuration = Math.round data.duration
          $scope.secondsPlayed = Math.round data.seconds
          $scope.volume = Math.round data.volume * 100
          checkStatusOfPlayer()
          $scope.ready = true
        when 'update'
          if data['loadProgress']
            $scope.percentageLoaded = Math.round data['loadProgress'].percent * 100
          $scope.secondsPlayed = Math.round data['playProgress'].seconds
          $scope.percentagePlayed = Math.round data['playProgress'].percent * 100
        when 'play'
          $scope.lastAction = 'play'
          $scope.play = true
          $scope.pause = false
        when 'pause'
          $scope.lastAction = 'pause'
          $scope.play = false
          $scope.pause = true
        when 'finish'
          $scope.playbackFinished = true
          resetPlayer()
        when 'seek'
          $scope.lastAction = 'seek'
          $scope.seekToSeconds = Math.round data['seek'].seconds
          $scope.seekToPercentage = Math.round data['seek'].percent * 100
  ])


  .controller('FriendsController', ['$scope', '$rootScope', '$window', 'pubsub', 'rpc', 'facebookManager', 'connectionManager', 'storageManager', 'videosManager', 'playerManager', 'uiManager', 'utils', ($scope, $rootScope, $window, pubsub, rpc, facebookManager, connectionManager, storageManager, videosManager, playerManager, uiManager, utils) ->
    $scope.connected = false
    $scope.$on 'connected', ->
      $scope.connecting = false
      $scope.connected = true
    $scope.$on 'disconnected', ->
      $scope.connecting = false
      $scope.connected = false

    $scope.loggedIn = false
    $scope.$on 'loggedIn', ->
      $scope.loggedIn = true
    $scope.$on 'loggedOut', ->
      $scope.loggedIn = false

    $scope.facebookFriends = []
    $scope.$on 'hasFriends', ->
      $scope.facebookFriends = facebookManager.getFriends()
    $scope.$on 'hasNoFriends', ->
      $scope.facebookFriends = []

    $scope.noFriendsOnline = true
    $scope.$on 'friendsOnline', ->
      $scope.noFriendsOnline = false
    $scope.$on 'noFriendsOnline', ->
      $scope.noFriendsOnline = true

    utils.repeat 10000, ->
      if $scope.loggedIn and facebookManager.getUserId() > 0 and facebookManager.hasFriends()
        timestamp = new Date().getTime()
        $rootScope.$broadcast 'refreshUsers', timestamp

    selectedFriend = 0
    $scope.selectFriend = (friendId) ->
      if not $scope.connected
        uiManager.showAlert message: 'To pass the remote, please connect to a screen first.'
      else
        uiManager.showConfirm
          message: 'Do you want to pass the remote to ' + facebookManager.getFriendName(friendId) + '?',
          action: ->
            selectedFriend = friendId
            rpc 'rtc.offerRemoteToFriend', facebookManager.getUserId(), friendId

    offeringFriend = 0
    $scope.$on 'ss-offerRemote', (event, data) ->
      if data.to is facebookManager.getUserId()
        if $scope.connected
          uiManager.showConfirm
            message: facebookManager.getFriendName(data.from) + ' wants to pass the remote! Accept and disconnect from your current screen?',
            action: ->
              offeringFriend = data.from
              connectionManager.transferDisconnect true
              rpc 'rtc.acceptRemoteFromFriend', facebookManager.getUserId(), data.from
        else
          uiManager.showConfirm
            message: facebookManager.getFriendName(data.from) + ' wants to pass the remote! Accept?',
            action: ->
              offeringFriend = data.from
              rpc 'rtc.acceptRemoteFromFriend', facebookManager.getUserId(), data.from

    $scope.$on 'ss-acceptRemote', (event, data) ->
      if data.to is facebookManager.getUserId() and data.from is selectedFriend
        videoData = videosManager.getCurrentVideo();
        videoData.play = playerManager.getPlayerStatus().play;
        videoData.pause = playerManager.getPlayerStatus().pause;
        videoData.isRepeated = playerManager.getPlayerStatus().isRepeated;
        videoData.isMuted = playerManager.getPlayerStatus().isMuted;
        videoData.percentagePlayed = playerManager.getPlayerStatus().percentagePlayed;
        rpc 'rtc.transferRemoteToFriend', facebookManager.getUserId(), data.from, videoData
        connectionManager.transferDisconnect()

    $scope.$on 'ss-transferRemote', (event, data) ->
      if data.to is facebookManager.getUserId() and data.from is offeringFriend
        videosManager.setCurrentVideo(data.videoData)
        $rootScope.$broadcast 'videoSelected', { 'play': data.videoData.play, 'pause': data.videoData.pause, 'isRepeated': data.videoData.isRepeated, 'isMuted': data.videoData.isMuted, 'percentagePlayed': data.videoData.percentagePlayed, 'isPlayerTransfer': true }
        connectionManager.transferConnect data.code
  ])
