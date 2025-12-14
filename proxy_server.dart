import 'dart:io';
import 'dart:convert';

void main() async {
  final server = await HttpServer.bind('localhost', 8080);
  print('Proxy server corriendo en http://localhost:8080');
  print('Usa este proxy para evitar problemas de CORS durante desarrollo\n');

  await for (HttpRequest request in server) {
    // Habilitar CORS
    request.response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Content-Type, Cookie, x-target-url')
      ..set('Access-Control-Allow-Credentials', 'true');

    // Manejar preflight requests
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    try {
      // Obtener la URL de destino
      final targetUrl = request.headers.value('x-target-url');
      
      if (targetUrl == null) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write('Missing x-target-url header');
        await request.response.close();
        continue;
      }

      print('Proxy request to: $targetUrl');

      // Leer el body
      final body = await utf8.decoder.bind(request).join();
      
      // Crear cliente HTTP
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true; // Aceptar certificados autofirmados
      
      final uri = Uri.parse(targetUrl);
      final proxyRequest = await client.postUrl(uri);
      
      // Copiar headers importantes
      proxyRequest.headers
        ..set('Content-Type', 'application/json')
        ..set('Accept', 'application/json');
      
      // Escribir body
      proxyRequest.write(body);
      
      // Obtener respuesta
      final proxyResponse = await proxyRequest.close();
      
      // Copiar status code
      request.response.statusCode = proxyResponse.statusCode;
      
      // Leer y enviar respuesta
      final responseBody = await utf8.decoder.bind(proxyResponse).join();
      print('Response: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}...\n');
      
      request.response.write(responseBody);
      await request.response.close();
      
      client.close();
    } catch (e) {
      print('Error en proxy: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Proxy error: $e');
      await request.response.close();
    }
  }
}
