// Server-side Code

var env = (process.env.VIMEO_KEY && process.env.VIMEO_SECRET) ? process.env : require('node-env-file')(__dirname + '../../../.env'),
    vimeo = require('vimeo')(process.env.VIMEO_KEY, process.env.VIMEO_SECRET),
    _ = require('underscore');

var screens = {};
var users = {};
function generateFourDigits() {
  return _.random(1000, 9999).toString();
}
function getScreenCode() {
  var code = generateFourDigits();
  if(!screens[code]) {
    screens[code] = {};
    return code;
  } else {
    return getScreenCode();
  }
}
function deleteScreenCode(code) {
  delete screens[code];
}
function activateScreen(req) {
  req.session.screenCode = getScreenCode();
  req.session.save(function(err) {
    req.session.channel.subscribe(req.session.screenCode);
  });
}
function deactivateScreen(req) {
  req.session.channel.unsubscribe(req.session.screenCode);
  deleteScreenCode(req.session.screenCode);
  delete req.session.screenCode;
}
function activateRemote(code, req, ss) {
  if(screens[code] && !screens[code].superUser) {
    screens[code].superUser = req.session.userId;
    ss.publish.channel(code, 'ss-remoteConnected');
    req.session.screenCode = code;
    req.session.save(function(err) {
      req.session.channel.subscribe(req.session.screenCode);
    });
    return true;
  } else {
    return false;
  }
}
function deactivateRemote(req, ss) {
  if(screens[req.session.screenCode] && screens[req.session.screenCode].superUser === req.session.userId) {
    ss.publish.channel(req.session.screenCode, 'ss-remoteDisconnected');
    req.session.channel.unsubscribe(req.session.screenCode);
    delete screens[req.session.screenCode].superUser;
    delete req.session.screenCode;
    return true;
  } else {
    return false;
  }
}
function resetRemote(req, ss) {
  ss.publish.channel(req.session.screenCode, 'ss-screenDisconnected');
  return true;
}
function processCommand(data, req, ss) {
  if(screens[req.session.screenCode] && screens[req.session.screenCode].superUser === req.session.userId) {
    ss.publish.channel(req.session.screenCode, 'ss-playerCommand', data);
    return true;
  } else {
    return false;
  }
}
function processStatus(data, req, ss) {
  if(screens[req.session.screenCode] && screens[req.session.screenCode].superUser) {
    ss.publish.channel(req.session.screenCode, 'ss-playerStatus', data);
    return true;
  } else {
    return false;
  }
}
function processSearch(data, req, ss) {
  vimeo.videos('search', data, function(err, results) {
    if(!err) {
      ss.publish.user(req.session.userId, 'ss-searchResults', results);
    } else {
      console.log(err);
      ss.publish.user(req.session.userId, 'ss-searchErrors', err);
    }
  });
  return true;
}
// var cache = false;
// function processSearch(data, req, ss) {
//   if(!cache) {
//     vimeo.videos('search', data, function(err, results) {
//       if(!err) {
//         cache = results;
//         ss.publish.all('ss-searchResults', results);
//       } else {
//         console.log(err);
//         ss.publish.all('ss-searchErrors', err);
//       }
//     });
//   } else {
//     setTimeout(function() {
//       console.log('from cache');
//       ss.publish.all('ss-searchResults', cache);
//     }, 2000);
//   }
//   return true;
// }
function processVideo(id, req, ss) {
  if(screens[req.session.screenCode] && screens[req.session.screenCode].superUser === req.session.userId) {
    ss.publish.channel(req.session.screenCode, 'ss-selectVideo', id);
    return true;
  } else {
    return false;
  }
}
function processUser(fbUserId, req, ss) {
  users[fbUserId] = req.session.userId;
  ss.publish.channel(fbUserId, 'ss-userStatus', fbUserId);
  return true;
}
function processFriends(fbFriendIds, req, ss) {
  req.session.channel.subscribe(fbFriendIds);
  return true;
}
function offerRemote(fbUserId, fbFriendId, req, ss) {
  ss.publish.channel(fbUserId, 'ss-offerRemote', { from: fbUserId, to: fbFriendId });
  return true;
}
function acceptRemote(fbUserId, fbFriendId, req, ss) {
  ss.publish.channel(fbUserId, 'ss-acceptRemote', { from: fbUserId, to: fbFriendId });
  return true;
}
function transferRemote(fbUserId, fbFriendId, videoData, req, ss) {
  var code = req.session.screenCode;
  if(screens[code] && screens[code].superUser === users[fbUserId]) {
    req.session.channel.unsubscribe(code);
    delete screens[code].superUser;
    ss.publish.channel(fbUserId, 'ss-transferRemote', { from: fbUserId, to: fbFriendId, code: code, videoData: videoData });
    return true;
  } else {
    return false;
  }
}

// Define actions which can be called from the client using ss.rpc('rtc.ACTIONNAME', param1, param2...)
exports.actions = function(req, res, ss) {

  // Example of pre-loading sessions into req.session using internal middleware
  req.use('session');

  // output all incoming requests to the console in cyan
  //req.use('debug', 'cyan');

  // Uncomment line below to use the middleware defined in server/middleware/before
  req.use('before.authenticated')

  return {
    requestCodeForScreen: function() {
      if(!req.session.screenCode) {
        activateScreen(req);
      } else {
        deactivateScreen(req);
        activateScreen(req);
      }
      return res(req.session.screenCode);
    },
    connectRemoteToScreen: function(code) {
      return res(activateRemote(code, req, ss));
    },
    disconnectRemoteFromScreen: function() {
      return res(deactivateRemote(req, ss));
    },
    disconnectScreenFromRemote: function() {
      return res(resetRemote(req, ss));
    },
    sendPlayerCommandToScreen: function(data) {
      return res(processCommand(data, req, ss));
    },
    sendPlayerStatusToRemote: function(data) {
      return res(processStatus(data, req, ss));
    },
    searchVideosOnVimeo: function(data) {
      return res(processSearch(data, req, ss));
    },
    selectVideo: function(id) {
      return res(processVideo(id, req, ss));
    },
    publishUser: function(fbUserId) {
      return res(processUser(fbUserId, req, ss));
    },
    subscribeToFriends: function(fbFriendIds) {
      return res(processFriends(fbFriendIds, req, ss));
    },
    offerRemoteToFriend: function(fbUserId, fbFriendId) {
      return res(offerRemote(fbUserId, fbFriendId, req, ss));
    },
    acceptRemoteFromFriend: function(fbUserId, fbFriendId) {
      return res(acceptRemote(fbUserId, fbFriendId, req, ss));
    },
    transferRemoteToFriend: function(fbUserId, fbFriendId, videoData) {
      return res(transferRemote(fbUserId, fbFriendId, videoData, req, ss));
    }
  };
};
