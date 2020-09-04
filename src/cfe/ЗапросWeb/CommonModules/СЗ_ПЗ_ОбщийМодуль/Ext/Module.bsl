﻿#Область ОбработчикиСобытий

Функция ВыполнитьЗапрос(ВебЗапрос, ОтветВJSON = Ложь) Экспорт
	
	// 1. Инициализация ответа
	ТипОтвет = ФабрикаXDTO.Тип("http://www.1cnw.ru/query", "Ответ");
	ТипКолонкаОтвета = ФабрикаXDTO.Тип("http://www.1cnw.ru/query", "Колонка");
	
	Ответ = ФабрикаXDTO.Создать(ТипОтвет);
	Ответ.Ошибка = "";
	Ответ.Результат = "";
	
	// 2. Инициализация запроса
	Запрос = Новый Запрос;
	Запрос.Текст = ВебЗапрос.Текст;
	
	Параметры = Параметры(ВебЗапрос.Параметры, Ответ.Ошибка);
	
	Если Не Ответ.Ошибка = "" Тогда
		Возврат Ответ;
	КонецЕсли;
	
	Для Каждого Параметр Из Параметры Цикл
		Запрос.УстановитьПараметр(Параметр.Ключ, Параметр.Значение);
	КонецЦикла;
	
	// 3. Выполнение запроса
	Попытка
		РезультатЗапроса = Запрос.Выполнить();
	Исключение
		Ответ.Ошибка = ОписаниеОшибки();
		
		Возврат Ответ;
	КонецПопытки;
	
	// 4. Получение данных запроса
	Если ВебЗапрос.Упрощенный Тогда
		Результат = РезультатЗапроса.Выгрузить();
	Иначе
		// Преобразование ссылочных типов
		Выборка = РезультатЗапроса.Выбрать();
		Результат = Новый ТаблицаЗначений;
	КонецЕсли;
	
	КолонкиЗапроса = Новый Массив;
	Для Каждого Колонка Из РезультатЗапроса.Колонки Цикл
		КолонкиЗапроса.Добавить(Новый Структура("Имя, ТипЗначения, Метод", Колонка.Имя, Колонка.ТипЗначения));
	КонецЦикла;
	
	Для Каждого ДопКолонка Из ВебЗапрос.ДополнительныеКолонки Цикл
		СтруктураКолонки = Новый Структура("Имя, ТипЗначения, Метод", ДопКолонка.Имя, Новый ОписаниеТипов, ДопКолонка.Метод);
		КолонкиЗапроса.Добавить(СтруктураКолонки);
	КонецЦикла;
	
	ЗаполнитьКолонкиОтвета(КолонкиЗапроса, Ответ, Результат, ТипКолонкаОтвета, ВебЗапрос.Упрощенный);
	Если Не ПустаяСтрока(Ответ.Ошибка) Тогда
	
		Возврат Ответ;
	
	КонецЕсли; 
	
	// 7. Заполнение результата ответа (для не упрощенного услучая)
	Если Не ВебЗапрос.Упрощенный Тогда
		// 7.1 Сбор сведений о перечислениях
		ЗначенияПеречислений = Новый Соответствие;
		
		Для Каждого ПеречислениеМД Из Метаданные.Перечисления Цикл
			Значение = Новый Структура("Тип, Значение", "Перечисление." + ПеречислениеМД.Имя, "");
			ЗначенияПеречислений.Вставить(Перечисления[ПеречислениеМД.Имя].ПустаяСсылка(), Значение);
			
			Для Каждого ЗначениеПеречисления Из ПеречислениеМД.ЗначенияПеречисления Цикл
				Значение = Новый Структура("Тип, Значение", "Перечисление." + ПеречислениеМД.Имя, ЗначениеПеречисления.Имя);
				ЗначенияПеречислений.Вставить(Перечисления[ПеречислениеМД.Имя][ЗначениеПеречисления.Имя], Значение);
			КонецЦикла;
		КонецЦикла;
		
		ЗаполнитьТаблицуРезультата(Выборка, ЗначенияПеречислений, КолонкиЗапроса, Результат);
	КонецЕсли;
	
	Если ОтветВJSON Тогда
	
		Ответ.Результат = СформироватьJSON(ТаблицаЗначенийВМассив(Результат));
	
	Иначе
	
		Ответ.Результат = ЗначениеВСтрокуВнутр(Результат);
	
	КонецЕсли; 
	
	Возврат Ответ;
	
КонецФункции

