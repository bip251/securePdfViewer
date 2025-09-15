// Conditional export to pick web or non-web implementation.
export 'pdf_web_view_stub.dart'
  if (dart.library.html) 'pdf_web_view_html.dart';
