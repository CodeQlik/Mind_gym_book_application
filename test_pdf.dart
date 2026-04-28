import 'dart:io';

void main() async {
  const urlStr =
      "https://res.cloudinary.com/dmgikaeri/raw/upload/v1772795130/mindgymbook/books/pdf/gdrbinwqbonkjlhqi1z5.pdf";
  final url = Uri.parse(urlStr);

  try {
    final request = await HttpClient().getUrl(url);
    final response = await request.close();
    print("Status code: ${response.statusCode}");
    print("Headers: ${response.headers}");
  } catch (e) {
    print(e);
  }
}
