# This file automatically gets called first by SocketStream and must always exist

# Make 'ss' available to all modules and the browser console
window.ss = require('socketstream')

require('/components/services')
require('/components/controllers')
require('/components/directives')
require('/components/filters')

window.mobile = angular.module('mobile', ['mobile.services', 'mobile.controllers', 'mobile.directives', 'mobile.filters'])

ss.server.on 'disconnect', ->
  console.log('Connection down :-(')

ss.server.on 'reconnect', ->
  console.log('Connection back up :-)')

ss.server.on 'ready', ->
  console.log('Mobile ready')