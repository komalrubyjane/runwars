import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/storage_utils.dart';
import '../../domain/entities/user.dart';
import '../mock/mock_data.dart';
import '../model/request/edit_password_request.dart';
import '../model/request/edit_profile_request.dart';
import '../model/request/login_request.dart';
import '../model/request/registration_request.dart';
import '../model/request/send_new_password_request.dart';
import '../model/response/login_response.dart';
import '../model/response/user_response.dart';
import 'helpers/api_helper.dart';

/// API methods for managing user-related operations.
class UserApi {
  /// Creates a new user.
  ///
  /// Returns the user ID as an integer.
  static Future<int> createUser(RegistrationRequest request) async {
    if (AppConfig.useMockData) {
      print('DEBUG: Using mock registration data');
      return MockData.mockUserId();
    }

    try {
      Response? response = await ApiHelper.makeRequest(
          '${ApiHelper.apiUrl}user/register', 'POST',
          data: request.toMap());
      
      final userId = response?.data;
      print('DEBUG: Registration response data: $userId (type: ${userId.runtimeType})');
      
      if (userId == null) {
        print('DEBUG: Response data is null');
        return 0;
      }
      if (userId is int) {
        print('DEBUG: User ID is int: $userId');
        return userId;
      }
      if (userId is String && userId.isNotEmpty) {
        try {
          final parsed = int.parse(userId);
          print('DEBUG: Parsed user ID from string: $parsed');
          return parsed;
        } catch (e) {
          print('DEBUG: Failed to parse user ID from string "$userId": $e');
          return 0;
        }
      }
      print('DEBUG: Unexpected response format: $userId');
      return 0;
    } catch (e) {
      print('DEBUG: Exception in createUser: $e');
      rethrow;
    }
  }

  /// Logs in a user.
  ///
  /// Returns a [LoginResponse] object.
  static Future<LoginResponse> login(LoginRequest request) async {
    if (AppConfig.useMockData) {
      print('DEBUG: Using mock login data');
      return MockData.mockLoginResponse();
    }

    try {
      Response? response = await ApiHelper.makeRequest(
          '${ApiHelper.apiUrl}user/login', 'POST',
          data: request.toMap());

      print('DEBUG: Login response data: ${response?.data} (type: ${response?.data.runtimeType})');
      print('DEBUG: Login response statusCode: ${response?.statusCode}');
      
      if (response?.data == null) {
        throw Exception('Login response is null');
      }
      
      if (response?.data is String) {
        print('DEBUG: Login response is a String, attempting to parse as JSON');
        try {
          final jsonData = jsonDecode(response!.data);
          return LoginResponse.fromMap(jsonData);
        } catch (e) {
          throw Exception('Failed to parse login response: $e. Response was: ${response!.data}');
        }
      }
      
      if (response?.data is Map) {
        return LoginResponse.fromMap(response?.data);
      }
      
      throw Exception('Unexpected login response type: ${response?.data.runtimeType}. Data: ${response?.data}');
    } catch (e) {
      print('DEBUG: Login error: $e');
      rethrow;
    }
  }

  /// Logs out the current user.
  static Future<void> logout() async {
    await ApiHelper.makeRequest(
        '${ApiHelper.apiUrl}private/user/logout', 'POST');
  }

  /// Deletes the current user account.
  static Future<void> delete() async {
    await ApiHelper.makeRequest('${ApiHelper.apiUrl}private/user', 'DELETE');
  }

  /// Refreshes the JWT token using the refresh token.
  ///
  /// Returns the new JWT token as a string.
  static Future<String?> refreshToken() async {
    String? refreshToken = await StorageUtils.getRefreshToken();

    Response? response = await ApiHelper.makeRequest(
        '${ApiHelper.apiUrl}user/refreshToken', 'POST',
        data: {'token': refreshToken});

    String? jwt = response?.data['token'];
    await StorageUtils.setJwt(response?.data['token']);

    return jwt;
  }

  /// Send new password by mail
  ///
  /// Returns a [String].
  static Future<String> sendNewPasswordByMail(
      SendNewPasswordRequest request) async {
    Response? response = await ApiHelper.makeRequest(
        '${ApiHelper.apiUrl}user/sendNewPasswordByMail', 'POST',
        queryParams: request.toMap());

    return response?.data;
  }

  /// Edit password
  ///
  /// Returns a [void] object.
  static Future<void> editPassword(EditPasswordRequest request) async {
    await ApiHelper.makeRequest(
        '${ApiHelper.apiUrl}private/user/editPassword', 'PUT',
        data: request.toMap());
  }

  /// Edit profile
  ///
  /// Returns a [void] object.
  static Future<void> editProfile(EditProfileRequest request) async {
    await ApiHelper.makeRequest(
        '${ApiHelper.apiUrl}private/user/editProfile', 'PUT',
        data: request.toMap());
  }

  /// Search users based on a search value
  ///
  /// Returns a List of [UserResponse] object.
  static Future<List<UserResponse>> search(String text) async {
    Response? response = await ApiHelper.makeRequest(
        '${ApiHelper.apiUrl}private/user/search', 'GET',
        queryParams: {'searchText': text});
    final data = List<Map<String, dynamic>>.from(response?.data);
    return data.map((e) => UserResponse.fromMap(e)).toList();
  }

  /// Download the profile picture of the user id
  ///
  /// Returns a [Uint8List] object.
  static Future<Uint8List?> downloadProfilePicture(String id) async {
    User? user = await StorageUtils.getUser();
    bool useCache = user != null ? user.id == id : false;
    Response? response = await ApiHelper.makeRequest(
        '${ApiHelper.apiUrl}user/picture/download/$id', 'GET',
        noCache: !useCache, responseType: ResponseType.bytes);

    if (response != null &&
        (response.statusCode == 404 || (response.statusCode == 500))) {
      return null;
    }

    if (response != null && response.data != null) {
      try {
        List<int> dataList = [];
        dataList = List<int>.from(response.data);
        Uint8List uint8List = Uint8List.fromList(dataList);
        return uint8List;
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Upload the profile picture of the current user
  static Future<void> uploadProfilePicture(Uint8List file) async {
    MultipartFile multipartFile = MultipartFile.fromBytes(
      file,
      filename: 'profile_picture.jpg',
    );
    await ApiHelper.makeRequest(
        '${ApiHelper.apiUrl}private/user/picture/upload', 'POST_FORM_DATA',
        data: {'file': multipartFile});
    User? user = await StorageUtils.getUser();
    if (user != null) {
      await ApiHelper.removeCacheForUrl(
          '${ApiHelper.apiUrl}user/picture/download/${user.id}');
    }
  }
}
