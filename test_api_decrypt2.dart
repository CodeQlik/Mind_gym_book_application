import 'dart:io';
import 'dart:convert';

void main() async {
  const urlStr =
      "https://mindgymbook.ductfabrication.in/api/v1/book/readBook/bcacf6175e07b0f2d1b762a0d36ec538:12a46c2a35aa4580a18ba10cc806f5b1";

  try {
    final client = HttpClient();
    final req = await client.postUrl(Uri.parse(
        "https://mindgymbook.ductfabrication.in/api/v1/book/decrypt"));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({"url": urlStr}));
    final res = await req.close();
    print("Decrypt POST Status code: ${res.statusCode}");
  } catch (e) {}

  try {
    final client = HttpClient();
    final req = await client.postUrl(
        Uri.parse("https://mindgymbook.ductfabrication.in/api/v1/decryptUrl"));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({"url": urlStr}));
    final res = await req.close();
    print("Decrypt POST Status code: ${res.statusCode}");
  } catch (e) {}
}
