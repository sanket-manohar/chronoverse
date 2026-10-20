/// Localisation data used by the formatter, parser and widgets.
///
/// Chronoverse ships its own compact locale tables instead of depending on
/// a separate localisation library, which keeps the package dependency-free. Register your own with
/// [ChronoLocale.register] or tweak a built-in one with [copyWith].
library;

/// Units used by relative-time formatting.
enum ChronoUnit {
  /// Seconds.
  second,

  /// Minutes.
  minute,

  /// Hours.
  hour,

  /// Days.
  day,

  /// Weeks.
  week,

  /// Months.
  month,

  /// Years.
  year,
}

/// How a language picks a plural form from a count.
enum PluralRule {
  /// One form for every count (Chinese, Japanese, Korean, Turkish...).
  none,

  /// `[one, other]`: one for 1, other otherwise (English, German...).
  oneOther,

  /// `[one, other]`: one for 0 and 1 (French, Portuguese, Hindi...).
  zeroOneOther,

  /// `[one, few, many]` East-Slavic rule (Russian, Ukrainian).
  slavic,

  /// `[one, two, few, other]` simplified Arabic rule.
  arabic,
}

/// Localised words and conventions for one language.
class ChronoLocale {
  /// Creates a locale. Lists of weekdays always start with Monday.
  const ChronoLocale({
    required this.code,
    required this.monthNames,
    required this.monthShortNames,
    required this.weekdayNames,
    required this.weekdayShortNames,
    required this.weekdayNarrowNames,
    required this.amPm,
    required this.firstDayOfWeek,
    required this.strings,
    required this.unitNames,
    required this.relativeFuture,
    required this.relativePast,
    this.pluralRule = PluralRule.oneOther,
    this.isRtl = false,
    this.nativeDigits,
    this.defaultDatePattern = 'dd/MM/yyyy',
    this.weekendDays = const {DateTime.saturday, DateTime.sunday},
  });

  /// BCP-47 language code, e.g. `en`, `hi`, `pt`.
  final String code;

  /// Full month names, January first.
  final List<String> monthNames;

  /// Abbreviated month names.
  final List<String> monthShortNames;

  /// Full weekday names, Monday first.
  final List<String> weekdayNames;

  /// Abbreviated weekday names, Monday first.
  final List<String> weekdayShortNames;

  /// One or two letter weekday names, Monday first.
  final List<String> weekdayNarrowNames;

  /// `[am, pm]` markers.
  final List<String> amPm;

  /// Usual first day of the week ([DateTime.monday]..[DateTime.sunday]).
  final int firstDayOfWeek;

  /// Whether the language is written right to left.
  final bool isRtl;

  /// Ten digit characters (0–9) when the script has its own numerals.
  final List<String>? nativeDigits;

  /// Pattern used by date fields when none is given.
  final String defaultDatePattern;

  /// Weekend days usual for the language's main region.
  final Set<int> weekendDays;

  /// UI strings (see [ChronoStrings]).
  final ChronoStrings strings;

  /// Plural forms for each [ChronoUnit], in the order [pluralRule] expects.
  final Map<ChronoUnit, List<String>> unitNames;

  /// Template for future relative time; `{0}` is "3 days".
  final String relativeFuture;

  /// Template for past relative time; `{0}` is "3 days".
  final String relativePast;

  /// Plural selection rule.
  final PluralRule pluralRule;

  /// Month name for 1-based [month].
  String monthName(int month, {bool short = false}) => (short ? monthShortNames : monthNames)[month - 1];

  /// Weekday name for [DateTime.weekday] (1 = Monday).
  String weekdayName(int weekday, {WeekdayStyle style = WeekdayStyle.full}) => switch (style) {
        WeekdayStyle.full => weekdayNames,
        WeekdayStyle.short => weekdayShortNames,
        WeekdayStyle.narrow => weekdayNarrowNames,
      }[weekday - 1];

