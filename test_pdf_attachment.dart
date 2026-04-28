import 'dart:io';

void main() async {
  const urlStr =
      "https://res.cloudinary.com/dmgikaeri/image/upload/fl_attachment/v1772795130/mindgymbook/books/pdf/gdrbinwqbonkjlhqi1z5.pdf";
  final url = Uri.parse(urlStr);

  try {
    final request = await HttpClient().getUrl(url);
    final response = await request.close();
    print("Status code: ${response.statusCode}");
  } catch (e) {
    print(e);
  }
}
