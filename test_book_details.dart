import 'dart:io';
import 'dart:convert';

void main() async {
  const bookId = "29";
  const baseUrl = "https://mindgymbook.ductfabrication.in";
  final uri = Uri.parse("$baseUrl/api/v1/book/$bookId");

  try {
    final client = HttpClient();
    final request = await client.getUrl(uri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    print(body);
  } catch (e) {
    print("Error: $e");
  }
}
