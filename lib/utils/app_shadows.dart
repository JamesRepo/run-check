import 'package:flutter/material.dart';

abstract final class AppShadows {
  // Use sparingly — only on result cards.
  // Prefer tonal layering for most surfaces.
  static const editorialShadow = BoxShadow(
    offset: Offset(0, 8),
    blurRadius: 24,
    spreadRadius: -4,
    color: Color(0x0F181D1A),
  );
}