  /// "3 days" in this language.
  String unit(ChronoUnit unit, int count) {
    final forms = unitNames[unit]!;
    final n = count.abs();
    final index = switch (pluralRule) {
      PluralRule.none => 0,
      PluralRule.oneOther => n == 1 ? 0 : 1,
      PluralRule.zeroOneOther => n <= 1 ? 0 : 1,
      PluralRule.slavic => n % 10 == 1 && n % 100 != 11
          ? 0
          : (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 12 || n % 100 > 14))
              ? 1
              : 2,
      PluralRule.arabic => n == 1
          ? 0
          : n == 2
              ? 1
              : (n % 100 >= 3 && n % 100 <= 10)
                  ? 2
                  : 3,
    };
    final form = forms[index.clamp(0, forms.length - 1)];
    return form.replaceAll('{n}', localizeDigits('$n'));
  }

  /// Replaces ASCII digits with [nativeDigits] when [enabled] and available.
  String localizeDigits(String input, {bool enabled = false}) {
    final digits = nativeDigits;
    if (!enabled || digits == null) return input;
    final b = StringBuffer();
    for (final c in input.codeUnits) {
      b.write(c >= 48 && c <= 57 ? digits[c - 48] : String.fromCharCode(c));
    }
    return b.toString();
  }

  /// Converts native digits back to ASCII so typed input can be parsed.
  String normalizeDigits(String input) {
    final digits = nativeDigits;
    if (digits == null) return input;
    var out = input;
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(digits[i], '$i');
    }
    return out;
  }

  /// Copy with some fields replaced.
  ChronoLocale copyWith({
    String? code,
    List<String>? monthNames,
    List<String>? monthShortNames,
    List<String>? weekdayNames,
    List<String>? weekdayShortNames,
    List<String>? weekdayNarrowNames,
    List<String>? amPm,
    int? firstDayOfWeek,
    bool? isRtl,
    List<String>? nativeDigits,
    String? defaultDatePattern,
    Set<int>? weekendDays,
    ChronoStrings? strings,
    Map<ChronoUnit, List<String>>? unitNames,
    String? relativeFuture,
    String? relativePast,
    PluralRule? pluralRule,
  }) =>
      ChronoLocale(
        code: code ?? this.code,
        monthNames: monthNames ?? this.monthNames,
        monthShortNames: monthShortNames ?? this.monthShortNames,
        weekdayNames: weekdayNames ?? this.weekdayNames,
        weekdayShortNames: weekdayShortNames ?? this.weekdayShortNames,
        weekdayNarrowNames: weekdayNarrowNames ?? this.weekdayNarrowNames,
        amPm: amPm ?? this.amPm,
        firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
        isRtl: isRtl ?? this.isRtl,
        nativeDigits: nativeDigits ?? this.nativeDigits,
        defaultDatePattern: defaultDatePattern ?? this.defaultDatePattern,
        weekendDays: weekendDays ?? this.weekendDays,
        strings: strings ?? this.strings,
        unitNames: unitNames ?? this.unitNames,
        relativeFuture: relativeFuture ?? this.relativeFuture,
        relativePast: relativePast ?? this.relativePast,
        pluralRule: pluralRule ?? this.pluralRule,
      );

  static final Map<String, ChronoLocale> _registry = {
    for (final l in builtInLocales) l.code: l,
  };

  /// Codes of every registered locale.
  static Iterable<String> get supportedCodes => _registry.keys;

  /// Adds or replaces a locale so it can be looked up by [of].
  static void register(ChronoLocale locale) => _registry[locale.code] = locale;

  /// Looks up a locale by code (`pt_BR` and `pt-BR` fall back to `pt`),
  /// falling back to English.
  static ChronoLocale of(String? code) {
    if (code == null) return en;
    final normalized = code.replaceAll('-', '_');
    return _registry[normalized] ?? _registry[normalized.split('_').first.toLowerCase()] ?? en;
  }

  /// English.
  static const en = _en;

  /// Every locale shipped with the package.
  static const List<ChronoLocale> builtInLocales = [
    _en, _es, _fr, _de, _it, _pt, _ru, _ar, _hi, _mr, _zh, _ja, _ko, _tr, //
  ];
}

/// Weekday label length.
enum WeekdayStyle {
  /// "Monday".
  full,

  /// "Mon".
  short,

  /// "M".
  narrow,
}

/// Short UI strings used by the widgets.
class ChronoStrings {
  /// Creates a set of UI strings.
  const ChronoStrings({
    required this.today,
    required this.yesterday,
    required this.tomorrow,
    required this.now,
    required this.ok,
    required this.cancel,
    required this.clear,
    required this.selectDate,
    required this.selectRange,
    required this.enterDate,
    required this.invalidDate,
    required this.outOfRange,
    required this.weekShort,
    required this.allDay,
    required this.noEvents,
    required this.start,
    required this.end,
  });

  /// "Today".
  final String today;

  /// "Yesterday".
  final String yesterday;

