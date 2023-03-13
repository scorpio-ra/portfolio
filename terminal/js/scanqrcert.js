import QrScanner from "../libs/qr-scanner/qr-scanner.min.js";
QrScanner.WORKER_PATH = '../libs/qr-scanner/qr-scanner-worker.min.js';

const qrcam=document.getElementById('qrcam');

export function restart_qrscanner() {
    var certstatus=document.getElementById("covidCertStatus");
    clearErrors();
    printError("<p class='warning'>Отсканируйте корректный QR-код прививки или отредактируйте личные данные посетителя</p>",certstatus);
    $("#certDetails").empty();
    setInvisible(document.getElementById('certDetails'));
    qrcanvas.style.display="block";
    scanner.start();
        
}

function getCertv1Data(cert) {
    var cert1= new Object();
    cert1.Type="VACCINE_CERT";
    cert1.fio=cert.fio;
    cert1.birthday=cert.birthdate;
    cert1.passport="**** ******";
    cert1.status=cert.status;
    cert1.expiredAt=cert.expiredAt;
    return cert1
}

function getCertv2Data(cert) {
    var cert1= new Object();
    cert1.Type=cert.items[0].type;
    cert.items[0].attrs.forEach(function (item,i,arr) {
        if (item.type=="fio") {cert1.fio=item.value;}
        if (item.type=="birthDate") {cert1.birthday=item.value;}
        if (item.type=="passport") {cert1.passport=item.value;}
    });
    cert1.status=cert.items[0].status;
    cert1.expiredAt=cert.items[0].expiredAt;
    return cert1;
}

function getCertData(cert) {
    // Определяем, тип сертификата
    //var cert1= new Object();
    if (cert.hasOwnProperty('items')&& Array.isArray(cert.items) && cert.items[0].hasOwnProperty('type') &&((cert.items[0].type==="VACCINE_CERT")||(cert.items[0].type==="ILLNESS_FACT") )) {
        var cert1=getCertv2Data(cert);
    }
    if (cert.hasOwnProperty('unrz')) {
        var cert1=getCertv1Data(cert);
    }
    return cert1;
}

function checkCert(msg) {
    //console.log(cert);
    $("#certDetails").empty();
    setInvisible(document.getElementById("certDetails"));
    var certstatus=document.getElementById("covidCertStatus");
    var cert1=getCertData(msg);
    console.log(cert1);
    var certCorrect=true;
    // Сравниваем полученные данные
    if (cert1.hasOwnProperty('Type') && ((cert1.Type=="VACCINE_CERT")||(cert1.Type=="ILLNESS_FACT"))) {
        // Выводим данные о сертификате
        $("#certDetails").append("<p class='lbl'>ФИО:</p><p>"+cert1.fio+"</p>");
        $("#certDetails").append("<p class='lbl'>Дата рождения:</p><p>"+cert1.birthday+"</p>");
        $("#certDetails").append("<p class='lbl'>Паспорт:</p><p>"+cert1.passport+"</p>");
        $("#certDetails").append("<p class='lbl'>Действителен до:</p><p>"+cert1.expiredAt+"</p>");
        setVisible(document.getElementById("certDetails"));
        if (cert1.status<1) {
            certCorrect=false;
            printError("<p class='warning'>Сертификат прививки недействителен</p>",certstatus);
        }
        // Сравниваем ФИО
        var fioarr=cert1.fio.split(' ');
        console.log(Client);
        var fioarrsrc=[Client.surname, Client.name];
        if ((fioarr[0][0].toUpperCase()!==fioarrsrc[0][0].toUpperCase()) || (fioarr[1][0].toUpperCase()!==fioarrsrc[1][0].toUpperCase())) {
            certCorrect=false;
            printError("<p class='warning'>Данные сертификата не соответствуют введенным данным посетителя</p>",certstatus);
        } else {
            // Сравниваем даты рождения
            if (cert1.birthday!=Client.birthday) {
                certCorrect=false;
                printError("<p class='warning'>Данные сертификата не соответствуют введенным данным посетителя</p>",certstatus);
            }
        }
    } else {
        certCorrect=false;
        printError("<p class='warning'>QR-код не является сертификатом профилактической прививки COVID-19</p>",certstatus);
    }
    if (certCorrect==true) {
        certstatus.innerHTML="<h4 class='verifiedcert green1'>Проверка сертификата прививки от COVID-19 завершена успешно</h4>";
        covidCertValidated=true;
        setTimeout(()=> $('#b-next-step').trigger('click'),3000);
    } else {
        covidCertValidated=false;
        setTimeout(restart_qrscanner,5000);
        
    }
}

async function getCovidCert(result) {
        scanner.stop();
        var certstatus=document.getElementById("covidCertStatus");
        qrcanvas.style.display="none";
        var a=result.indexOf('https://www.gosuslugi.ru/');
        if (a==0) {
            var apiaddr="";
            let c=result.indexOf('vaccine/cert/verify');
            if (c>0) {
                apiaddr='https://www.gosuslugi.ru/api/vaccine/v1/cert/verify/';
            } else {
                c=result.indexOf('covid-cert/verify');
                if (c>0) {
                    apiaddr='https://www.gosuslugi.ru/api/covid-cert/v2/cert/check/';
                }
            }

            var b=result.lastIndexOf('/');
            var paramaddr=result.substr(b);
            var apiurl=apiaddr.concat(paramaddr);
            $("#loading-overlay").show();
            try {
            await $.ajax({            
                type: "Get",
                url: apiurl,
                dataType: "json",
                success: function (msg, textStatus) {
                    checkCert(msg);
                },
                error: function (xmlHttpRequest, textStatus, errorThrown) {
                    printError("<p class='warning'>Ошибка связи с порталом Госуслуг. Повторите сканирование</p>");
                    setTimeout(restart_qrscanner,5000);
                }
            }); }catch (error) {
             $("#loading-overlay").hide();
            } finally {
            $("#loading-overlay").hide();
            }
        } else {
            clearErrors();
            printError("<p class='warning'>QR-код не является кодом сертификата прививки COVID-19</p>",certstatus);
            setTimeout(restart_qrscanner,5000);
        }
}
function monitoringcovidValidated() {
    if ((covidCertValidated==false)&&(oldcovidCertValidated==true)) {restart_qrscanner();}
    if (covidCertValidated!==oldcovidCertValidated) {oldcovidCertValidated=covidCertValidated;}
}
const scanner = new QrScanner(qrcam, result => getCovidCert(result));
scanner.start();
const qrcanvas=document.getElementById('qrcanvas');
qrcanvas.appendChild(scanner.$canvas);
var oldcovidCertValidated=covidCertValidated;
setInterval(monitoringcovidValidated,5000);
