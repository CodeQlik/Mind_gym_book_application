import 'dart:io';
import 'dart:convert';

void main() async {
  const urlStr =
      "https://mindgymbook.ductfabrication.in/api/v1/book/readBook/bcacf6175e07b0f2d1b762a0d36ec538:12a46c2a35aa4580a18ba10cc806f5b1";

  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(urlStr));
    final response = await request.close();
    print("Direct GET readBook Status code: ${response.statusCode}");
    print("Content-Type: ${response.headers.contentType}");

    // Read small amount to see if it's JSON or binary
    final responseBody =
        await response.transform(utf8.decoder).take(1).toList();
    if (responseBody.isNotEmpty) {
      print("Body sample: ${responseBody[0].substring(0, 100)}...");
    }
  } catch (e) {
    print(e);
  }

  try {
    const decUrl = "https://mindgymbook.ductfabrication.in/api/v1/decrypt";
    final client = HttpClient();
    final req = await client.postUrl(Uri.parse(decUrl));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({"url": urlStr}));
    final res = await req.close();
    print("Decrypt POST Status code: ${res.statusCode}");
  } catch (e) {}
}