  /// "Tomorrow".
  final String tomorrow;

  /// "Just now".
  final String now;

  /// "OK".
  final String ok;

  /// "Cancel".
  final String cancel;

  /// "Clear".
  final String clear;

  /// "Select date".
  final String selectDate;

  /// "Select range".
  final String selectRange;

  /// "Enter date".
  final String enterDate;

  /// "Invalid date".
  final String invalidDate;

  /// "Date is out of range".
  final String outOfRange;

  /// Week-number column header, e.g. "Wk".
  final String weekShort;

  /// "All day".
  final String allDay;

  /// "No events".
  final String noEvents;

  /// "Start".
  final String start;

  /// "End".
  final String end;
}

const _en = ChronoLocale(
  code: 'en',
  monthNames: [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ],
  monthShortNames: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  weekdayNames: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
  weekdayShortNames: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  weekdayNarrowNames: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
  amPm: ['AM', 'PM'],
  firstDayOfWeek: DateTime.sunday,
  defaultDatePattern: 'MM/dd/yyyy',
  unitNames: {
    ChronoUnit.second: ['{n} second', '{n} seconds'],
    ChronoUnit.minute: ['{n} minute', '{n} minutes'],
    ChronoUnit.hour: ['{n} hour', '{n} hours'],
    ChronoUnit.day: ['{n} day', '{n} days'],
    ChronoUnit.week: ['{n} week', '{n} weeks'],
    ChronoUnit.month: ['{n} month', '{n} months'],
    ChronoUnit.year: ['{n} year', '{n} years'],
  },
  relativeFuture: 'in {0}',
  relativePast: '{0} ago',
  strings: ChronoStrings(
    today: 'Today',
    yesterday: 'Yesterday',
    tomorrow: 'Tomorrow',
    now: 'Just now',
    ok: 'OK',
    cancel: 'Cancel',
    clear: 'Clear',
    selectDate: 'Select date',
    selectRange: 'Select range',
    enterDate: 'Enter date',
    invalidDate: 'Invalid date',
    outOfRange: 'Date is out of range',
    weekShort: 'Wk',
    allDay: 'All day',
    noEvents: 'No events',
    start: 'Start',
    end: 'End',
  ),
);

const _es = ChronoLocale(
  code: 'es',
  monthNames: [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre'
  ],
  monthShortNames: ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'],
  weekdayNames: ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'],
  weekdayShortNames: ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'],
  weekdayNarrowNames: ['L', 'M', 'X', 'J', 'V', 'S', 'D'],
  amPm: ['a. m.', 'p. m.'],
  firstDayOfWeek: DateTime.monday,
  unitNames: {
    ChronoUnit.second: ['{n} segundo', '{n} segundos'],
    ChronoUnit.minute: ['{n} minuto', '{n} minutos'],
    ChronoUnit.hour: ['{n} hora', '{n} horas'],
    ChronoUnit.day: ['{n} día', '{n} días'],
    ChronoUnit.week: ['{n} semana', '{n} semanas'],
    ChronoUnit.month: ['{n} mes', '{n} meses'],
    ChronoUnit.year: ['{n} año', '{n} años'],
  },
  relativeFuture: 'dentro de {0}',
  relativePast: 'hace {0}',
  strings: ChronoStrings(
    today: 'Hoy',
    yesterday: 'Ayer',
    tomorrow: 'Mañana',
    now: 'Ahora mismo',
    ok: 'Aceptar',
    cancel: 'Cancelar',
    clear: 'Borrar',
    selectDate: 'Seleccionar fecha',
    selectRange: 'Seleccionar rango',
    enterDate: 'Introducir fecha',
    invalidDate: 'Fecha no válida',
    outOfRange: 'Fecha fuera de rango',
    weekShort: 'Sem',
    allDay: 'Todo el día',
    noEvents: 'Sin eventos',
    start: 'Inicio',
    end: 'Fin',
  ),
);

