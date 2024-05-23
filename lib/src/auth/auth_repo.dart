import 'package:supabase/supabase.dart';
import 'package:touch_cut_server/server_exception.dart';

/// An exception class for the authentication repository
class AuthRepoException extends ServerException {
  /// Constructor for the AuthRepoException class
  AuthRepoException({
    required String errorMessage,
    super.errorCode,
    super.errorBody,
  }) : super(
          errorMessage: 'AuthRepoException -> $errorMessage',
        );
}

class AuthRepo {
  /// Constructor
  const AuthRepo({required this.supabaseClient});

  /// The supabase client
  final SupabaseClient supabaseClient;

  /// Send OTP to user
  Future<void> sendOtpToUser({
    String? phoneNumber,
    String? email,
    Map<String, dynamic>? data,
  }) async {
    try {
      _validateEmailAndPhoneNumber(
        email: email,
        phoneNumber: phoneNumber,
      );
      await supabaseClient.auth.signInWithOtp(
        email: email,
        phone: phoneNumber,
        data: data,
      );
    } on AuthException catch (authException) {
      print(authException);
      throw AuthRepoException(
        errorCode: authException.statusCode,
        errorMessage: authException.toString(),
      );
    } catch (err) {
      print(err);
      throw AuthRepoException(
        errorMessage: err.toString(),
      );
    }
  }

  /// Resend OTP to user
  Future<void> resendOtpToUser({
    String? phoneNumber,
    String? email,
  }) async {
    try {
      _validateEmailAndPhoneNumber(
        email: email,
        phoneNumber: phoneNumber,
      );
      await supabaseClient.auth.resend(
        type: phoneNumber != null ? OtpType.sms : OtpType.email,
        phone: phoneNumber,
        email: email,
      );
    } on AuthException catch (authException) {
      print(authException);
      throw AuthRepoException(
        errorCode: authException.statusCode,
        errorMessage: authException.toString(),
      );
    } catch (err) {
      print(err);
      throw AuthRepoException(
        errorMessage: err.toString(),
      );
    }
  }

  /// Verify the token and return the user
  Future<User?> verifyAccessToken({
    required String accessToken,
  }) async {
    try {
      final userResponse = await supabaseClient.auth.getUser(accessToken);
      print("Got the user $userResponse");
      return userResponse.user;
    } on AuthException catch (authException) {
      print(authException);
      // We will have a wrapper that sends a 401 status code if the user is null
      return null;
    } catch (err) {
      throw AuthRepoException(
        errorMessage: err.toString(),
      );
    }
  }

  /// Verifies the OTP supplied by the user, and returns
  /// the access and refresh token, after creating a session
  /// for the user
  Future<Map<String, String>> verifyOTP({
    required String token,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      _validateEmailAndPhoneNumber(
        email: email,
        phoneNumber: phoneNumber,
      );
      final authResponse = await supabaseClient.auth.verifyOTP(
        type: phoneNumber != null ? OtpType.sms : OtpType.email,
        token: token,
        phone: phoneNumber,
        email: email,
      );
      print('Hello $authResponse');
      final session = authResponse.session!;
      return {
        'access_token': session.accessToken,
        'refresh_token': session.refreshToken!,
      };
    } on AuthException catch (authException) {
      print(authException);
      throw AuthRepoException(
        errorCode: authException.statusCode,
        errorMessage: authException.toString(),
      );
    } catch (err) {
      throw AuthRepoException(
        errorMessage: err.toString(),
      );
    }
  }

  void _validateEmailAndPhoneNumber({
    String? email,
    String? phoneNumber,
  }) {
    if (phoneNumber == null && email == null) {
      throw Exception('Phone number and email cannot be null');
    }
    if (phoneNumber != null && email != null) {
      throw Exception('Only supply either email or phone number');
    }
  }

  /// Refresh access and refresh token
  Future<Map<String, String>> refreshAccessToken({
    required String refreshToken,
  }) async {
    try {
      final authResponse = await supabaseClient.auth.setSession(refreshToken);
      final session = authResponse.session!;
      return {
        'access_token': session.accessToken,
        'refresh_token': session.refreshToken!,
      };
    } on AuthException catch (authException) {
      throw AuthRepoException(
        errorCode: authException.statusCode,
        errorMessage: authException.toString(),
      );
    } catch (err) {
      throw AuthRepoException(
        errorMessage: err.toString(),
      );
    }
  }

  /// This function checks if the supplied phone number from the customer is
  /// in the DB, while trying to sign in. If not found, that means no customer
  /// exits with that phone number, therefore, we will return an error asking
  /// them to sign-up, if found, we will go ahead and send an SMS containing
  /// an OTP.
  /// IMPORTANT -> This is used to check customers, since customers sign in
  /// using phone numbers.
  Future<bool> customerPhoneNumberExists({required String phoneNumber}) async {
    // Supabase DB saves the phone number without the + sign
    var phoneNumberToCheck = phoneNumber;
    if (phoneNumber.startsWith('+')) {
      phoneNumberToCheck = phoneNumber.substring(1);
    }
    final data = await supabaseClient
        .from('customers')
        .select()
        .eq('phone_number', phoneNumberToCheck);
    if (data.isEmpty) {
      print('$phoneNumber not found in the system');
      return false;
    }
    print('$phoneNumber found in the system');
    return true;
  }

  /// Same check for the customer phone number, but in here, we check
  /// the email of the barbershop
  /// IMPORTANT -> This is used to check barbershops, since they sign in
  /// using emails.
  Future<bool> barbershopEmailExists({required String email}) async {
    final data =
        await supabaseClient.from('barbershops').select().eq('email', email);
    if (data.isEmpty) {
      print('$email not found in the system');
      return false;
    }
    print('$email found in the system');
    return true;
  }
}
