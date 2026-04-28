import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse(
      "https://mindgymbook.ductfabrication.in/api/v1/book/content/29");
  try {
    final request = await HttpClient().getUrl(url);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    print("API Response: $responseBody");

    // If there's a file url, try getting it as well
    final data = json.decode(responseBody);
    final fileUrl = data['data']['file_url'];
    print("Testing fileUrl: $fileUrl");
    final req2 = await HttpClient().getUrl(Uri.parse(fileUrl));
    final res2 = await req2.close();
    print("File URL Content-Type: ${res2.headers.contentType}");
  } catch (e) {
    print(e);
  }
}