const _fr = ChronoLocale(
  code: 'fr',
  monthNames: [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre'
  ],
  monthShortNames: ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'],
  weekdayNames: ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'],
  weekdayShortNames: ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'],
  weekdayNarrowNames: ['L', 'M', 'M', 'J', 'V', 'S', 'D'],
  amPm: ['AM', 'PM'],
  firstDayOfWeek: DateTime.monday,
  pluralRule: PluralRule.zeroOneOther,
  unitNames: {
    ChronoUnit.second: ['{n} seconde', '{n} secondes'],
    ChronoUnit.minute: ['{n} minute', '{n} minutes'],
    ChronoUnit.hour: ['{n} heure', '{n} heures'],
    ChronoUnit.day: ['{n} jour', '{n} jours'],
    ChronoUnit.week: ['{n} semaine', '{n} semaines'],
    ChronoUnit.month: ['{n} mois', '{n} mois'],
    ChronoUnit.year: ['{n} an', '{n} ans'],
  },
  relativeFuture: 'dans {0}',
  relativePast: 'il y a {0}',
  strings: ChronoStrings(
    today: "Aujourd'hui",
    yesterday: 'Hier',
    tomorrow: 'Demain',
    now: "À l'instant",
    ok: 'OK',
    cancel: 'Annuler',
    clear: 'Effacer',
    selectDate: 'Choisir une date',
    selectRange: 'Choisir une période',
    enterDate: 'Saisir une date',
    invalidDate: 'Date invalide',
    outOfRange: 'Date hors limites',
    weekShort: 'Sem',
    allDay: 'Toute la journée',
    noEvents: 'Aucun événement',
    start: 'Début',
    end: 'Fin',
  ),
);

const _de = ChronoLocale(
  code: 'de',
  monthNames: [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember'
  ],
  monthShortNames: ['Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sept.', 'Okt.', 'Nov.', 'Dez.'],
  weekdayNames: ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'],
  weekdayShortNames: ['Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.', 'So.'],
  weekdayNarrowNames: ['M', 'D', 'M', 'D', 'F', 'S', 'S'],
  amPm: ['AM', 'PM'],
  firstDayOfWeek: DateTime.monday,
  defaultDatePattern: 'dd.MM.yyyy',
  unitNames: {
    ChronoUnit.second: ['{n} Sekunde', '{n} Sekunden'],
    ChronoUnit.minute: ['{n} Minute', '{n} Minuten'],
    ChronoUnit.hour: ['{n} Stunde', '{n} Stunden'],
    ChronoUnit.day: ['{n} Tag', '{n} Tagen'],
    ChronoUnit.week: ['{n} Woche', '{n} Wochen'],
    ChronoUnit.month: ['{n} Monat', '{n} Monaten'],
    ChronoUnit.year: ['{n} Jahr', '{n} Jahren'],
  },
  relativeFuture: 'in {0}',
  relativePast: 'vor {0}',
  strings: ChronoStrings(
    today: 'Heute',
    yesterday: 'Gestern',
    tomorrow: 'Morgen',
    now: 'Gerade eben',
    ok: 'OK',
    cancel: 'Abbrechen',
    clear: 'Löschen',
    selectDate: 'Datum wählen',
    selectRange: 'Zeitraum wählen',
    enterDate: 'Datum eingeben',
    invalidDate: 'Ungültiges Datum',
    outOfRange: 'Datum außerhalb des Bereichs',
    weekShort: 'KW',
    allDay: 'Ganztägig',
    noEvents: 'Keine Termine',
    start: 'Beginn',
    end: 'Ende',
  ),
);

const _it = ChronoLocale(
  code: 'it',
  monthNames: [
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre'
  ],
  monthShortNames: ['gen', 'feb', 'mar', 'apr', 'mag', 'giu', 'lug', 'ago', 'set', 'ott', 'nov', 'dic'],
  weekdayNames: ['lunedì', 'martedì', 'mercoledì', 'giovedì', 'venerdì', 'sabato', 'domenica'],
  weekdayShortNames: ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
  weekdayNarrowNames: ['L', 'M', 'M', 'G', 'V', 'S', 'D'],
  amPm: ['AM', 'PM'],
  firstDayOfWeek: DateTime.monday,
  unitNames: {
    ChronoUnit.second: ['{n} secondo', '{n} secondi'],
    ChronoUnit.minute: ['{n} minuto', '{n} minuti'],
    ChronoUnit.hour: ['{n} ora', '{n} ore'],
    ChronoUnit.day: ['{n} giorno', '{n} giorni'],
    ChronoUnit.week: ['{n} settimana', '{n} settimane'],
    ChronoUnit.month: ['{n} mese', '{n} mesi'],
    ChronoUnit.year: ['{n} anno', '{n} anni'],
  },
  relativeFuture: 'tra {0}',
  relativePast: '{0} fa',
  strings: ChronoStrings(
    today: 'Oggi',
    yesterday: 'Ieri',
    tomorrow: 'Domani',
    now: 'Proprio ora',
    ok: 'OK',
    cancel: 'Annulla',
    clear: 'Cancella',
    selectDate: 'Seleziona data',
    selectRange: 'Seleziona intervallo',
    enterDate: 'Inserisci data',
    invalidDate: 'Data non valida',
    outOfRange: "Data fuori dall'intervallo",
    weekShort: 'Sett',
    allDay: 'Tutto il giorno',
    noEvents: 'Nessun evento',
    start: 'Inizio',
    end: 'Fine',
  ),
);

