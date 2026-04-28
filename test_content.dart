import 'dart:io';
import 'dart:convert';

void main() async {
  const url18 = "https://mindgymbook.ductfabrication.in/api/v1/book/content/18";
  const url29 = "https://mindgymbook.ductfabrication.in/api/v1/book/content/29";

  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url18));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    print("Content API 18: $responseBody");
  } catch (e) {}

  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url29));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    print("Content API 29: $responseBody");
  } catch (e) {}
}
