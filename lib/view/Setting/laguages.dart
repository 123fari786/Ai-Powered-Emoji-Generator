import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../widgets/background_theme.dart';

class Language extends StatefulWidget {
  const Language({super.key});

  @override
  State<Language> createState() => _LanguageState();
}

class _LanguageState extends State<Language> {
  final box = GetStorage();
  Locale? _currentLocale;

  final List<CountrySetting> _countries = [
    CountrySetting(
      name: 'United States'.tr,
      flag: "assets/images/united_states.png",
      locale: const Locale('en', 'US'),
      isSelected: false,
    ),
    CountrySetting(
      name: 'United Kingdom'.tr,
      flag: "assets/images/united_kingdom.png",
      locale: const Locale('en', 'GB'),
      isSelected: false,
    ),
    CountrySetting(
      name: 'Arabic'.tr,
      flag: "assets/images/arabic.png",
      locale: const Locale('ar', 'SA'),
      isSelected: false,
    ),
    CountrySetting(
      name: 'Chinese'.tr,
      flag: "assets/images/chinese.png",
      locale: const Locale('zh', 'CN'),
      isSelected: false,
    ),
    CountrySetting(
      name: 'French'.tr,
      flag: "assets/images/france.png",
      locale: const Locale('fr', 'FR'),
      isSelected: false,
    ),
    CountrySetting(
      name: 'German'.tr,
      flag: "assets/images/germany.png",
      locale: const Locale('de', 'DE'),
      isSelected: false,
    ),
    CountrySetting(
      name: 'Italian'.tr,
      flag: "assets/images/italian.jpeg",
      locale: const Locale('it', 'IT'),
      isSelected: false,
    ),
    CountrySetting(
      name: 'Japanese'.tr,
      flag: "assets/images/japanese.png",
      locale: const Locale('ja', 'JP'),
      isSelected: false,
    ),
    CountrySetting(
      name: 'Korean'.tr,
      flag: "assets/images/korean.png",
      locale: const Locale('ko', 'KR'),
      isSelected: false,
    ),
    CountrySetting(
      name: 'Portuguese'.tr,
      flag: "assets/images/portugal_flag.png",
      locale: const Locale('pt', 'PT'),
      isSelected: false,
    ),
    CountrySetting(
      name: 'Russian'.tr,
      flag: "assets/images/russia_flag.png",
      locale: const Locale('ru', 'RU'),
      isSelected: false,
    ),
    CountrySetting(
      name: 'Spanish'.tr,
      flag: "assets/images/spanish.png",
      locale: const Locale('es', 'ES'),
      isSelected: false,
    ),
    CountrySetting(
      name: 'Thailand'.tr,
      flag: "assets/images/thailand_flag.png",
      locale: const Locale('th', 'TH'),
      isSelected: false,
    ),
    CountrySetting(
      name: 'Turkish'.tr,
      flag: "assets/images/turkey.png",
      locale: const Locale('tr', 'TR'),
      isSelected: false,
    ),
    CountrySetting(
      name: 'Vietnamese'.tr,
      flag: "assets/images/vietnammese.png",
      locale: const Locale('vi', 'VN'),
      isSelected: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  void _loadSavedLanguage() {
    final langCode = box.read('lang_code');
    final countryCode = box.read('country_code');

    // Reset all selections
    for (var c in _countries) c.isSelected = false;

    if (langCode != null && countryCode != null) {
      final index = _countries.indexWhere(
        (c) =>
            c.locale.languageCode == langCode &&
            c.locale.countryCode == countryCode,
      );
      if (index != -1) {
        _countries[index].isSelected = true;
        _currentLocale = _countries[index].locale;
      } else {
        _countries[0].isSelected = true;
        _currentLocale = _countries[0].locale;
      }
    } else {
      _countries[0].isSelected = true;
      _currentLocale = _countries[0].locale;
    }
    setState(() {});
  }

  void _selectCountry(int index) {
    for (var c in _countries) c.isSelected = false;

    _countries[index].isSelected = true;
    _currentLocale = _countries[index].locale;

    // Update app locale
    Get.updateLocale(_currentLocale!);

    // Save to storage
    box.write('lang_code', _currentLocale!.languageCode);
    box.write('country_code', _currentLocale!.countryCode);

    setState(() {});

    // Return selected locale to previous screen
    Navigator.pop(context, _currentLocale);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: BackgroundTheme.background),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: topPadding + 0, bottom: 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Languages'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Positioned(
                    left: 16,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                itemCount: _countries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final country = _countries[index];
                  return InkWell(
                    onTap: () => _selectCountry(index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: country.isSelected
                            ? theme.colorScheme.primary.withOpacity(0.15)
                            : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            padding: const EdgeInsets.all(4),
                            child: ClipOval(
                              child: Image.asset(
                                country.flag,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              country.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: country.isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            height: 22,
                            width: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: country.isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.3,
                                    ),
                            ),
                            child: Icon(
                              Icons.check,
                              size: 14,
                              color: country.isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.background,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CountrySetting {
  final String name;
  final String flag;
  final Locale locale;
  bool isSelected;

  CountrySetting({
    required this.name,
    required this.flag,
    required this.locale,
    required this.isSelected,
  });
}
