﻿
&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	
	ТекстДляЗапроса = 
	"ВЫБРАТЬ
	|	Код,Наименование,Предопределенный
	|ИЗ СПРАВОЧНИК.Валюты 
	|	Где Наименование = &Рубль";
	
	ТекстЗапроса.УстановитьТекст(ТекстДляЗапроса);
	
	СтрокаПараметров = ПараметрыЗапроса.Добавить();
	СтрокаПараметров.ИмяПараметра = "Рубль";
	СтрокаПараметров.ЗначениеПараметра = "Рубль";

	
КонецПроцедуры

&НаСервере
Процедура ПолучитьДанныеЗапросаНаСервере(JSON = ложь)
	ТипЗапрос = ФабрикаXDTO.Тип("http://www.1cnw.ru/query", "Запрос");
	ТипПараметрЗапроса = ФабрикаXDTO.Тип("http://www.1cnw.ru/query", "ПараметрЗапроса");
	
	Запрос = ФабрикаXDTO.Создать(ТипЗапрос);
	Запрос.Текст = ТекстЗапроса.ПолучитьТекст();
	Запрос.Упрощенный = Упрощенный;
	
	Для каждого Строка Из ПараметрыЗапроса Цикл
	
		ПараметрЗапроса = ФабрикаXDTO.Создать(ТипПараметрЗапроса);
		ПараметрЗапроса.Имя		 = Строка.ИмяПараметра;
		ПараметрЗапроса.Значение = "S"+Строка.ЗначениеПараметра;
		Запрос.Параметры.Добавить(ПараметрЗапроса);
	
	КонецЦикла;
	Ответ = СЗ_ПЗ_ОбщийМодуль.ВыполнитьЗапрос(Запрос, JSON);
	Для каждого Колонка Из Ответ.Колонки Цикл
	
		ТипКолонки = "Тип неизвестен";
		Если Колонка.Булево Тогда
			ТипКолонки = "Булево";
		ИначеЕсли Колонка.Строка Тогда
			ТипКолонки = "Строка";
		ИначеЕсли Колонка.Дата Тогда
			ТипКолонки = "Дата";
		ИначеЕсли Колонка.Число Тогда
			ТипКолонки = "Число";
		ИначеЕсли Колонка.Ссылка Тогда
			ТипКолонки = "Ссылка";
		ИначеЕсли Колонка.УникальныйИдентификатор Тогда
			ТипКолонки = "УникальныйИдентификатор";
		ИначеЕсли Колонка.ХранилищеЗначения Тогда
			ТипКолонки = "ХранилищеЗначения";
		КонецЕсли; 
		Сообщить("Колонка:  " + Колонка.Имя + ". Тип: " + ТипКолонки);
	
	КонецЦикла;
	Если Не JSON Тогда
	
		ДанныеОтСервера = ЗначениеИзСтрокиВнутр(Ответ.Результат);
	
	КонецЕсли; 
	РезультатЗапроса.УстановитьТекст(Ответ.Результат);
	Элементы.ГруппаСтраницы.ТекущаяСтраница = Элементы.ГруппаРезультат;
	
КонецПроцедуры

&НаКлиенте
Процедура ПолучитьДанныеЗапроса(Команда)
	ПолучитьДанныеЗапросаНаСервере();
КонецПроцедуры

&НаКлиенте
Процедура ПолучитьДанныеЗапросаJSON(Команда)
	ПолучитьДанныеЗапросаНаСервере(Истина);
КонецПроцедуры

&НаКлиенте
Процедура ПростойЗапрос(Команда)
	ПростойЗапросСервер();
	
КонецПроцедуры

&НаСервере
Процедура ПростойЗапросСервер()
	
	Запрос = новый HTTPЗапрос;
	Запрос.УстановитьТелоИзСтроки(ТекстЗапроса.ПолучитьТекст());
	Ответ = СЗ_ПЗ_ОбщийМодуль.ПолучитьРезультатЗапросаВJSON(Запрос);
	РезультатЗапроса.УстановитьТекст(Ответ.ПолучитьТелоКакСтроку());
	Если не Ответ.КодСостояния = 200 Тогда
	
		ВызватьИсключение "Ошибка " + Ответ.ПолучитьТелоКакСтроку();
	
	КонецЕсли; 
	
КонецПроцедуры

