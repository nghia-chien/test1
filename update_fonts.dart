import 'dart:io';

void main() {
  print('Thay thế font Montserrat thành Roboto...');
  
  // Danh sách các file cần cập nhật
  final files = [
    'lib/pages/register_pages.dart',
    'lib/pages/question_page.dart',
    'lib/pages/login_page.dart',
    'lib/main.dart',
  ];
  
  for (final filePath in files) {
    final file = File(filePath);
    if (file.existsSync()) {
      String content = file.readAsStringSync();
      
      // Thay thế fontFamily: 'Montserrat' thành fontFamily: 'Roboto'
      content = content.replaceAll("fontFamily: 'Montserrat'", "fontFamily: 'Roboto'");
      content = content.replaceAll('fontFamily: "Montserrat"', 'fontFamily: "Roboto"');
      
      // Thay thế trong ThemeData
      content = content.replaceAll("ThemeData(fontFamily: 'Montserrat')", "ThemeData(fontFamily: 'Roboto')");
      
      file.writeAsStringSync(content);
      print('Đã cập nhật: $filePath');
    }
  }
  
  print('Hoàn thành thay thế font!');
} 