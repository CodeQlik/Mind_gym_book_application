import 'dart:io';

void main() async {
  const urlStr =
      "https://res.cloudinary.com/dmgikaeri/raw/upload/v1772795130/mindgymbook/books/pdf/gdrbinwqbonkjlhqi1z5.pdf";
  final url = Uri.parse(urlStr);

  try {
    final client = HttpClient();
    final request = await client.getUrl(url);
    request.headers.add('User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    request.headers.add('Accept',
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7');
    request.headers.add('Accept-Language', 'en-US,en;q=0.9');
    request.headers.add('Sec-Fetch-Dest', 'document');
    request.headers.add('Sec-Fetch-Mode', 'navigate');
    request.headers.add('Sec-Fetch-Site', 'none');
    final response = await request.close();
    print("Status code: ${response.statusCode}");
  } catch (e) {
    print(e);
  }
}
