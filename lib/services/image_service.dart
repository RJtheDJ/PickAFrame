import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';

Future<Uint8List?> extractFrameTexture(String imagePath) async {
  // Replace this IP with your computer's actual local IPv4 address
  var uri = Uri.parse('http://192.168.0.10:8000/remove-bg/'); 
  var request = http.MultipartRequest('POST', uri);
  
  request.files.add(await http.MultipartFile.fromPath('file', imagePath));
  
  try {
    // Force a timeout after 15 seconds
    var response = await request.send().timeout(const Duration(seconds: 120));
    if (response.statusCode == 200) {
      return await response.stream.toBytes(); 
    } else {
      print("Server returned error: ${response.statusCode}");
    }
  } catch (e) {
    print("Error contacting Python backend: $e");
  }
  return null;
}

Future<List<String>> fetchPolyHavenWoodTextures() async {
  final uri = Uri.parse('https://api.polyhaven.com/assets?t=textures&c=wood');
  
  try {
    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'PickAFrameApp/1.0', // Required by Poly Haven API
      }
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data.keys.map((assetId) => 
        'https://cdn.polyhaven.com/asset_img/primary/$assetId.png?width=512&height=512'
      ).toList();
    }
  } catch (e) {
    print("Error contacting Poly Haven: $e");
  }
  return [];
}