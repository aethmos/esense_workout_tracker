
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final colorBg = Color(0xFFEAEAEA);

final colorFgLight = Color(0xFF707070);
final colorFg = Color(0xFF1E1E1E);
final colorFgBold = Color(0xFF1A1A1A);

final colorAccent = Color(0xFF8E00CC);

final colorGradientBegin = Color(0xFFB143E0);
final colorGradientEnd = Color(0xFFF6009B);

final colorAccentBorder = Color(0xFF8E00CC).withOpacity(0.5);
final colorShadowDark = Color(0xFF000000).withOpacity(0.16);
final colorShadowLight = Color(0xFFFFFFFF).withOpacity(0.8);

final colorGood = Color(0xFF19C530);
final colorNeutral = Color(0xFFE6A100);
final colorDanger = Color(0xFFE1154B);

final textCalendarDayToday = TextStyle(
  fontFamily: "Jost*",
  fontWeight: FontWeight.w500,
  fontSize: 35,
  color: colorAccent,
);
final textCalendarDay = TextStyle(
  fontFamily: "Jost*",
  fontWeight: FontWeight.w500,
  fontSize: 35,
  color: colorFgBold,
);
final textCalendarMonth = TextStyle(
  fontFamily: "Jost*",
  fontWeight: FontWeight.w300,
  fontSize: 16,
  color: colorFgLight,
);

final textActivityLabel = TextStyle(
  fontFamily: "Jost*",
  fontWeight: FontWeight.w500,
  fontSize: 28,
  color: colorFgBold,
);
final textActivityCounter = TextStyle(
  fontFamily: "Jost*",
  fontWeight: FontWeight.w500,
  fontSize: 35,
  color: colorAccent,
);

final textHeading = TextStyle(
  fontFamily: "Jost*",
  fontWeight: FontWeight.w300,
  fontSize: 26,
  color: colorFg,
);
final textSubheading = TextStyle(
  fontFamily: "Jost*",
  fontWeight: FontWeight.w300,
  fontSize: 16,
  color: colorFgLight,
);

final borderRadius = BorderRadius.circular(12.00);

final elevationShadow = [
  BoxShadow(
    offset: Offset(-3.00, -3.00),
    color: colorShadowLight,
    blurRadius: 6,
  ),
  BoxShadow(
    offset: Offset(3.00, 3.00),
    color: colorShadowDark,
    blurRadius: 6,
  ),
];

final elevationShadowLight = [
  BoxShadow(
    offset: Offset(-2.00, -2.00),
    color: colorShadowLight,
    blurRadius: 2,
  ),
  BoxShadow(
    offset: Offset(2.00, 2.00),
    color: colorShadowDark,
    blurRadius: 2,
  ),
];

final elevationShadowExtraLight = [
  BoxShadow(
    offset: Offset(-1.00, -1.00),
    color: colorShadowLight,
    blurRadius: 1,
  ),
  BoxShadow(
    offset: Offset(1.00, 1.00),
    color: colorShadowDark,
    blurRadius: 1,
  ),
];

final humanReadableDate = DateFormat('yyyy-MM-dd');
