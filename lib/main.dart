import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum _AppLanguage { tr, zh, en, es, ru, fr }
enum _ReferenceMode { bottom, left, top, right, auto }

const Map<_AppLanguage, Map<String, String>> _i18n = {
  _AppLanguage.tr: {
    'settings': 'Ayarlar',
    'language': 'Dil',
    'sensitivity': 'Baloncuk hassasiyeti (tam ölçek açı)',
    'threshold': 'Düz kabul eşiği',
    'smoothing': 'Yumuşatma',
    'show_usage': 'Kullanım bilgisini göster',
    'usage_title': 'Kullanım Bilgileri',
    'usage_body': '• Telefonu yüzeye koy.\n'
        '• X/Y paneline uzun basarak mevcut konumu kalibre et.\n'
        '• X/Y paneline çift dokunarak kalibrasyonu sıfırla.\n'
        '• Emülatörde sensör verisi sınırlı olabilir, gerçek cihazda test et.',
    'reset_defaults': 'Varsayılan ayarlara dön',
    'hint_controls': 'Uzun bas: kalibre et  •  Çift dokun: sıfırla',
    'hint_emulator': 'Emülatör sensör verisi üretmeyebilir.',
    'reference_options': 'Referans kenarı',
    'reference_bottom': 'Alt',
    'reference_left': 'Sol',
    'reference_top': 'Üst',
    'reference_right': 'Sağ',
    'reference_auto': 'Otomatik',
    'reference_changed': 'Referans kenarı değişti:',
  },
  _AppLanguage.zh: {
    'settings': '设置',
    'language': '语言',
    'sensitivity': '气泡灵敏度（满量程角度）',
    'threshold': '水平阈值',
    'smoothing': '平滑',
    'show_usage': '显示使用提示',
    'usage_title': '使用说明',
    'usage_body': '• 将手机放在要测量的表面上。\n'
        '• 长按 X/Y 面板校准当前位置。\n'
        '• 双击 X/Y 面板重置校准。\n'
        '• 模拟器可能无法提供传感器数据，请在真机测试。',
    'reset_defaults': '恢复默认设置',
    'hint_controls': '长按：校准  •  双击：重置',
    'hint_emulator': '模拟器可能无法提供传感器数据。',
    'reference_options': '参考边',
    'reference_bottom': '底部',
    'reference_left': '左侧',
    'reference_top': '顶部',
    'reference_right': '右侧',
    'reference_auto': '自动',
    'reference_changed': '参考边已切换：',
  },
  _AppLanguage.en: {
    'settings': 'Settings',
    'language': 'Language',
    'sensitivity': 'Bubble sensitivity (full-scale angle)',
    'threshold': 'Level threshold',
    'smoothing': 'Smoothing',
    'show_usage': 'Show usage tips',
    'usage_title': 'How to Use',
    'usage_body': '• Place the phone on the target surface.\n'
        '• Long-press the X/Y panel to calibrate current position.\n'
        '• Double-tap the X/Y panel to clear calibration.\n'
        '• Emulator sensor data may be limited; test on a real device.',
    'reset_defaults': 'Reset to defaults',
    'hint_controls': 'Long press: calibrate  •  Double tap: reset',
    'hint_emulator': 'Emulator may not provide sensor data.',
    'reference_options': 'Reference edge',
    'reference_bottom': 'Bottom',
    'reference_left': 'Left',
    'reference_top': 'Top',
    'reference_right': 'Right',
    'reference_auto': 'Auto',
    'reference_changed': 'Reference edge changed:',
  },
  _AppLanguage.es: {
    'settings': 'Ajustes',
    'language': 'Idioma',
    'sensitivity': 'Sensibilidad de burbuja (ángulo de escala total)',
    'threshold': 'Umbral de nivel',
    'smoothing': 'Suavizado',
    'show_usage': 'Mostrar guía de uso',
    'usage_title': 'Guía de Uso',
    'usage_body': '• Coloca el teléfono sobre la superficie.\n'
        '• Mantén pulsado el panel X/Y para calibrar la posición actual.\n'
        '• Toca dos veces el panel X/Y para reiniciar la calibración.\n'
        '• El emulador puede no dar datos de sensores; prueba en dispositivo real.',
    'reset_defaults': 'Restablecer valores',
    'hint_controls': 'Mantén pulsado: calibrar  •  Doble toque: reiniciar',
    'hint_emulator': 'El emulador puede no proporcionar datos de sensores.',
    'reference_options': 'Borde de referencia',
    'reference_bottom': 'Abajo',
    'reference_left': 'Izquierda',
    'reference_top': 'Arriba',
    'reference_right': 'Derecha',
    'reference_auto': 'Automatico',
    'reference_changed': 'Borde de referencia cambiado:',
  },
  _AppLanguage.ru: {
    'settings': 'Настройки',
    'language': 'Язык',
    'sensitivity': 'Чувствительность пузырька (угол полной шкалы)',
    'threshold': 'Порог уровня',
    'smoothing': 'Сглаживание',
    'show_usage': 'Показывать подсказки',
    'usage_title': 'Как пользоваться',
    'usage_body': '• Положите телефон на поверхность.\n'
        '• Удерживайте панель X/Y для калибровки текущего положения.\n'
        '• Дважды нажмите панель X/Y, чтобы сбросить калибровку.\n'
        '• В эмуляторе данные датчиков могут быть ограничены; проверьте на телефоне.',
    'reset_defaults': 'Сбросить по умолчанию',
    'hint_controls': 'Удержание: калибровка  •  Двойное нажатие: сброс',
    'hint_emulator': 'Эмулятор может не передавать данные датчиков.',
    'reference_options': 'Опорная грань',
    'reference_bottom': 'Низ',
    'reference_left': 'Слева',
    'reference_top': 'Верх',
    'reference_right': 'Справа',
    'reference_auto': 'Авто',
    'reference_changed': 'Опорная грань изменена:',
  },
  _AppLanguage.fr: {
    'settings': 'Parametres',
    'language': 'Langue',
    'sensitivity': 'Sensibilite de la bulle (angle pleine echelle)',
    'threshold': 'Seuil de niveau',
    'smoothing': 'Lissage',
    'show_usage': 'Afficher les conseils',
    'usage_title': 'Mode d’emploi',
    'usage_body': '• Pose le telephone sur la surface cible.\n'
        '• Appui long sur le panneau X/Y pour calibrer la position.\n'
        '• Double appui sur le panneau X/Y pour reinitialiser.\n'
        '• Les donnees capteur peuvent etre limitees sur emulateur.',
    'reset_defaults': 'Reinitialiser par defaut',
    'hint_controls': 'Appui long : calibrer  •  Double appui : reinitialiser',
    'hint_emulator': "L'emulateur peut ne pas fournir de donnees capteur.",
    'reference_options': 'Bord de reference',
    'reference_bottom': 'Bas',
    'reference_left': 'Gauche',
    'reference_top': 'Haut',
    'reference_right': 'Droite',
    'reference_auto': 'Auto',
    'reference_changed': 'Bord de reference modifie :',
  },
};