Функция ПолучитьРезультатЗапросаВJSON(Знач Запрос) Экспорт
	
	Перем ЗапросВыполненСОшибками, Ответ, СтруктураОтвета, ТекстЗапроса, ТекстОтвета, ФормированиеJSONВыполненоСОшибками;
	
	// Создаем структуру ответа, которая состоит из статуса и ответа
	СтруктураОтвета = Новый Структура("status, response");
	
	Если ТипЗнч(Запрос) = Тип("HTTPЗапрос") Тогда
	
		ТекстЗапроса = Запрос.ПолучитьТелоКакСтроку();
	
	Иначе
	
		ТекстЗапроса = Запрос.ПолучитьТелоКакСтроку(КодировкаТекста.UTF8);
	
	КонецЕсли; 
	
	ЗапросВыполненСОшибками = Ложь;
	ФормированиеJSONВыполненоСОшибками = Ложь;
	// Выполняем запрос
	Попытка
		СтруктураОтвета.response = ВыполнитьЗапросБезПараметров(ТекстЗапроса);
	Исключение
		Ответ = ПодготовитьОтвет(403, "Ошибка во время выполнения запроса. " + ОписаниеОшибки(), Истина);
		ЗапросВыполненСОшибками = Истина;
	КонецПопытки;
	Если Не ЗапросВыполненСОшибками Тогда
		
		// Переводим в JSON
		Попытка
			СтруктураОтвета.status = "ОК";
			ТекстОтвета = СформироватьJSON(СтруктураОтвета);
		Исключение
			Ответ = ПодготовитьОтвет(403, "Ошибка во время формирования JSON", Истина);
			ФормированиеJSONВыполненоСОшибками = Истина;
		КонецПопытки;
		Если Не ФормированиеJSONВыполненоСОшибками Тогда
			
			Ответ = ПодготовитьОтвет(200, ТекстОтвета);
			
		КонецЕсли; 
		
	КонецЕсли;
	Возврат Ответ;

КонецФункции

#КонецОбласти

#Область ВспомогательныеПроцедурыИФункции

Функция ПривестиПараметр(Значение)
	
	ПараметрНеТребуетПриведения = ТипЗнч(Значение) = Тип("NULL") 
		Или ТипЗнч(Значение) = Тип("Неопределено") 
		Или ТипЗнч(Значение) = Тип("Булево")
		Или ТипЗнч(Значение) = Тип("Дата") 
		Или ТипЗнч(Значение) = Тип("Число") 
		Или ТипЗнч(Значение) = Тип("УникальныйИдентификатор");
	Если ПараметрНеТребуетПриведения Тогда
		Возврат Значение;
	ИначеЕсли Не ТипЗнч(Значение) = Тип("Строка") Тогда
		ВызватьИсключение "Неверное значение параметра ";
	ИначеЕсли Лев(Значение, 1) = "S" Тогда
		Возврат Сред(Значение, 2);
	ИначеЕсли Лев(Значение, 1) = "#" Тогда
		Позиция = СтрНайти(Значение, ":");
		Если Позиция = 0 Тогда
			ВызватьИсключение "Неверное значение параметра ";
		КонецЕсли;
		
		ТипЗначение = Сред(Значение, 2, Позиция - 2);
		УникальныйИдентификатор = Сред(Значение, Позиция + 1);
		
		Попытка
			Менеджер = Новый(Тип(СтрЗаменить(ТипЗначение, ".", "Менеджер.")));
			Возврат Менеджер.ПолучитьСсылку(Новый УникальныйИдентификатор(УникальныйИдентификатор));
		Исключение
			ВызватьИсключение "Неверное значение параметра ";
		КонецПопытки;
	Иначе
		ВызватьИсключение "Неверное значение параметра ";
	КонецЕсли;
	
КонецФункции

