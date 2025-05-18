import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_router/shelf_router.dart';

void main() async {
  // Serve static Flutter Web files
  final staticHandler = createStaticHandler('build/web', defaultDocument: 'index.html');

  // Router untuk API backend
  final router = Router();

  router.get('/api/hello', (Request req) {
    return Response.ok('Hello from backend!');
  });

  // Kombinasi router dan static handler
  final handler = Cascade()
      .add(router)
      .add(staticHandler)
      .handler;

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);

  print('Server running on http://${server.address.host}:${server.port}');
}
