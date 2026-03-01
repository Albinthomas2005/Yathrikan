import 'dart:convert';
import 'package:http/http.dart' as http;

class MbtaService {
  static const String _apiKey = "ddec6fb4aadf4f4db40509fc75891796";

  static Future<List<dynamic>> fetchVehicles() async {
    // Using a CORS proxy because flutter web blocks direct requests to MBTA API
    const targetUrl = "https://api-v3.mbta.com/vehicles?api_key=$_apiKey";
    final url = Uri.parse("https://api.codetabs.com/v1/proxy?quest=$targetUrl");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["data"];
    } else {
      throw Exception("Failed to load vehicles");
    }
  }
}
