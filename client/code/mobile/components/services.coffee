angular.module('mobile.services', [])


  .factory('rpc', ['$q', '$rootScope', ($q, $rootScope) ->
    isReady = false
    queued = []
    window.ss.server.on 'ready', ->
      isReady = true
      while queued.length
        window.ss.rpc.apply window.ss, queued.shift()
    window.ss.server.on 'reconnect', ->
      isReady = true
      while queued.length
        window.ss.rpc.apply window.ss, queued.shift()
    window.ss.server.on 'disconnect', ->
      isReady = false

    (command) ->
      args = Array.prototype.slice.apply arguments
      deferred = $q.defer()
      rpcArgs = [command].concat(args.slice(1, args.length)).concat (response) ->
        $rootScope.$apply ->
          deferred.resolve response
      if isReady
        window.ss.rpc.apply window.ss, rpcArgs
      else
        queued.push rpcArgs
      deferred.promise
  ])


  .factory('pubsub', ['$rootScope', ($rootScope) ->
    old$on = $rootScope.$on
    Object.getPrototypeOf($rootScope).$on = (name, listener) ->
      scope = @
      if name.length > 3 and name.substr(0,3) is 'ss-'
        window.ss.event.on name, (message) ->
          scope.$apply ->
            scope.$broadcast name, message
      old$on.apply @, arguments
  ])


  .factory('connectionManager', ['$rootScope', 'uiManager', 'rpc', 'utils', ($rootScope, uiManager, rpc, utils) ->
    requestConnect = ->
      uiManager.showPrompt()
    requestDisconnect = ->
      uiManager.showConfirm
        message: 'Are you sure you want to disconnect from the screen?',
        action: disconnect
    connect = (code) ->
      code ?= 0
      if code > 999 and code < 10000
        $rootScope.$broadcast 'connecting'
        connected = rpc 'rtc.connectRemoteToScreen', code
        connected.then (conn) ->
          if conn
            $rootScope.$broadcast 'connected'
          else
            $rootScope.$broadcast 'disconnected'
    disconnect = ->
      $rootScope.$broadcast 'disconnecting'
      disconnected = rpc 'rtc.disconnectRemoteFromScreen'
      disconnected.then (disconn) ->
        if disconn
          $rootScope.$broadcast 'disconnected'
    transferConnect = (code) ->
      $rootScope.$broadcast 'connecting'
      connected = rpc 'rtc.connectRemoteToScreen', code
      connected.then (conn) ->
        if conn
          $rootScope.$broadcast 'connected'
          uiManager.showAlert message: 'You have the remote!'
    transferDisconnect = (currentlyConnected) ->
      if currentlyConnected
        $rootScope.$broadcast 'disconnecting'
        disconnected = rpc 'rtc.disconnectRemoteFromScreen'
        disconnected.then (disconn) ->
          if disconn
            $rootScope.$broadcast 'disconnected'
      else
        $rootScope.$broadcast 'disconnected'

    requestConnect: requestConnect,
    requestDisconnect: requestDisconnect,
    connect: connect,
    disconnect: disconnect,
    transferConnect: transferConnect,
    transferDisconnect: transferDisconnect
  ])


  .factory('uiManager', ['$rootScope', ($rootScope) ->
    screens = {}
    menus = {}
    screenStack = []
    menuStack = []
    currentScreen = ''
    currentMenu = ''
    previousScreen = ''
    link = ''
    timestamp = 0
    lastTap = 0
    transitionTime = 350

    getTransitionTime = ->
      transitionTime
    registerScreen = (id, transition) ->
      screens[id] = transition: transition
    registerMenu = (id, transition, right, small) ->
      menus[id] = transition: transition, right: right, small: small
    initializeScreenStack = (id) ->
      screenStack[0] = id
    handleLink = (href, screenId) ->
      if /prompt-box/.test href
        $rootScope.$broadcast 'prompt'
        $rootScope.$broadcast 'showBox'
      if /confirm-box/.test href
        $rootScope.$broadcast 'confirm'
        $rootScope.$broadcast 'showBox'
      if /alert-box/.test href
        $rootScope.$broadcast 'alert'
        $rootScope.$broadcast 'showBox'
      if /dismiss/.test href
        $rootScope.$broadcast 'closeBox'
      timestamp = new Date().getTime()
      link = href.replace '#', ''
      if lastTap < (timestamp - transitionTime) and link isnt ''
        lastTap = timestamp
        if link isnt 'back'
          if screens.hasOwnProperty(link) and link isnt currentScreen
            currentScreen = link
            screenStack.push link
            $rootScope.$broadcast 'changeScreen', id: link, transition: screens[link].transition
          else if menus.hasOwnProperty(link)
            if link is currentMenu
              currentMenu = ''
              menuStack.pop()
              $rootScope.$broadcast 'closeMenu'
            else
              currentMenu = link
              menuStack.push link
              $rootScope.$broadcast 'openMenu', id: link, screenId: screenId, right: menus[link].right, small: menus[link].small
        else if link is 'back' and screenStack.length > 1
          currentScreen = screenStack.pop()
          previousScreen = screenStack[screenStack.length - 1]
          $rootScope.$broadcast 'back', currentId: currentScreen, currentTransition: screens[currentScreen].transition, previousId: previousScreen, previousTransition: screens[previousScreen].transition
          currentScreen = ''
    showPrompt = ->
      handleLink 'prompt-box'
    showConfirm = (modalData) ->
      handleLink 'confirm-box'
      $rootScope.$broadcast 'modalData', modalData
    showAlert = (modalData) ->
      handleLink 'alert-box'
      $rootScope.$broadcast 'modalData', modalData

    getTransitionTime: getTransitionTime,
    registerScreen: registerScreen,
    registerMenu: registerMenu,
    initializeScreenStack: initializeScreenStack
    handleLink: handleLink,
    showPrompt: showPrompt,
    showConfirm: showConfirm,
    showAlert: showAlert
  ])


  .factory('facebookManager', ['$rootScope', 'uiManager', 'rpc', 'utils', ($rootScope, uiManager, rpc, utils) ->
    loggedIn = false
    userId = 0
    userName = ''
    friends = []
    friendIds = []
    friendNames = {}
    onlineCounter = 0
    resetFriendsData = ->
      friends = []
      friendIds = []
      friendNames = {}
      onlineCounter = 0

    handleStatus = (response) ->
      if response.status is 'connected'
        setupUser()
      else
        cleanupUser()
    login = ->
      window.FB.login (response) ->
        if response.authResponse
          setupUser()
        else
          cleanupUser()
    logout = ->
      uiManager.showConfirm
        message: 'Are you sure you want to log out? This will log you out of Facebook as well!',
        action: ->
          window.FB.logout (response) ->
            $rootScope.$apply ->
              cleanupUser()
    setupUser = ->
      window.FB.api '/me', (response) ->
        loggedIn = true
        setUserId response.id
        setUserName response.name
        $rootScope.$broadcast 'loggedIn'
        rpc 'rtc.publishUser', getUserId()
      window.FB.api '/me/friends', { fields: 'id,first_name,last_name,name,birthday,gender,location,link,installed', limit: 5000 }, (response) ->
        resetFriendsData()
        friends = response.data
        for friend in friends
          friendIds.push friend.id
          friendNames[friend.id] = friend.name
        if friends.length
          $rootScope.$broadcast 'hasFriends'
          rpc 'rtc.subscribeToFriends', friendIds
        else
          $rootScope.$broadcast 'hasNoFriends'
      utils.repeat 5000, ->
        if loggedIn and getUserId() > 0 and hasFriends()
          rpc 'rtc.publishUser', getUserId()
    cleanupUser = ->
      setUserName ''
      setUserId 0
      loggedIn = false
      $rootScope.$broadcast 'loggedOut'
    getUserId = ->
      userId
    setUserId = (id) ->
      userId = id
    getUserName = ->
      userName
    setUserName = (name) ->
      userName = name
    getFriendName = (id) ->
      friendNames[id]
    hasFriends = ->
      friends.length
    getFriends = ->
      friends
    incrementOnlineFriendsCounter = ->
      if onlineCounter < friends.length
        onlineCounter++
      if onlineCounter > 0
        $rootScope.$broadcast 'friendsOnline'
    decrementOnlineFriendsCounter = ->
      if onlineCounter > 0
        onlineCounter--
      if onlineCounter is 0
        $rootScope.$broadcast 'noFriendsOnline'

    handleStatus: handleStatus,
    login: login,
    logout: logout,
    getUserId: getUserId,
    getUserName: getUserName,
    getFriendName: getFriendName,
    hasFriends: hasFriends,
    getFriends: getFriends,
    incrementOnlineFriendsCounter: incrementOnlineFriendsCounter,
    decrementOnlineFriendsCounter: decrementOnlineFriendsCounter
  ])


  .factory('videosManager', ['$rootScope', 'storageManager', 'rpc', 'pubsub', ($rootScope, storageManager, rpc, pubsub) ->
    showFavorites = false

    search = {}
    search.userId = ''
    search.page = 1
    search.perPage = 10
    search.summaryResponse = 0
    search.fullResponse = 1
    search.query = ''
    search.sort = 'relevant'

    searchLoading = false
    searchObject = {}
    searchCacheKey = ''

    searchResults = []
    searchTotal = 0
    favoritesResults = []
    currentIndex = -1

    previousSearchUserId = ''
    previousSearchPage = 1
    previousSearchPerPage = 10
    previousSearchQuery = ''
    previousSearchSort = 'relevant'

    currentVideo = {}
    currentVideo.id = 0
    currentVideo.title = 'Please select a video'
    currentVideo.thumbnails = { 'thumbnail': ['', { '_content': '/images/200x150.gif' }] }
    currentVideo.description = 'No video selected.'
    currentVideo.owner = { 'realname': '', 'username': '', 'portraits': { 'portrait': [{ '_content': '/images/30x30.gif' }] } }
    currentVideo.upload_date = '0000-00-00 00:00:00'
    currentVideo.modified_date = '0000-00-00 00:00:00'
    currentVideo.urls = { 'url': ['', { '_content': 'http://www.vimeo.com' }] }
    currentVideo.is_hd = 0
    currentVideo.number_of_comments = 0
    currentVideo.number_of_likes = 0
    currentVideo.number_of_plays = 0

    getSearchQueryParameter = (key) ->
      search[key]
    setSearchQueryParameter = (key, value) ->
      search[key] = value
    checkForDifferentParameters = ->
      if previousSearchUserId isnt getSearchQueryParameter('userId') or previousSearchPerPage isnt getSearchQueryParameter('perPage') or previousSearchQuery isnt getSearchQueryParameter('query') or previousSearchSort isnt getSearchQueryParameter('sort')
          setSearchQueryParameter 'page', 1
    cleanupParameters = ->
      userId = getSearchQueryParameter('userId').toString()
      setSearchQueryParameter('userId', userId.toLowerCase())
      page = parseInt getSearchQueryParameter('page')
      if isNaN page or page < 1
        setSearchQueryParameter('page', 1)
      perPage = parseInt getSearchQueryParameter('perPage')
      if isNaN perPage or (perPage < 1 or perPage > 50)
        setSearchQueryParameter('perPage', 10)
      setSearchQueryParameter('summaryResponse', 0)
      setSearchQueryParameter('fullResponse', 1)
      query = getSearchQueryParameter('query').toString()
      setSearchQueryParameter('query', query.toLowerCase())
      sort = getSearchQueryParameter('sort').toString()
      setSearchQueryParameter('sort', sort.toLowerCase())
    setPreviousParameters = ->
      previousSearchUserId = getSearchQueryParameter('userId')
      previousSearchPerPage = getSearchQueryParameter('perPage')
      previousSearchQuery = getSearchQueryParameter('query')
      previousSearchSort = getSearchQueryParameter('sort')
    prepareSearch = ->
      showFavorites = false
    handleSearch = ->
      if getSearchQueryParameter('query') isnt '' and not searchLoading
        searchLoading = true
        $rootScope.$broadcast 'searching'
        checkForDifferentParameters()
        cleanupParameters()
        setPreviousParameters()
        searchObject =
          user_id: getSearchQueryParameter('userId'),
          page: getSearchQueryParameter('page'),
          per_page: getSearchQueryParameter('perPage'),
          summary_response: getSearchQueryParameter('summaryResponse'),
          full_response: getSearchQueryParameter('fullResponse'),
          query: getSearchQueryParameter('query'),
          sort: getSearchQueryParameter('sort')
        searchCacheKey = storageManager.buildSearchCacheKey searchObject
        if storageManager.getSearchCache searchCacheKey
          data = storageManager.getSearchCache searchCacheKey
          data.cache = true
          $rootScope.$broadcast 'ss-searchResults', data
        else
          rpc 'rtc.searchVideosOnVimeo', searchObject

    $rootScope.$on 'ss-searchResults', (event, data) ->
      if not data.cache and data.videos.video.length
        storageManager.setSearchCache searchCacheKey, data
      searchResults = data.videos.video
      searchTotal = parseInt data.videos.total
      searchLoading = false
    $rootScope.$on 'ss-searchErrors', (event, data) ->
      searchResults = []
      searchTotal = 0
      searchLoading = false

    handleFavorites = ->
      showFavorites = true
      data = storageManager.getAllFavorites()
      $rootScope.$broadcast 'favoritesResults', data

    $rootScope.$on 'favoritesResults', (event, data) ->
      favoritesResults = data

    hasCurrentVideo = ->
      currentVideo.id > 0
    getCurrentVideo = ->
      currentVideo
    setCurrentVideo = (object) ->
      currentVideo = object
    setCurrentVideoTitle = (title) ->
      currentVideo.title = title
    getCurrentVideoIndex = ->
      currentIndex
    setCurrentVideoIndex = (index) ->
      currentIndex = index
      if showFavorites
        currentVideo = favoritesResults[currentIndex]
      else
        currentVideo = searchResults[currentIndex]
      $rootScope.$broadcast 'videoSelected', currentVideo.id
      rpc 'rtc.selectVideo', currentVideo.id

    $rootScope.$on 'connected', ->
      if hasCurrentVideo()
        rpc 'rtc.selectVideo', getCurrentVideo().id

    getVideoResultsLength = ->
      if showFavorites
        favoritesResults.length
      else
        searchResults.length
    getSearchTotal = ->
      searchTotal
    previousVideo = ->
      if getCurrentVideoIndex() > 0
        setCurrentVideoIndex(getCurrentVideoIndex() - 1)
    nextVideo = ->
      if getCurrentVideoIndex() < (getVideoResultsLength() - 1)
        setCurrentVideoIndex(getCurrentVideoIndex() + 1)
    getBeginPage = ->
      begin = ((getSearchQueryParameter('page') * getSearchQueryParameter('perPage')) - getSearchQueryParameter('perPage')) + 1
      begin
    getEndPage = ->
      end = getSearchQueryParameter('page') * getSearchQueryParameter('perPage')
      if end > getSearchTotal()
        if getPagesTotal() is getSearchQueryParameter('page')
          end = getSearchTotal()
      end
    getPagesTotal = ->
      rest = getSearchTotal() % getSearchQueryParameter('perPage')
      pages = (getSearchTotal() - rest) / getSearchQueryParameter('perPage')
      if rest > 0
        pages++
      pages
    hasPreviousPage = ->
      getSearchQueryParameter('page') > 1
    hasNextPage = ->
      getPagesTotal() > getSearchQueryParameter('page')
    previousPage = ->
      if hasPreviousPage()
        setSearchQueryParameter('page', getSearchQueryParameter('page') - 1)
        handleSearch()
    nextPage = ->
      if hasNextPage()
        setSearchQueryParameter('page', getSearchQueryParameter('page') + 1)
        handleSearch()

    getSearchQueryParameter: getSearchQueryParameter,
    setSearchQueryParameter: setSearchQueryParameter,
    prepareSearch: prepareSearch,
    handleSearch: handleSearch,
    handleFavorites: handleFavorites,
    hasCurrentVideo: hasCurrentVideo,
    getCurrentVideo: getCurrentVideo,
    setCurrentVideo: setCurrentVideo,
    getCurrentVideoIndex: getCurrentVideoIndex,
    setCurrentVideoIndex: setCurrentVideoIndex,
    getVideoResultsLength: getVideoResultsLength,
    getSearchTotal: getSearchTotal,
    previousVideo: previousVideo,
    nextVideo: nextVideo,
    getBeginPage: getBeginPage,
    getEndPage: getEndPage,
    getPagesTotal: getPagesTotal,
    hasPreviousPage: hasPreviousPage,
    hasNextPage: hasNextPage,
    previousPage: previousPage,
    nextPage: nextPage
  ])


  .factory('playerManager', ['$rootScope', 'rpc', ($rootScope, rpc) ->
    volume = 0
    previousVolume = 0

    play = false
    pause = false
    isRepeated = false
    isMuted = false

    percentagePlayed = 0

    getVolume = ->
      volume
    setVolume = (newValue) ->
      volume = newValue
      sendCommand 'setVolume', newValue / 100
      sendVolumeEvents()
    sendVolumeEvents = ->
      $rootScope.$broadcast 'volumeChanged'
      if volume is 0
        $rootScope.$broadcast 'mute'
      else if volume > 0 and volume < 51
        $rootScope.$broadcast 'lowVolume'
      else
        $rootScope.$broadcast 'highVolume'
    $rootScope.$on 'connected', ->
      setVolume volume
    $rootScope.$on 'videoSelected', (event, data) ->
      play = data.play
      pause = data.pause
      isRepeated = data.isRepeated
      isMuted = data.isMuted
      percentagePlayed = data.percentagePlayed
      if isMuted
        setVolume 0
    $rootScope.$on 'ss-playerStatus', (event, data) ->
      if data['event'] is 'ready'
        if isMuted
          setVolume 0
        else
          setVolume(Math.round(data.volume * 100))
      else if data['event'] is 'update'
        percentagePlayed = Math.round data['playProgress'].percent * 100
      else if data['event'] is 'finish'
        percentagePlayed = 0
    sendCommand = (command, value) ->
      data = { command: command, value: value }
      rpc 'rtc.sendPlayerCommandToScreen', data
    play = ->
      play = true
      pause = false
      sendCommand 'play', 1
    pause = ->
      play = false
      pause = true
      sendCommand 'pause', 1
    repeat = (repeatVideo) ->
      if repeatVideo
        isRepeated = true
        sendCommand 'setLoop', 1
      else
        isRepeated = false
        sendCommand 'setLoop', 0
    seek = (seekTo) ->
      sendCommand 'seekTo', seekTo
    mute = ->
      if isMuted
        setVolume previousVolume
        isMuted = false
      else
        previousVolume = volume
        setVolume 0
        isMuted = true
    getPlayerStatus = ->
      { play: play, pause: pause, isRepeated: isRepeated, isMuted: isMuted, percentagePlayed: percentagePlayed }

    getVolume: getVolume,
    setVolume: setVolume,
    play: play,
    pause: pause,
    repeat: repeat,
    seek: seek,
    mute: mute,
    getPlayerStatus: getPlayerStatus
  ])


  .factory('storageManager', ['$rootScope', ($rootScope) ->
    buildSearchCacheKey = (object) ->
      cacheKey = for own key, value of object
        key.toString() + ':' + value.toString()
      cacheKey.join ','
    getSearchCache = (key) ->
      window.lscache.setBucket 'search|'
      window.lscache.get key
    setSearchCache = (key, data) ->
      window.lscache.setBucket 'search|'
      window.lscache.set key, data, 60 * 24
    flushSearchCache = ->
      window.lscache.setBucket 'search|'
      window.lscache.flush()
    isFavorite = (id) ->
      window.lscache.setBucket 'favorites|'
      window.lscache.get id
    getAllFavorites = ->
      favorites = []
      for key in Object.keys window.localStorage when /lscache-favorites\|/.test key
        favorite = key.replace 'lscache-favorites|', ''
        favorites.push isFavorite favorite
      favorites
    addFavorite = (id, data) ->
      window.lscache.setBucket 'favorites|'
      if not isFavorite id
        window.lscache.set id, data
        $rootScope.$broadcast 'favoritesResults', getAllFavorites()
    removeFavorite = (id) ->
      window.lscache.setBucket 'favorites|'
      window.lscache.remove id
      $rootScope.$broadcast 'favoritesResults', getAllFavorites()
    removeAllFavorites = ->
      window.lscache.setBucket 'favorites|'
      window.lscache.flush()
      $rootScope.$broadcast 'favoritesResults', getAllFavorites()

    buildSearchCacheKey: buildSearchCacheKey,
    getSearchCache: getSearchCache,
    setSearchCache: setSearchCache,
    flushSearchCache: flushSearchCache,
    isFavorite: isFavorite,
    getAllFavorites: getAllFavorites,
    addFavorite: addFavorite,
    removeFavorite: removeFavorite,
    removeAllFavorites: removeAllFavorites
  ])


  .factory('utils', ['$rootScope', '$window', '$document', 'rpc', ($rootScope, $window, $document, rpc) ->
    # window.onbeforeunload = ->
    #   rpc 'rtc.disconnectRemoteFromScreen'
    # window.onhashchange = ->
    #   if window.location.hash
    #     loc = window.location
    #     if 'pushState' in window.history
    #       window.history.pushState '', document.title, loc.pathname + loc.search
    #     else
    #       loc.hash = ''
    # $rootScope.$on 'ss-screenDisconnected', ->
    #   window.location.reload()

    isOldAndroid = (ua) ->
      old = false
      if ua.indexOf('Android') >= 0
        version = parseFloat(ua.slice(ua.indexOf('Android')+8))
        if version < 3
          old = true
      old
    inferCorrectPositionAttributeFromUserAgent = (ua) ->
      style = position: 'fixed'
      if isOldAndroid ua
        style = position: 'absolute'
      style
    delay = (ms, func) -> window.setTimeout func, ms
    repeat = (ms, func) -> window.setInterval func, ms

    inferCorrectPositionAttributeFromUserAgent: inferCorrectPositionAttributeFromUserAgent,
    delay: delay,
    repeat: repeat
  ])