void main() {
  runApp(const DuzlemOlcerApp());
}

class DuzlemOlcerApp extends StatelessWidget {
  const DuzlemOlcerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Düzlem Ölçer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A7F5A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const BubbleLevelPage(),
    );
  }
}

class BubbleLevelPage extends StatefulWidget {
  const BubbleLevelPage({super.key});

  @override
  State<BubbleLevelPage> createState() => _BubbleLevelPageState();
}

class _BubbleLevelPageState extends State<BubbleLevelPage> {
  static const double _defaultFullScaleAngle = 35;
  static const double _defaultLevelTolerance = 1.1;
  static const double _defaultSmoothing = 0.18;
  static const String _kPrefLanguage = 'language';
  static const String _kPrefReferenceMode = 'reference_mode';
  static const String _kPrefFullScaleAngle = 'full_scale_angle';
  static const String _kPrefLevelTolerance = 'level_tolerance';
  static const String _kPrefSmoothing = 'smoothing';
  static const String _kPrefShowUsageInfo = 'show_usage_info';

  StreamSubscription<AccelerometerEvent>? _accelerometerSub;

  double _pitchRaw = 0;
  double _rollRaw = 0;
  double _pitchOffset = 0;
  double _rollOffset = 0;
  double _pitch = 0;
  double _roll = 0;
  bool _hasSensorData = false;
  double _fullScaleAngle = _defaultFullScaleAngle;
  double _levelTolerance = _defaultLevelTolerance;
  double _smoothing = _defaultSmoothing;
  bool _showUsageInfo = true;
  _AppLanguage _language = _AppLanguage.tr;
  _ReferenceMode _referenceMode = _ReferenceMode.auto;

