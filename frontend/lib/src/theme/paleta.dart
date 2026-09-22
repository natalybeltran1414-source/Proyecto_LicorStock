import 'package:flutter/material.dart';

/// Paleta con contraste verificado WCAG AA (portada 1:1 desde paletas.js).
@immutable
class Paleta {
  final bool esOscuro;

  final Color background;
  final Color surface;
  final Color card;
  final Color cardLight;
  final Color border;
  final Color borderSubtle;

  final Color gold;
  final Color goldLight;
  final Color goldDark;
  final Color goldSoft;
  final Color sobreDorado;

  final Color text;
  final Color textSecondary;
  final Color textMuted;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;

  final List<Color> gradientGold;
  final List<Color> gradientDark;
  final List<Color> gradientCard;

  final Color shadowGoldColor;
  final double shadowGoldOpacity;
  final double shadowGoldRadius;
  final double shadowGoldDy;
  final double shadowGoldElev;

  final Color shadowCardColor;
  final double shadowCardOpacity;
  final double shadowCardRadius;
  final double shadowCardDy;
  final double shadowCardElev;

  const Paleta({
    required this.esOscuro,
    required this.background,
    required this.surface,
    required this.card,
    required this.cardLight,
    required this.border,
    required this.borderSubtle,
    required this.gold,
    required this.goldLight,
    required this.goldDark,
    required this.goldSoft,
    required this.sobreDorado,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
    required this.gradientGold,
    required this.gradientDark,
    required this.gradientCard,
    required this.shadowGoldColor,
    required this.shadowGoldOpacity,
    required this.shadowGoldRadius,
    required this.shadowGoldDy,
    required this.shadowGoldElev,
    required this.shadowCardColor,
    required this.shadowCardOpacity,
    required this.shadowCardRadius,
    required this.shadowCardDy,
    required this.shadowCardElev,
  });

  List<BoxShadow> sombraDorada() => <BoxShadow>[
        BoxShadow(
          color: shadowGoldColor.withValues(alpha: shadowGoldOpacity),
          offset: Offset(0, shadowGoldDy),
          blurRadius: shadowGoldRadius,
        ),
      ];

  List<BoxShadow> sombraCard() => <BoxShadow>[
        BoxShadow(
          color: shadowCardColor.withValues(alpha: shadowCardOpacity),
          offset: Offset(0, shadowCardDy),
          blurRadius: shadowCardRadius,
        ),
      ];
}

const Paleta paletaOscura = Paleta(
  esOscuro: true,
  background: Color(0xFF0B0E17),
  surface: Color(0xFF121726),
  card: Color(0xFF171D30),
  cardLight: Color(0xFF1D2540),
  border: Color.fromRGBO(217, 180, 74, 0.18),
  borderSubtle: Color.fromRGBO(255, 255, 255, 0.07),
  gold: Color(0xFFD9B44A),
  goldLight: Color(0xFFF0D98C),
  goldDark: Color(0xFF9C7C1E),
  goldSoft: Color.fromRGBO(217, 180, 74, 0.14),
  sobreDorado: Color(0xFF241B04),
  text: Color(0xFFF5F7FC),
  textSecondary: Color(0xFFA7AEC1),
  textMuted: Color(0xFF8B93A8),
  success: Color(0xFF4ADE8F),
  successSoft: Color.fromRGBO(74, 222, 143, 0.13),
  warning: Color(0xFFFFB020),
  warningSoft: Color.fromRGBO(255, 176, 32, 0.13),
  danger: Color(0xFFFF7A7A),
  dangerSoft: Color.fromRGBO(255, 122, 122, 0.13),
  info: Color(0xFF6FB3FF),
  infoSoft: Color.fromRGBO(111, 179, 255, 0.13),
  gradientGold: [Color(0xFFF0D98C), Color(0xFFD4AF37), Color(0xFFA8842A)],
  gradientDark: [Color(0xFF1C2438), Color(0xFF111624)],
  gradientCard: [Color(0xFF1A2136), Color(0xFF141A2B)],
  shadowGoldColor: Color(0xFFD4AF37),
  shadowGoldOpacity: 0.35,
  shadowGoldRadius: 14,
  shadowGoldDy: 6,
  shadowGoldElev: 8,
  shadowCardColor: Color(0xFF000000),
  shadowCardOpacity: 0.35,
  shadowCardRadius: 16,
  shadowCardDy: 8,
  shadowCardElev: 6,
);

const Paleta paletaClara = Paleta(
  esOscuro: false,
  background: Color(0xFFF4F6FA),
  surface: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  cardLight: Color(0xFFEDF0F7),
  border: Color.fromRGBO(140, 109, 31, 0.28),
  borderSubtle: Color(0xFFE4E8F0),
  gold: Color(0xFF8C6D1F),
  goldLight: Color(0xFF7A5E14),
  goldDark: Color(0xFF6E5512),
  goldSoft: Color.fromRGBO(140, 109, 31, 0.12),
  sobreDorado: Color(0xFF241B04),
  text: Color(0xFF1B2233),
  textSecondary: Color(0xFF45506B),
  textMuted: Color(0xFF5D6780),
  success: Color(0xFF147A4E),
  successSoft: Color.fromRGBO(20, 122, 78, 0.10),
  warning: Color(0xFF9A6200),
  warningSoft: Color.fromRGBO(154, 98, 0, 0.10),
  danger: Color(0xFFC03636),
  dangerSoft: Color.fromRGBO(192, 54, 54, 0.10),
  info: Color(0xFF1D5FBF),
  infoSoft: Color.fromRGBO(29, 95, 191, 0.10),
  gradientGold: [Color(0xFFF3D98B), Color(0xFFDDAF3F), Color(0xFFB98A20)],
  gradientDark: [Color(0xFFFFFFFF), Color(0xFFE7EBF3)],
  gradientCard: [Color(0xFFFFFFFF), Color(0xFFF3F5FA)],
  shadowGoldColor: Color(0xFFB98A20),
  shadowGoldOpacity: 0.25,
  shadowGoldRadius: 10,
  shadowGoldDy: 5,
  shadowGoldElev: 5,
  shadowCardColor: Color(0xFF1B2233),
  shadowCardOpacity: 0.08,
  shadowCardRadius: 10,
  shadowCardDy: 4,
  shadowCardElev: 3,
);

const Map<String, Paleta> paletas = <String, Paleta>{
  'oscuro': paletaOscura,
  'claro': paletaClara,
};