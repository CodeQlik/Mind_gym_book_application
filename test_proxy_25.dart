import 'dart:io';
import 'dart:convert';

void main() async {
  const bookId = "25"; // From the user's log
  const token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MzEsImlhdCI6MTc3MzY0ODU1NCwiZXhwIjoxNzczNzM0OTU0fQ.w-mYbIWWlRVsWpsnrOeYq-JX-Io0G6BfHwbP89QJ7LM"; // From summary
  
  final proxyUrl = "https://mindgymbook.ductfabrication.in/api/v1/book/readBook/$bookId";
  
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(proxyUrl));
    request.headers.add("Authorization", "Bearer $token");
    final response = await request.close();
    
    print("Proxy Status Code: ${response.statusCode}");
    print("Proxy Content-Type: ${response.headers.contentType}");
    
    if (response.statusCode == 200) {
      final bytes = await response.fold<List<int>>([], (p, e) => p..addAll(e));
      print("First 10 bytes: ${bytes.take(10).toList()}");
      if (bytes.length > 10) {
        final text = utf8.decode(bytes.take(50).toList(), allowMalformed: true);
        print("Start of text: $text");
      }
    }
  } catch (e) {
    print("Error: $e");
  }
}
