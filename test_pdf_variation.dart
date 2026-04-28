import 'dart:io';

void main() async {
  final List<String> urlsToTest = [
    "https://res.cloudinary.com/dmgikaeri/raw/upload/mindgymbook/books/pdf/gdrbinwqbonkjlhqi1z5.pdf",
    "https://res.cloudinary.com/dmgikaeri/image/upload/fl_attachment/mindgymbook/books/pdf/gdrbinwqbonkjlhqi1z5.pdf",
    "https://res.cloudinary.com/dmgikaeri/image/upload/mindgymbook/books/pdf/gdrbinwqbonkjlhqi1z5.pdf",
    "https://res.cloudinary.com/dmgikaeri/raw/upload/mindgymbook/books/pdf/gdrbinwqbonkjlhqi1z5",
  ];

  for (final urlStr in urlsToTest) {
    try {
      final request = await HttpClient().getUrl(Uri.parse(urlStr));
      final response = await request.close();
      print("Status code: ${response.statusCode} for $urlStr");
    } catch (e) {}
  }
}
