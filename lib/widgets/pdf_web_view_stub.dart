// Stub (non-web) implementation. This file is used on mobile/desktop builds.
import 'package:flutter/material.dart';

Widget buildWebPdfView(String url) {
  return const Center(
    child: Text(
      'Web PDF view is not available on this platform.',
      textAlign: TextAlign.center,
    ),
  );
}
