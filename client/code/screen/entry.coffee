# This file automatically gets called first by SocketStream and must always exist

# Make 'ss' available to all modules and the browser console
window.ss = require('socketstream')

require('/components/services')
require('/components/controllers')
require('/components/directives')
require('/components/filters')

window.screen = angular.module('screen', ['screen.services' ,'screen.controllers', 'screen.directives', 'screen.filters'])

ss.server.on 'disconnect', ->
  console.log('Connection down :-(')

ss.server.on 'reconnect', ->
  console.log('Connection back up :-)')

ss.server.on 'ready', ->
  console.log('Screen ready')