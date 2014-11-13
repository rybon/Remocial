angular.module('mobile.filters', [])


  .filter('duration', [->
    (input) ->
      number = parseInt input
      seconds = minutes = hours = 0
      seconds = number % 60
      minutes = (number - seconds) / 60
      hours = (minutes - (minutes % 60)) / 60
      seconds = '0' + seconds.toString() if seconds < 10
      minutes = '0' + minutes.toString() if minutes < 10
      if hours is 0
        minutes + ':' + seconds
      else
        hours + ':' + minutes + ':' + seconds
  ])


  .filter('results', [->
    (input) ->
      number = parseInt input
      if number is 0 or number > 1
        number.toString() + ' results'
      else
        number.toString() + ' result'
  ])


  .filter('cleanup', [->
    (input) ->
      clean = input
      if /_/.test input
        clean = input.replace '_', ' '
      clean
  ])