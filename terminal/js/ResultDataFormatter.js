"use strict";
class ResultDataFormatter {
  constructor() {
    var fieldNamesForCardInfo = {
      card: "Номер карты",
      bonus: "Бонусы",
      bonusI: "Бонусы н/а",
      points: "Очки",
      moneyCash: "Деньги наличные",
      moneyBCard: "Деньги банковская карта",
      moneyCS: "Деньги безналичные",
      tickets: "Тикеты",
      moneyAccum: "Потрачено",
      cardPrice: "Цены карты",
      level: "Уровень",
      state: "Статус карты",
      activation: "Дата и время активации"
    };

    var fieldNamesForCardOwner = {
      card: "Номер карты",
      first_name: "Имя",
      last_name: "Фамилия",
      middle_name: "Отчество",
      birthday: "Дата рождения",
      gender: "Возраст",
      phone: "Телефон",
      email: "EMail",
      address: "Адрес"
    };

    var fieldNamesForCardHistory = {
      date: "Дата и время операции",
      name: "Наименование операции",
      value: "Значение",
      u1code: "",
      u2code: ""
    };

    var fieldNamesForCardDeposit = {
      orderNo: "Номер операции",
      points: "Баланс карты после пополнения",
      bonus: "Бонусы, начисленные за пополнение"
    };

    var fieldNamesForCardCancelDeposit = {};

    var dateTimeFormatOptions = {
      year: "numeric",
      month: "numeric",
      day: "numeric",
      hour: "numeric",
      minute: "numeric",
      second: "numeric",
      hour12: false
    };

    function GetFromDictionary(dictionary, value) {
      if (dictionary !== undefined) if (value in dictionary) return dictionary[value];
      return value;
    }

    function AsTable(data, dictionary) {
      var resultHtml = "";
      if (!Array.isArray(data)) return resultHtml;
      if (data.length <= 0) return resultHtml;
      var propList = Array();
      for (var property in data[0]) {
        if (data[0].hasOwnProperty(property)) {
          resultHtml += "<th>" + GetFromDictionary(dictionary, property) + "</th>";
          propList.push(property);
        }
      }
      resultHtml = '<thead class="thead-dark"><tr>' + resultHtml + "</tr></thead>";
      var bodyHtml = "";
      for (var row in data) {
        bodyHtml += '<tr class="table-active">';
        for (var prop in propList) {
          bodyHtml += "<td>";
          if (data[row].hasOwnProperty(propList[prop])) {
            bodyHtml += FormatValue(data[row][propList[prop]]);
          }
          bodyHtml += "</td>";
        }
        bodyHtml += "</tr>";
      }
      resultHtml += "<tbody>" + bodyHtml + "</tbody>";
      resultHtml = '<table class="table table-hover">' + resultHtml + "</table>";
      return resultHtml;
    }

    function AsCard(data, dictionary) {
      var resultHtml = "";
      if (data === undefined) return resultHtml;
      var propList = Array();
      resultHtml += '<table class="table table-as-card">';
      resultHtml += "<tbody>";
      for (var property in data) {
        if (data.hasOwnProperty(property)) {
          resultHtml +=
            '<tr class="table-active"><td><span class="font-weight-bold">' +
            GetFromDictionary(dictionary, property) +
            "</span></td><td>" +
            FormatValue(data[property]) +
            "</td></tr>";
          propList.push(property);
        }
      }
      resultHtml += "</tbody></table>";
      return resultHtml;
    }

    function FormatValue(value) {
      if (typeof value !== "string") return value;
      var date = new Date(Date.parse(value));
      if (!isNaN(date)) return date.toLocaleString("ru-RU", dateTimeFormatOptions);
      return value;
    }

    function AsSuccess(data, dictionary) {
      return "<h2>Отменено успешно</h2>";
    }

    this.GetHtml = function(command, data) {
      switch (command) {
        case commandCardHistory:
          return AsTable(data, fieldNamesForCardHistory);
        case commandCardInfo:
          return AsCard(data, fieldNamesForCardInfo);
        case commandCardOwner:
          return AsCard(data, fieldNamesForCardOwner);
        case commandCardDeposit:
          return AsCard(data, fieldNamesForCardDeposit);
        case commandCancelDeposit:
          return AsSuccess(data, fieldNamesForCardCancelDeposit);
        default:
          break;
      }
    };
  }
}
