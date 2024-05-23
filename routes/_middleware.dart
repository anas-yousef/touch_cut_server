import 'package:dart_frog/dart_frog.dart';
import 'package:touch_cut_server/src/auth/auth_repo.dart';

import '../main.dart';

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())

      /// AuthRepo will be used as a middleware:
      /// 1. Send the OTP to the user.
      /// 2. Validate the OTP supplied by the user.
      /// 3. Authenticate every inbound request when
      /// needed (whether the access token supplied is valid).
      /// 4. To refresh the access token.
      .use(provider<AuthRepo>((_) => authRepo));
}
