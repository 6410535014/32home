// State pattern — represents the auth flow lifecycle
abstract class AuthState {
  const AuthState();
}

class AuthIdle extends AuthState {
  const AuthIdle();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthOtpSent extends AuthState {
  final String verificationId;
  const AuthOtpSent(this.verificationId);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