const _pt = ChronoLocale(
  code: 'pt',
  monthNames: [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro'
  ],
  monthShortNames: ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'],
  weekdayNames: ['segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado', 'domingo'],
  weekdayShortNames: ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'],
  weekdayNarrowNames: ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'],
  amPm: ['AM', 'PM'],
  firstDayOfWeek: DateTime.sunday,
  pluralRule: PluralRule.zeroOneOther,
  unitNames: {
    ChronoUnit.second: ['{n} segundo', '{n} segundos'],
    ChronoUnit.minute: ['{n} minuto', '{n} minutos'],
    ChronoUnit.hour: ['{n} hora', '{n} horas'],
    ChronoUnit.day: ['{n} dia', '{n} dias'],
    ChronoUnit.week: ['{n} semana', '{n} semanas'],
    ChronoUnit.month: ['{n} mês', '{n} meses'],
    ChronoUnit.year: ['{n} ano', '{n} anos'],
  },
  relativeFuture: 'em {0}',
  relativePast: 'há {0}',
  strings: ChronoStrings(
    today: 'Hoje',
    yesterday: 'Ontem',
    tomorrow: 'Amanhã',
    now: 'Agora mesmo',
    ok: 'OK',
    cancel: 'Cancelar',
    clear: 'Limpar',
    selectDate: 'Selecionar data',
    selectRange: 'Selecionar período',
    enterDate: 'Digitar data',
    invalidDate: 'Data inválida',
    outOfRange: 'Data fora do intervalo',
    weekShort: 'Sem',
    allDay: 'Dia inteiro',
    noEvents: 'Nenhum evento',
    start: 'Início',
    end: 'Fim',
  ),
);

const _ru = ChronoLocale(
  code: 'ru',
  monthNames: [
    'январь',
    'февраль',
    'март',
    'апрель',
    'май',
    'июнь',
    'июль',
    'август',
    'сентябрь',
    'октябрь',
    'ноябрь',
    'декабрь'
  ],
  monthShortNames: ['янв.', 'февр.', 'март', 'апр.', 'май', 'июнь', 'июль', 'авг.', 'сент.', 'окт.', 'нояб.', 'дек.'],
  weekdayNames: ['понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'],
  weekdayShortNames: ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'],
  weekdayNarrowNames: ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'],
  amPm: ['AM', 'PM'],
  firstDayOfWeek: DateTime.monday,
  defaultDatePattern: 'dd.MM.yyyy',
  pluralRule: PluralRule.slavic,
  unitNames: {
    ChronoUnit.second: ['{n} секунду', '{n} секунды', '{n} секунд'],
    ChronoUnit.minute: ['{n} минуту', '{n} минуты', '{n} минут'],
    ChronoUnit.hour: ['{n} час', '{n} часа', '{n} часов'],
    ChronoUnit.day: ['{n} день', '{n} дня', '{n} дней'],
    ChronoUnit.week: ['{n} неделю', '{n} недели', '{n} недель'],
    ChronoUnit.month: ['{n} месяц', '{n} месяца', '{n} месяцев'],
    ChronoUnit.year: ['{n} год', '{n} года', '{n} лет'],
  },
  relativeFuture: 'через {0}',
  relativePast: '{0} назад',
  strings: ChronoStrings(
    today: 'Сегодня',
    yesterday: 'Вчера',
    tomorrow: 'Завтра',
    now: 'Только что',
    ok: 'ОК',
    cancel: 'Отмена',
    clear: 'Очистить',
    selectDate: 'Выберите дату',
    selectRange: 'Выберите период',
    enterDate: 'Введите дату',
    invalidDate: 'Неверная дата',
    outOfRange: 'Дата вне диапазона',
    weekShort: 'Нед',
    allDay: 'Весь день',
    noEvents: 'Нет событий',
    start: 'Начало',
    end: 'Конец',
  ),
);

