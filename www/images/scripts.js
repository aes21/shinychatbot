// Base scripts

// modal overlay
Shiny.addCustomMessageHandler("modalBackdrop", function(message) {
  setTimeout(function() {
    $('.modal-backdrop').removeClass('startup-backdrop login-backdrop');
    
    if (message.type === "login") {
      $('.modal-backdrop').addClass('login-backdrop');
    } else {
      $('.modal-backdrop').addClass('startup-backdrop');
    }
  }, 100);
});

// message enter key entry
$(document).on('keydown', '[id$="user_input"]', function(e) {
  if (e.keyCode === 13 && !e.shiftKey) {
    e.preventDefault();
    setTimeout(function() {
      $('[id$="send_btn"]').click();
    }, 50);
  }
});

// automatic chat scroll
Shiny.addCustomMessageHandler('scrollCallback', function(baseline) {
  setTimeout(function() {
    var chat = document.getElementById('chat-chat-container');
    if (chat) {
      chat.scrollTop = chat.scrollHeight;
    }
  }, 1800); // delay to allow DOM update
});

// loading overlay
Shiny.addCustomMessageHandler("startChatLoad", function(message) {
  $('div#divLoading').addClass('show');
  $('#overlay').fadeIn(200);
});

Shiny.addCustomMessageHandler("stopChatLoad", function(message) {
  $('div#divLoading').removeClass('show');
  $('#overlay').fadeOut(200);
});

// login failure
Shiny.addCustomMessageHandler("loginError", function(message) {
  setTimeout(function() {
    $('.authenticator input[type="text"]').addClass('login-error');
  }, 100);
});