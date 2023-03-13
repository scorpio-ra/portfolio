"use strict";

function LoaderUtils (url = `${baseUrl}/`) {
    var UrlApi = url;
    // routeParams - массив string
    // paramsObj - ключ->значение
    async function sendQuery (routeParams, paramsObj, successFunc, errorFunc, sendType, dataObj) {
        var generatedUrl = UrlApi;
        if (routeParams !== undefined) {
            if (Array.isArray(routeParams)) {
                generatedUrl += routeParams.join("/");
            }
        };
        if (paramsObj !== undefined) {
            var tempArray = Array();
            for (const key in paramsObj) {
                if (paramsObj.hasOwnProperty(key)) {
                    tempArray.push(key + "=" + paramsObj[key]);
                }
            }
            if (tempArray.length > 0)
                generatedUrl += "?" + tempArray.join("&");
        }
		//var datastr=JSON.stringify(dataObj);
        await $.ajax({
            //cache: false,
            type: sendType,
			//contentType: 'application/json; charset=utf-8',
            url: generatedUrl,
            dataType: "json",
			data: dataObj,
            success: function (msg, textStatus) {
                successFunc(msg);
            },
            error: function (xmlHttpRequest, textStatus, errorThrown) {
                errorFunc ();
            }
        });
    }
    // public
    this.sendQueryGet = async function  (routeParams, paramsObj, successFunc, errorFunc) {
        await sendQuery(routeParams, paramsObj, successFunc, errorFunc, "GET")
    }

    this.sendQueryPost = async function (routeParams, paramsObj, successFunc, errorFunc, dataObj) {
        await sendQuery(routeParams, paramsObj, successFunc, errorFunc, "POST", dataObj)
    }
}