const _ar = ChronoLocale(
  code: 'ar',
  monthNames: [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر'
  ],
  monthShortNames: [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر'
  ],
  weekdayNames: ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
  weekdayShortNames: ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
  weekdayNarrowNames: ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'],
  amPm: ['ص', 'م'],
  firstDayOfWeek: DateTime.saturday,
  isRtl: true,
  nativeDigits: ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'],
  weekendDays: {DateTime.friday, DateTime.saturday},
  pluralRule: PluralRule.arabic,
  unitNames: {
    ChronoUnit.second: ['ثانية واحدة', 'ثانيتين', '{n} ثوانٍ', '{n} ثانية'],
    ChronoUnit.minute: ['دقيقة واحدة', 'دقيقتين', '{n} دقائق', '{n} دقيقة'],
    ChronoUnit.hour: ['ساعة واحدة', 'ساعتين', '{n} ساعات', '{n} ساعة'],
    ChronoUnit.day: ['يوم واحد', 'يومين', '{n} أيام', '{n} يومًا'],
    ChronoUnit.week: ['أسبوع واحد', 'أسبوعين', '{n} أسابيع', '{n} أسبوعًا'],
    ChronoUnit.month: ['شهر واحد', 'شهرين', '{n} أشهر', '{n} شهرًا'],
    ChronoUnit.year: ['سنة واحدة', 'سنتين', '{n} سنوات', '{n} سنة'],
  },
  relativeFuture: 'خلال {0}',
  relativePast: 'منذ {0}',
  strings: ChronoStrings(
    today: 'اليوم',
    yesterday: 'أمس',
    tomorrow: 'غدًا',
    now: 'الآن',
    ok: 'موافق',
    cancel: 'إلغاء',
    clear: 'مسح',
    selectDate: 'اختر التاريخ',
    selectRange: 'اختر الفترة',
    enterDate: 'أدخل التاريخ',
    invalidDate: 'تاريخ غير صالح',
    outOfRange: 'التاريخ خارج النطاق',
    weekShort: 'أسبوع',
    allDay: 'طوال اليوم',
    noEvents: 'لا توجد أحداث',
    start: 'البداية',
    end: 'النهاية',
  ),
);

