// Trigger photo take
function takePhoto() {
    var canvas = document.getElementById('photo');
    var context = canvas.getContext('2d');
    var video = document.getElementById('video');
    var newwidth=video.videoHeight/4*3;
    canvas.visibility='hidden';
    canvas.width=newwidth;
    canvas.height=video.videoHeight;
    var context = canvas.getContext('2d');
    context.drawImage(video, Math.round((video.videoWidth-newwidth)/2), 0, newwidth, video.videoHeight, 0,0,newwidth,video.videoHeight);
    canvas.style.width=video.height/4*3+'px';
    canvas.style.height=video.height+'px';
    canvas.visibility='normal';
}

// Put event listeners into place
window.addEventListener("DOMContentLoaded", function() {
    var canvas = document.getElementById('photo');
    var context = canvas.getContext('2d');
    // Grab elements, create settings, etc.
    var video = document.getElementById('video');
    var mediaConfig = {
        video: true
    };
    var errBack = function(e) {
        console.log('An error has occurred!', e)
    };

    // Put video listeners into place
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia(mediaConfig).then(function(stream) {
            //video.src = window.URL.createObjectURL(stream);
            video.srcObject = stream;
            video.play();
        });
    }

    /* Legacy code below! */
    else if (navigator.getUserMedia) { // Standard
        navigator.getUserMedia(mediaConfig, function(stream) {
            video.src = stream;
            video.play();
        }, errBack);
    } else if (navigator.webkitGetUserMedia) { // WebKit-prefixed
        navigator.webkitGetUserMedia(mediaConfig, function(stream) {
            video.src = window.webkitURL.createObjectURL(stream);
            video.play();
        }, errBack);
    } else if (navigator.mozGetUserMedia) { // Mozilla-prefixed
        navigator.mozGetUserMedia(mediaConfig, function(stream) {
            video.src = window.URL.createObjectURL(stream);
            video.play();
        }, errBack);
    }


}, false);