  String _t(String key) => _i18n[_language]?[key] ?? key;

  String _languageName(_AppLanguage language) {
    switch (language) {
      case _AppLanguage.tr:
        return 'Türkçe';
      case _AppLanguage.zh:
        return '中文';
      case _AppLanguage.en:
        return 'English';
      case _AppLanguage.es:
        return 'Español';
      case _AppLanguage.ru:
        return 'Русский';
      case _AppLanguage.fr:
        return 'Français';
    }
  }

  String _referenceModeName(_ReferenceMode mode) {
    switch (mode) {
      case _ReferenceMode.bottom:
        return _t('reference_bottom');
      case _ReferenceMode.left:
        return _t('reference_left');
      case _ReferenceMode.top:
        return _t('reference_top');
      case _ReferenceMode.right:
        return _t('reference_right');
      case _ReferenceMode.auto:
        return _t('reference_auto');
    }
  }

  Widget _referenceModeGlyph(_ReferenceMode mode) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: _ReferenceGlyphPainter(mode: mode),
      ),
    );
  }

  (double x, double y) _projectAngles(double roll, double pitch) {
    switch (_referenceMode) {
      case _ReferenceMode.bottom:
      case _ReferenceMode.auto:
        return (roll, pitch);
      case _ReferenceMode.left:
        return (pitch, -roll);
      case _ReferenceMode.top:
        return (-roll, -pitch);
      case _ReferenceMode.right:
        return (-pitch, roll);
    }
  }

  void _setReferenceMode(_ReferenceMode mode) {
    setState(() {
      _referenceMode = mode;
    });
    _savePreferencesInBackground();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1300),
        content: Text('${_t('reference_changed')} ${_referenceModeName(mode)}'),
      ),
    );
  }

  _ReferenceMode _nextReferenceMode(_ReferenceMode current) {
    switch (current) {
      case _ReferenceMode.bottom:
        return _ReferenceMode.left;
      case _ReferenceMode.left:
        return _ReferenceMode.top;
      case _ReferenceMode.top:
        return _ReferenceMode.right;
      case _ReferenceMode.right:
        return _ReferenceMode.auto;
      case _ReferenceMode.auto:
        return _ReferenceMode.bottom;
    }
  }

  void _cycleReferenceMode() {
    _setReferenceMode(_nextReferenceMode(_referenceMode));
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreferences());
    _accelerometerSub = accelerometerEventStream().listen(_onSensorUpdate);
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    super.dispose();
  }

  void _onSensorUpdate(AccelerometerEvent event) {
    final gravityMagnitude =
        math.sqrt((event.x * event.x) + (event.y * event.y) + (event.z * event.z));
    final pitchRaw = math.atan2(
          -event.y,
          math.sqrt((event.x * event.x) + (event.z * event.z)),
        ) *
        180 /
        math.pi;
    final rollRaw = math.atan2(event.x, event.z) * 180 / math.pi;

    final pitch = pitchRaw - _pitchOffset;
    final roll = rollRaw - _rollOffset;

    if (!mounted) {
      return;
    }

    setState(() {
      _hasSensorData = gravityMagnitude > 0.1;
      _pitchRaw = pitchRaw;
      _rollRaw = rollRaw;
      _pitch = _pitch + (pitch - _pitch) * _smoothing;
      _roll = _roll + (roll - _roll) * _smoothing;
    });
  }

  bool get _isLevel =>
      _pitch.abs() <= _levelTolerance && _roll.abs() <= _levelTolerance;

  void _calibrate() {
    setState(() {
      _pitchOffset = _pitchRaw;
      _rollOffset = _rollRaw;
    });
  }

  void _clearCalibration() {
    setState(() {
      _pitchOffset = 0;
      _rollOffset = 0;
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getInt(_kPrefLanguage);
    final savedReferenceMode = prefs.getInt(_kPrefReferenceMode);

    if (!mounted) {
      return;
    }

    setState(() {
      _fullScaleAngle =
          prefs.getDouble(_kPrefFullScaleAngle) ?? _defaultFullScaleAngle;
      _levelTolerance =
          prefs.getDouble(_kPrefLevelTolerance) ?? _defaultLevelTolerance;
      _smoothing = prefs.getDouble(_kPrefSmoothing) ?? _defaultSmoothing;
      _showUsageInfo = prefs.getBool(_kPrefShowUsageInfo) ?? true;

      if (savedLanguage != null &&
          savedLanguage >= 0 &&
          savedLanguage < _AppLanguage.values.length) {
        _language = _AppLanguage.values[savedLanguage];
      }

      if (savedReferenceMode != null &&
          savedReferenceMode >= 0 &&
          savedReferenceMode < _ReferenceMode.values.length) {
        _referenceMode = _ReferenceMode.values[savedReferenceMode];
      }
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefLanguage, _language.index);
    await prefs.setInt(_kPrefReferenceMode, _referenceMode.index);
    await prefs.setDouble(_kPrefFullScaleAngle, _fullScaleAngle);
    await prefs.setDouble(_kPrefLevelTolerance, _levelTolerance);
    await prefs.setDouble(_kPrefSmoothing, _smoothing);
    await prefs.setBool(_kPrefShowUsageInfo, _showUsageInfo);
  }

  void _savePreferencesInBackground() {
    unawaited(_savePreferences());
  }

  Widget _modeActionButton({
    required Widget icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Tooltip(
            message: tooltip,
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceControls() {
    return _modeActionButton(
      icon: _referenceModeGlyph(_referenceMode),
      tooltip: '${_t('reference_options')}: ${_referenceModeName(_referenceMode)}',
      onTap: _cycleReferenceMode,
    );
  }

  void _openSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1C21),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget settingsSlider({
              required String title,
              required String valueText,
              required double value,
              required double min,
              required double max,
              required int divisions,
              required ValueChanged<double> onChanged,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        valueText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    activeColor: const Color(0xFF0BA1D8),
                    inactiveColor: Colors.white.withValues(alpha: 0.20),
                    onChanged: (next) {
                      onChanged(next);
                      setModalState(() {});
                    },
                  ),
                ],
              );
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.26),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _t('settings'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _t('language'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111318),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<_AppLanguage>(
                          value: _language,
                          dropdownColor: const Color(0xFF1F2228),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          iconEnabledColor: const Color(0xFF0BA1D8),
                          items: _AppLanguage.values
                              .map(
                                (lang) => DropdownMenuItem<_AppLanguage>(
                                  value: lang,
                                  child: Text(_languageName(lang)),
                                ),
                              )
                              .toList(),
                          onChanged: (next) {
                            if (next == null) {
                              return;
                            }
                            setState(() => _language = next);
                            _savePreferencesInBackground();
                            setModalState(() {});
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    settingsSlider(
                      title: _t('sensitivity'),
                      valueText: '${_fullScaleAngle.toStringAsFixed(0)}°',
                      value: _fullScaleAngle,
                      min: 15,
                      max: 60,
                      divisions: 45,
                      onChanged: (v) {
                        setState(() => _fullScaleAngle = v);
                        _savePreferencesInBackground();
                      },
                    ),
                    settingsSlider(
                      title: _t('threshold'),
                      valueText: '${_levelTolerance.toStringAsFixed(1)}°',
                      value: _levelTolerance,
                      min: 0.3,
                      max: 3.0,
                      divisions: 27,
                      onChanged: (v) {
                        setState(() => _levelTolerance = v);
                        _savePreferencesInBackground();
                      },
                    ),
                    settingsSlider(
                      title: _t('smoothing'),
                      valueText: _smoothing.toStringAsFixed(2),
                      value: _smoothing,
                      min: 0.05,
                      max: 0.50,
                      divisions: 45,
                      onChanged: (v) {
                        setState(() => _smoothing = v);
                        _savePreferencesInBackground();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: const Color(0xFF0BA1D8),
                      activeTrackColor: const Color(0xFF0A78A3),
                      title: Text(
                        _t('show_usage'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: _showUsageInfo,
                      onChanged: (v) {
                        setState(() => _showUsageInfo = v);
                        _savePreferencesInBackground();
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t('usage_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _t('usage_body'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _fullScaleAngle = _defaultFullScaleAngle;
                            _levelTolerance = _defaultLevelTolerance;
                            _smoothing = _defaultSmoothing;
                          });
                          _savePreferencesInBackground();
                          setModalState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Text(_t('reset_defaults')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final projected = _projectAngles(_roll, _pitch);
    final displayX = projected.$1;
    final displayY = projected.$2;
    final xNorm = (displayX / _fullScaleAngle).clamp(-1.0, 1.0);
    final yNorm = (displayY / _fullScaleAngle).clamp(-1.0, 1.0);
    final bubbleColor = _isLevel ? const Color(0xFF2CB7EA) : const Color(0xFF0B8DC0);

    return Scaffold(
      backgroundColor: const Color(0xFF202126),
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final panelWidth = math.max(0.0, math.min(540.0, constraints.maxWidth - 28));
                final centerHeight =
                    math.max(220.0, math.min(constraints.maxHeight * 0.42, 380.0));

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: panelWidth,
                          child: _HorizontalVial(
                            xNorm: xNorm,
                            bubbleColor: bubbleColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: panelWidth,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _VerticalVial(
                                yNorm: yNorm,
                                height: centerHeight,
                                bubbleColor: bubbleColor,
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: _CircularLevel(
                                    xNorm: xNorm,
                                    yNorm: yNorm,
                                    bubbleColor: bubbleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        GestureDetector(
                          onLongPress: _calibrate,
                          onDoubleTap: _clearCalibration,
                          child: _ValuePanel(x: displayX, y: displayY),
                        ),
                        if (_showUsageInfo) ...[
                          const SizedBox(height: 10),
                          Text(
                            _hasSensorData
                                ? _t('hint_controls')
                                : _t('hint_emulator'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.52),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 14,
            bottom: 14,
            child: SafeArea(
              child: _buildReferenceControls(),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.small(
        onPressed: _openSettingsSheet,
        backgroundColor: const Color(0xFF0F1013),
        foregroundColor: const Color(0xFF0BA1D8),
        child: const Icon(Icons.settings),
      ),
    );
  }
}

class _HorizontalVial extends StatelessWidget {
  const _HorizontalVial({required this.xNorm, required this.bubbleColor});

  final double xNorm;
  final Color bubbleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1013),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tubeHeight = 52.0;
          final innerWidth = math.max(0.0, constraints.maxWidth - 52);
          final bubbleSize = math.min(56.0, tubeHeight - 10);
          final travel = math.max(0.0, (innerWidth - bubbleSize) / 2 - 6);
          final left = 26 + (innerWidth - bubbleSize) / 2 + (xNorm * travel);

          return Stack(
            children: [
              Positioned(
                left: 26,
                right: 26,
                top: (constraints.maxHeight - tubeHeight) / 2,
                child: Container(
                  height: tubeHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF93DCF7), Color(0xFF28B2E6), Color(0xFF0879A7)],
                    ),
                    border: Border.all(color: const Color(0xAA000000), width: 1.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _VialMarksPainter(isHorizontal: true),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          left: (innerWidth - bubbleSize) / 2 + (xNorm * travel),
                          top: (tubeHeight - bubbleSize) / 2,
                          child: _GlossBubble(size: bubbleSize, color: bubbleColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 22,
                bottom: 22,
                child: _TubeCap(isHorizontal: true),
              ),
              Positioned(
                right: 8,
                top: 22,
                bottom: 22,
                child: _TubeCap(isHorizontal: true),
              ),
              Positioned(
                left: left,
                top: (constraints.maxHeight - tubeHeight) / 2 + (tubeHeight - bubbleSize) / 2,
                child: IgnorePointer(
                  child: Container(
                    width: bubbleSize,
                    height: bubbleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      boxShadow: [
                        BoxShadow(
                          color: bubbleColor.withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VerticalVial extends StatelessWidget {
  const _VerticalVial({
    required this.yNorm,
    required this.height,
    required this.bubbleColor,
  });

  final double yNorm;
  final double height;
  final Color bubbleColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            right: 8,
            top: 18,
            bottom: 18,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF0879A7), Color(0xFF28B2E6), Color(0xFF93DCF7)],
                ),
                border: Border.all(color: const Color(0xAA000000), width: 1.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bubbleSize = math.min(52.0, constraints.maxWidth - 10);
                    final travel = math.max(0.0, (constraints.maxHeight - bubbleSize) / 2 - 6);
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _VialMarksPainter(isHorizontal: false),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          left: (constraints.maxWidth - bubbleSize) / 2,
                          top: (constraints.maxHeight - bubbleSize) / 2 + (yNorm * travel),
                          child: _GlossBubble(size: bubbleSize, color: bubbleColor),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 2,
            right: 2,
            child: _TubeCap(isHorizontal: false),
          ),
          Positioned(
            bottom: 0,
            left: 2,
            right: 2,
            child: _TubeCap(isHorizontal: false),
          ),
        ],
      ),
    );
  }
}

class _CircularLevel extends StatelessWidget {
  const _CircularLevel({
    required this.xNorm,
    required this.yNorm,
    required this.bubbleColor,
  });

  final double xNorm;
  final double yNorm;
  final Color bubbleColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.max(0.0, math.min(constraints.maxWidth, constraints.maxHeight));
        final bubbleSize = size * 0.20;
        final travel = size * 0.33;
        final dx = xNorm * travel;
        final dy = yNorm * travel;

        return Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0xCC000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF494D53), Color(0xFF1E2127)],
              ),
            ),
            child: ClipOval(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.1, 0.05),
                          radius: 1.1,
                          colors: [
                            const Color(0xFFB6E9FA),
                            const Color(0xFF3AB8E8),
                            const Color(0xFF0A6E95),
                          ],
                          stops: const [0.0, 0.62, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.20),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CircleGridPainter(),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    left: (size - bubbleSize) / 2 + dx,
                    top: (size - bubbleSize) / 2 + dy,
                    child: _GlossBubble(
                      size: bubbleSize,
                      color: bubbleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ValuePanel extends StatelessWidget {
  const _ValuePanel({required this.x, required this.y});

  final double x;
  final double y;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: math.min(MediaQuery.of(context).size.width - 48, 500),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0B0E), Color(0xFF101217)],
        ),
        border: Border.all(color: const Color(0xFF000000), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        'X: ${x.toStringAsFixed(1)}°   Y: ${y.toStringAsFixed(1)}°',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFF2F2F2),
          fontSize: 48 * 0.58,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _GlossBubble extends StatelessWidget {
  const _GlossBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.2),
          radius: 0.95,
          colors: [
            color.withValues(alpha: 0.98),
            const Color(0xFF67CBEF),
            const Color(0xFF0D7DAA),
          ],
        ),
        border: Border.all(color: Colors.black.withValues(alpha: 0.28), width: 1),
      ),
      child: Align(
        alignment: const Alignment(-0.42, -0.42),
        child: Container(
          width: size * 0.42,
          height: size * 0.26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.68),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.22),
                blurRadius: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TubeCap extends StatelessWidget {
  const _TubeCap({required this.isHorizontal});

  final bool isHorizontal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isHorizontal ? 12 : null,
      height: isHorizontal ? null : 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8E939A), Color(0xFF25272C)],
        ),
      ),
    );
  }
}

class _ReferenceGlyphPainter extends CustomPainter {
  const _ReferenceGlyphPainter({required this.mode});

  final _ReferenceMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.46;

    final badgeFill = Paint()
      ..color = const Color(0x2F9AC4F0)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, badgeFill);

    final linePaint = Paint()
      ..color = const Color(0xFF1A84D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round;

    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: size.shortestSide * 0.30,
        height: size.shortestSide * 0.56,
      ),
      const Radius.circular(2.4),
    );
    canvas.drawRRect(phoneRect, linePaint);

    final topY = phoneRect.top + 2.2;
    final bottomY = phoneRect.bottom - 2.2;
    canvas.drawLine(
      Offset(phoneRect.left + 3, topY),
      Offset(phoneRect.right - 3, topY),
      linePaint,
    );
    canvas.drawLine(
      Offset(phoneRect.left + 3, bottomY),
      Offset(phoneRect.right - 3, bottomY),
      linePaint,
    );

    final glyphText = mode == _ReferenceMode.auto ? 'A' : '0';
    final textPainter = TextPainter(
      text: TextSpan(
        text: glyphText,
        style: const TextStyle(
          color: Color(0xFF1A84D4),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    void drawEdgeMark(_ReferenceMode edge) {
      switch (edge) {
        case _ReferenceMode.bottom:
          canvas.drawLine(
            Offset(phoneRect.left + 2.4, phoneRect.bottom + 2.7),
            Offset(phoneRect.right - 2.4, phoneRect.bottom + 2.7),
            linePaint,
          );
          break;
        case _ReferenceMode.left:
          canvas.drawLine(
            Offset(phoneRect.left - 2.7, phoneRect.top + 2.4),
            Offset(phoneRect.left - 2.7, phoneRect.bottom - 2.4),
            linePaint,
          );
          break;
        case _ReferenceMode.top:
          canvas.drawLine(
            Offset(phoneRect.left + 2.4, phoneRect.top - 2.7),
            Offset(phoneRect.right - 2.4, phoneRect.top - 2.7),
            linePaint,
          );
          break;
        case _ReferenceMode.right:
          canvas.drawLine(
            Offset(phoneRect.right + 2.7, phoneRect.top + 2.4),
            Offset(phoneRect.right + 2.7, phoneRect.bottom - 2.4),
            linePaint,
          );
          break;
        case _ReferenceMode.auto:
          break;
      }
    }

    if (mode == _ReferenceMode.auto) {
      final leftArcRect = Rect.fromCenter(
        center: Offset(center.dx - 7.2, center.dy),
        width: 10,
        height: 18,
      );
      final rightArcRect = Rect.fromCenter(
        center: Offset(center.dx + 7.2, center.dy),
        width: 10,
        height: 18,
      );
      canvas.drawArc(leftArcRect, math.pi * 0.65, math.pi * 0.8, false, linePaint);
      canvas.drawArc(rightArcRect, -math.pi * 0.45, math.pi * 0.8, false, linePaint);
    } else {
      drawEdgeMark(mode);
    }
  }

  @override
  bool shouldRepaint(covariant _ReferenceGlyphPainter oldDelegate) {
    return oldDelegate.mode != mode;
  }
}

class _VialMarksPainter extends CustomPainter {
  const _VialMarksPainter({required this.isHorizontal});

  final bool isHorizontal;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xDD111214)
      ..strokeWidth = 2;

    if (isHorizontal) {
      final cx = size.width / 2;
      canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
      canvas.drawLine(Offset(cx - 18, 0), Offset(cx - 18, size.height), paint);
      canvas.drawLine(Offset(cx + 18, 0), Offset(cx + 18, size.height), paint);
    } else {
      final cy = size.height / 2;
      canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
      canvas.drawLine(Offset(0, cy - 18), Offset(size.width, cy - 18), paint);
      canvas.drawLine(Offset(0, cy + 18), Offset(size.width, cy + 18), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VialMarksPainter oldDelegate) {
    return oldDelegate.isHorizontal != isHorizontal;
  }
}

class _CircleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final cross = Paint()
      ..color = const Color(0xDD15181D)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), cross);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), cross);

    final tickPaint = Paint()
      ..color = const Color(0xDD15181D)
      ..strokeWidth = 1.6;
    final radius = size.width * 0.14;
    for (var i = 0; i < 56; i++) {
      final angle = (2 * math.pi * i) / 56;
      final inner = radius - (i % 7 == 0 ? 6 : 3);
      final outer = radius + (i % 7 == 0 ? 6 : 3);
      final p1 = Offset(
        center.dx + math.cos(angle) * inner,
        center.dy + math.sin(angle) * inner,
      );
      final p2 = Offset(
        center.dx + math.cos(angle) * outer,
        center.dy + math.sin(angle) * outer,
      );
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