const _hi = ChronoLocale(
  code: 'hi',
  monthNames: [
    'जनवरी',
    'फ़रवरी',
    'मार्च',
    'अप्रैल',
    'मई',
    'जून',
    'जुलाई',
    'अगस्त',
    'सितंबर',
    'अक्तूबर',
    'नवंबर',
    'दिसंबर'
  ],
  monthShortNames: ['जन॰', 'फ़र॰', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुल॰', 'अग॰', 'सित॰', 'अक्तू॰', 'नव॰', 'दिस॰'],
  weekdayNames: ['सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'],
  weekdayShortNames: ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'],
  weekdayNarrowNames: ['सो', 'मं', 'बु', 'गु', 'शु', 'श', 'र'],
  amPm: ['am', 'pm'],
  firstDayOfWeek: DateTime.sunday,
  nativeDigits: ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'],
  weekendDays: {DateTime.sunday},
  pluralRule: PluralRule.zeroOneOther,
  unitNames: {
    ChronoUnit.second: ['{n} सेकंड', '{n} सेकंड'],
    ChronoUnit.minute: ['{n} मिनट', '{n} मिनट'],
    ChronoUnit.hour: ['{n} घंटा', '{n} घंटे'],
    ChronoUnit.day: ['{n} दिन', '{n} दिन'],
    ChronoUnit.week: ['{n} सप्ताह', '{n} सप्ताह'],
    ChronoUnit.month: ['{n} महीना', '{n} महीने'],
    ChronoUnit.year: ['{n} वर्ष', '{n} वर्ष'],
  },
  relativeFuture: '{0} में',
  relativePast: '{0} पहले',
  strings: ChronoStrings(
    today: 'आज',
    yesterday: 'कल',
    tomorrow: 'कल',
    now: 'अभी',
    ok: 'ठीक है',
    cancel: 'रद्द करें',
    clear: 'साफ़ करें',
    selectDate: 'तारीख चुनें',
    selectRange: 'अवधि चुनें',
    enterDate: 'तारीख दर्ज करें',
    invalidDate: 'अमान्य तारीख',
    outOfRange: 'तारीख सीमा से बाहर है',
    weekShort: 'सप्ता',
    allDay: 'पूरा दिन',
    noEvents: 'कोई कार्यक्रम नहीं',
    start: 'शुरू',
    end: 'समाप्त',
  ),
);

const _mr = ChronoLocale(
  code: 'mr',
  monthNames: [
    'जानेवारी',
    'फेब्रुवारी',
    'मार्च',
    'एप्रिल',
    'मे',
    'जून',
    'जुलै',
    'ऑगस्ट',
    'सप्टेंबर',
    'ऑक्टोबर',
    'नोव्हेंबर',
    'डिसेंबर'
  ],
  monthShortNames: [
    'जाने',
    'फेब्रु',
    'मार्च',
    'एप्रि',
    'मे',
    'जून',
    'जुलै',
    'ऑग',
    'सप्टें',
    'ऑक्टो',
    'नोव्हें',
    'डिसें'
  ],
  weekdayNames: ['सोमवार', 'मंगळवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'],
  weekdayShortNames: ['सोम', 'मंगळ', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'],
  weekdayNarrowNames: ['सो', 'मं', 'बु', 'गु', 'शु', 'श', 'र'],
  amPm: ['म.पू.', 'म.उ.'],
  firstDayOfWeek: DateTime.sunday,
  nativeDigits: ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'],
  weekendDays: {DateTime.sunday},
  unitNames: {
    ChronoUnit.second: ['{n} सेकंद', '{n} सेकंद'],
    ChronoUnit.minute: ['{n} मिनिट', '{n} मिनिटे'],
    ChronoUnit.hour: ['{n} तास', '{n} तास'],
    ChronoUnit.day: ['{n} दिवस', '{n} दिवस'],
    ChronoUnit.week: ['{n} आठवडा', '{n} आठवडे'],
    ChronoUnit.month: ['{n} महिना', '{n} महिने'],
    ChronoUnit.year: ['{n} वर्ष', '{n} वर्षे'],
  },
  relativeFuture: '{0} मध्ये',
  relativePast: '{0} पूर्वी',
  strings: ChronoStrings(
    today: 'आज',
    yesterday: 'काल',
    tomorrow: 'उद्या',
    now: 'आत्ताच',
    ok: 'ठीक आहे',
    cancel: 'रद्द करा',
    clear: 'साफ करा',
    selectDate: 'तारीख निवडा',
    selectRange: 'कालावधी निवडा',
    enterDate: 'तारीख टाका',
    invalidDate: 'अवैध तारीख',
    outOfRange: 'तारीख मर्यादेबाहेर आहे',
    weekShort: 'आठ',
    allDay: 'पूर्ण दिवस',
    noEvents: 'कोणतेही कार्यक्रम नाहीत',
    start: 'सुरुवात',
    end: 'शेवट',
  ),
);

const _zh = ChronoLocale(
  code: 'zh',
  monthNames: ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'],
  monthShortNames: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
  weekdayNames: ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'],
  weekdayShortNames: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
  weekdayNarrowNames: ['一', '二', '三', '四', '五', '六', '日'],
  amPm: ['上午', '下午'],
  firstDayOfWeek: DateTime.monday,
  defaultDatePattern: 'yyyy/MM/dd',
  pluralRule: PluralRule.none,
  unitNames: {
    ChronoUnit.second: ['{n}秒'],
    ChronoUnit.minute: ['{n}分钟'],
    ChronoUnit.hour: ['{n}小时'],
    ChronoUnit.day: ['{n}天'],
    ChronoUnit.week: ['{n}周'],
    ChronoUnit.month: ['{n}个月'],
    ChronoUnit.year: ['{n}年'],
  },
  relativeFuture: '{0}后',
  relativePast: '{0}前',
  strings: ChronoStrings(
    today: '今天',
    yesterday: '昨天',
    tomorrow: '明天',
    now: '刚刚',
    ok: '确定',
    cancel: '取消',
    clear: '清除',
    selectDate: '选择日期',
    selectRange: '选择日期范围',
    enterDate: '输入日期',
    invalidDate: '日期无效',
    outOfRange: '日期超出范围',
    weekShort: '周',
    allDay: '全天',
    noEvents: '没有日程',
    start: '开始',
    end: '结束',
  ),
);

const _ja = ChronoLocale(
  code: 'ja',
  monthNames: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
  monthShortNames: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
  weekdayNames: ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'],
  weekdayShortNames: ['月', '火', '水', '木', '金', '土', '日'],
  weekdayNarrowNames: ['月', '火', '水', '木', '金', '土', '日'],
  amPm: ['午前', '午後'],
  firstDayOfWeek: DateTime.sunday,
  defaultDatePattern: 'yyyy/MM/dd',
  pluralRule: PluralRule.none,
  unitNames: {
    ChronoUnit.second: ['{n}秒'],
    ChronoUnit.minute: ['{n}分'],
    ChronoUnit.hour: ['{n}時間'],
    ChronoUnit.day: ['{n}日'],
    ChronoUnit.week: ['{n}週間'],
    ChronoUnit.month: ['{n}か月'],
    ChronoUnit.year: ['{n}年'],
  },
  relativeFuture: '{0}後',
  relativePast: '{0}前',
  strings: ChronoStrings(
    today: '今日',
    yesterday: '昨日',
    tomorrow: '明日',
    now: 'たった今',
    ok: 'OK',
    cancel: 'キャンセル',
    clear: 'クリア',
    selectDate: '日付を選択',
    selectRange: '期間を選択',
    enterDate: '日付を入力',
    invalidDate: '無効な日付',
    outOfRange: '日付が範囲外です',
    weekShort: '週',
    allDay: '終日',
    noEvents: '予定はありません',
    start: '開始',
    end: '終了',
  ),
);

const _ko = ChronoLocale(
  code: 'ko',
  monthNames: ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'],
  monthShortNames: ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'],
  weekdayNames: ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'],
  weekdayShortNames: ['월', '화', '수', '목', '금', '토', '일'],
  weekdayNarrowNames: ['월', '화', '수', '목', '금', '토', '일'],
  amPm: ['오전', '오후'],
  firstDayOfWeek: DateTime.sunday,
  defaultDatePattern: 'yyyy.MM.dd',
  pluralRule: PluralRule.none,
  unitNames: {
    ChronoUnit.second: ['{n}초'],
    ChronoUnit.minute: ['{n}분'],
    ChronoUnit.hour: ['{n}시간'],
    ChronoUnit.day: ['{n}일'],
    ChronoUnit.week: ['{n}주'],
    ChronoUnit.month: ['{n}개월'],
    ChronoUnit.year: ['{n}년'],
  },
  relativeFuture: '{0} 후',
  relativePast: '{0} 전',
  strings: ChronoStrings(
    today: '오늘',
    yesterday: '어제',
    tomorrow: '내일',
    now: '방금',
    ok: '확인',
    cancel: '취소',
    clear: '지우기',
    selectDate: '날짜 선택',
    selectRange: '기간 선택',
    enterDate: '날짜 입력',
    invalidDate: '잘못된 날짜',
    outOfRange: '날짜가 범위를 벗어났습니다',
    weekShort: '주',
    allDay: '종일',
    noEvents: '일정 없음',
    start: '시작',
    end: '종료',
  ),
);

const _tr = ChronoLocale(
  code: 'tr',
  monthNames: [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık'
  ],
  monthShortNames: ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'],
  weekdayNames: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'],
  weekdayShortNames: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'],
  weekdayNarrowNames: ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'],
  amPm: ['ÖÖ', 'ÖS'],
  firstDayOfWeek: DateTime.monday,
  defaultDatePattern: 'dd.MM.yyyy',
  pluralRule: PluralRule.none,
  unitNames: {
    ChronoUnit.second: ['{n} saniye'],
    ChronoUnit.minute: ['{n} dakika'],
    ChronoUnit.hour: ['{n} saat'],
    ChronoUnit.day: ['{n} gün'],
    ChronoUnit.week: ['{n} hafta'],
    ChronoUnit.month: ['{n} ay'],
    ChronoUnit.year: ['{n} yıl'],
  },
  relativeFuture: '{0} sonra',
  relativePast: '{0} önce',
  strings: ChronoStrings(
    today: 'Bugün',
    yesterday: 'Dün',
    tomorrow: 'Yarın',
    now: 'Az önce',
    ok: 'Tamam',
    cancel: 'İptal',
    clear: 'Temizle',
    selectDate: 'Tarih seçin',
    selectRange: 'Aralık seçin',
    enterDate: 'Tarih girin',
    invalidDate: 'Geçersiz tarih',
    outOfRange: 'Tarih aralık dışında',
    weekShort: 'Hf',
    allDay: 'Tüm gün',
    noEvents: 'Etkinlik yok',
    start: 'Başlangıç',
    end: 'Bitiş',
  ),
);
