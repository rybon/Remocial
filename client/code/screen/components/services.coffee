angular.module('screen.services', [])


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