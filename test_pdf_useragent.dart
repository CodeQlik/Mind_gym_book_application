import 'dart:io';

void main() async {
  const urlStr =
      "https://res.cloudinary.com/dmgikaeri/raw/upload/v1772795130/mindgymbook/books/pdf/gdrbinwqbonkjlhqi1z5.pdf";
  final url = Uri.parse(urlStr);

  try {
    final client = HttpClient();
    client.userAgent =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
    final request = await client.getUrl(url);
    final response = await request.close();
    print("Status code: ${response.statusCode}");
    print("Headers: ${response.headers}");
  } catch (e) {
    print(e);
  }
}