Функция Параметры(ПараметрыВходящие, Ошибки)
	
	Параметры = Новый Структура;
	
	Для Каждого Параметр Из ПараметрыВходящие Цикл
		Попытка
			Если ТипЗнч(Параметр.Значение) = Тип("Строка") И Лев(Параметр.Значение, 1) = "A" Тогда
				Массив = ЗначениеИзСтрокиВнутр(Сред(Параметр.Значение, 2));
				Если Не ТипЗнч(Массив) = Тип("Массив") Тогда
					ВызватьИсключение "Неверное значение параметра ";
				КонецЕсли;
				
				Значение = Новый Массив;
				Для Каждого Элемент Из Массив Цикл
					Значение.Добавить(ПривестиПараметр(Элемент));
				КонецЦикла;
			Иначе
				Значение = ПривестиПараметр(Параметр.Значение);
			КонецЕсли;
		Исключение
			Ошибки = Ошибки + Символы.ПС + ОписаниеОшибки() + " """ + Параметр.Имя + """!";
		КонецПопытки;
		
		Параметры.Вставить(Параметр.Имя, Значение);
	КонецЦикла;
	
	Возврат Параметры;
	
КонецФункции

Функция ВычислитьЗначениеКолонки(Метод, ДанныеСтроки)
	
	Возврат Вычислить(Метод);
	
КонецФункции

Процедура ЗаполнитьТаблицуРезультата(Выборка, Знач ЗначенияПеречислений, Знач КолонкиЗапроса, Результат)
	
	Перем Значение, ЗначениеМД, Колонка, Строка;
	
	// 7.2 Заполнение таблицы результата
	Пока Выборка.Следующий() Цикл
		Строка = Результат.Добавить();
		
		Для Каждого Колонка Из КолонкиЗапроса Цикл
			
			Если Колонка.Метод = Неопределено Тогда
				Значение = Выборка[Колонка.Имя];
			Иначе
				Значение = ВычислитьЗначениеКолонки(Колонка.Метод, Выборка);
			КонецЕсли;
			
			Если Не ЗначенияПеречислений[Значение] = Неопределено Тогда
				Значение = ЗначенияПеречислений[Значение];
			ИначеЕсли ТипЗнч(Значение) = Тип("ХранилищеЗначения") Тогда
				Значение = Новый Структура("Тип, Значение", "ХранилищеЗначения", ЗначениеВСтрокуВнутр(Значение));
			Иначе
				Попытка
					ЗначениеМД = Значение.Метаданные();
				Исключение
					ЗначениеМД = Неопределено;
				КонецПопытки;
				
				Если Не ЗначениеМД = Неопределено Тогда
					Значение = Новый Структура("Тип, Значение", ЗначениеМД.ПолноеИмя(), Значение.УникальныйИдентификатор());
				КонецЕсли;
			КонецЕсли;
			
			Строка[Колонка.Имя] = Значение;
		КонецЦикла;
	КонецЦикла;

КонецПроцедуры

Функция РаботаСТипомДанных(Знач Колонка, КолонкаОтвета)
	
	Перем ПустоеЗначение, Тип, ТипМетаданные, Типы, ТипыРезультат;
	
	Типы = Колонка.ТипЗначения.Типы();
	ТипыРезультат = Новый Массив;
	
	Для Каждого Тип Из Типы Цикл
		Если Тип = Тип("NULL") Тогда
			// Отсутствие значения
			ТипыРезультат.Добавить(Тип("NULL"));
		ИначеЕсли Тип = Тип("Булево") Тогда
			КолонкаОтвета.Булево = Истина;
			ТипыРезультат.Добавить(Тип("Булево"));
		ИначеЕсли Тип = Тип("Дата") Тогда
			КолонкаОтвета.Булево = Истина;
			ТипыРезультат.Добавить(Тип("Дата"));
		ИначеЕсли Тип = Тип("Строка") Тогда
			КолонкаОтвета.Строка = Истина;
			ТипыРезультат.Добавить(Тип("Строка"));
		ИначеЕсли Тип = Тип("УникальныйИдентификатор") Тогда
			КолонкаОтвета.УникальныйИдентификатор = Истина;
			ТипыРезультат.Добавить(Тип("УникальныйИдентификатор"));
		ИначеЕсли Тип = Тип("ХранилищеЗначения") Тогда
			КолонкаОтвета.ХранилищеЗначения = Истина;
			ТипыРезультат.Добавить(Тип("Структура"));
		ИначеЕсли Тип = Тип("Число") Тогда
			КолонкаОтвета.Число = Истина;
			ТипыРезультат.Добавить(Тип("Число"));
		Иначе
			Попытка
				ПустоеЗначение = Новый(Тип);
				ТипМетаданные = ПустоеЗначение.Метаданные();
				
				КолонкаОтвета.Ссылка = Истина;
				ТипыРезультат.Добавить(Тип("Структура"));
			Исключение
				ВызватьИсключение "Неизвестный тип " + Тип + "!" + ОписаниеОшибки();
			КонецПопытки;
		КонецЕсли;
	КонецЦикла;
	Возврат ТипыРезультат;

КонецФункции

Процедура ЗаполнитьКолонкиОтвета(Знач КолонкиЗапроса, Ответ, Результат, Знач ТипКолонкаОтвета, Упрощенный = Ложь)
	
	Перем Колонка, КолонкаОтвета, ТипыРезультат;
	
	// 6. Заполнение колонок ответа
	Для Каждого Колонка Из КолонкиЗапроса Цикл
		КолонкаОтвета = ФабрикаXDTO.Создать(ТипКолонкаОтвета);
		КолонкаОтвета.Имя = Колонка.Имя;
		
		КолонкаОтвета.Булево = Ложь;
		КолонкаОтвета.Дата = Ложь;
		КолонкаОтвета.Строка = Ложь;
		КолонкаОтвета.Ссылка = Ложь;
		КолонкаОтвета.УникальныйИдентификатор = Ложь;
		КолонкаОтвета.ХранилищеЗначения = Ложь;
		КолонкаОтвета.Число = Ложь;
		
		ТипыРезультат = РаботаСТипомДанных(Колонка, КолонкаОтвета);
		
		Ответ.Колонки.Добавить(КолонкаОтвета);
		
		Если Не Упрощенный Тогда
			Попытка
				Результат.Колонки.Добавить(Колонка.Имя, Новый ОписаниеТипов(ТипыРезультат));
			Исключение
				Ответ.Ошибка = ОписаниеОшибки() + " """ + Колонка.Имя + """!";
				Прервать;
			КонецПопытки;
		КонецЕсли;
	КонецЦикла;

КонецПроцедуры

#КонецОбласти

#Область ВспомогательныеФункцииJSON

Функция СформироватьJSON(Данные)
	
	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку(Новый ПараметрыЗаписиJSON(ПереносСтрокJSON.Авто, Символы.Таб));
	
	ПараметрыЗаписиJSON = Новый ПараметрыЗаписиJSON( , Символы.Таб);
	
	НастройкиСериализацииJSON = Новый НастройкиСериализацииJSON;
	НастройкиСериализацииJSON.ВариантЗаписиДаты = ВариантЗаписиДатыJSON.ЛокальнаяДата;
	НастройкиСериализацииJSON.ФорматСериализацииДаты = ФорматДатыJSON.ISO;
	
	ЗаписатьJSON(ЗаписьJSON, Данные, НастройкиСериализацииJSON);
	
	Возврат ЗаписьJSON.Закрыть();
	
КонецФункции

Функция ПодготовитьОтвет(Знач КодОтвета, Знач СтруктураОтвета, Знач Ошибка = ложь)
	
	Ответ = Новый HTTPСервисОтвет(КодОтвета);
	Если Ошибка Тогда
		Ответ.Заголовки.Вставить("Content-Type", "text/html;charset=utf-8");
		Ответ.УстановитьТелоИзСтроки(СтруктураОтвета, КодировкаТекста.UTF8);
	Иначе
		Ответ.Заголовки.Вставить("Content-Type", "application/json; charset=utf-8");
		Ответ.УстановитьТелоИзСтроки(СтруктураОтвета, КодировкаТекста.UTF8);
	КонецЕсли;
	Возврат Ответ;
	
КонецФункции

Функция ВыполнитьЗапросБезПараметров(ТекстЗапроса)
	
	Запрос = Новый Запрос;
	Запрос.Текст = ТекстЗапроса;
	
	Результат = Запрос.Выполнить().Выгрузить();
		
	Возврат ТаблицаЗначенийВМассив(Результат);
	
КонецФункции

Функция ТаблицаЗначенийВМассив(ТаблицаЗначений) Экспорт
	
	Массив = Новый Массив();
	СтруктураСтрокой = "";
	НужнаЗапятая = Ложь;
	Для Каждого Колонка Из ТаблицаЗначений.Колонки Цикл
		Если НужнаЗапятая Тогда
			СтруктураСтрокой = СтруктураСтрокой + ",";
		КонецЕсли;
		СтруктураСтрокой = СтруктураСтрокой + Колонка.Имя;
		НужнаЗапятая = Истина;
	КонецЦикла;
	Для Каждого Строка Из ТаблицаЗначений Цикл
		НоваяСтрока = Новый Структура(СтруктураСтрокой);
		ЗаполнитьЗначенияСвойств(НоваяСтрока, Строка);
		Массив.Добавить(НоваяСтрока);
	КонецЦикла;
	Возврат Массив;

КонецФункции

#КонецОбласти
