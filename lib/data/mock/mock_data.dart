import '../../../data/model/response/login_response.dart';
import '../../../data/model/response/user_response.dart';

/// Mock data for testing without a real backend.
class MockData {
  /// Mock login response
  static LoginResponse mockLoginResponse() {
    return LoginResponse(
      token: 'mock_jwt_token_abc123def456',
      refreshToken: 'mock_refresh_token_xyz789',
      user: UserResponse(
        id: '1',
        username: 'testuser',
        firstname: 'Test',
        lastname: 'User',
      ),
      message: 'Login successful',
    );
  }

  /// Mock user response
  static UserResponse mockUserResponse() {
    return UserResponse(
      id: '1',
      username: 'testuser',
      firstname: 'Test',
      lastname: 'User',
    );
  }

  /// Mock user ID for registration
  static int mockUserId() {
    return 1;
  }
}
