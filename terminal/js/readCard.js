"use strict";
var rc_str="";
function getCardNumberFromMagnet(str) {
    var arr=str.split('=');
    if (arr.length<5) {return "0";}
    var cardnum=arr[2];
    if (cardnum.length==6) {
        return cardnum;
    } else {
        return "0";
    }
}
// функция считывания символа
function readCard(evt) {
    if (evt.key=="Enter") {
        var cardnum=getCardNumberFromMagnet(rc_str);
        rc_str="";
        return cardnum;
    } else {
        rc_str = rc_str + String(evt.key);
        return "0";
    }
}