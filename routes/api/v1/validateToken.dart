import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  if (context.request.method == HttpMethod.get) {
    // A dummy endpoint to validate access token
    // This route goes through a middleware that verifies the access token,
    // so if the access token is valid and we reach this route, that means
    // we return 200, if the access token is not valid, then the middleware
    // will return a 401, and we won't reach this route
    return _validateToken(context);
  } else {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Response _validateToken(RequestContext context) {
  return Response.json();
}
