import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skapp/config.dart';
import 'package:logging/logging.dart';
import 'package:skapp/services/auth_service.dart';
class FriendsService {
  var client = http.Client();
  final String baseUrl = AppConfig.baseUrl;
  String get url => '$baseUrl/friends/list/';
  final _logger = Logger('FriendsService');
  final _authService =  AuthService();

  List<Map<String, dynamic>>? _friends = [];
  Future<List<Map<String, dynamic>>> getFriends() async {
    try{


      String? token = await _authService.getToken();
      if (token==null){
        _logger.warning('No authentication token available ');
        throw 'Session expired. Please log in again.';
      }
      http.Response response = await client.get(Uri.parse(url),headers: {
        'Authorization': 'Bearer $token',  // Use 'Token' if using DRF TokenAuth
        'Content-Type': 'application/json',
      },
      );
      _logger.info('Response status code from friends: ${response.statusCode}');
      if (response.statusCode==200){
          _friends = jsonDecode(response.body).cast<Map<String, dynamic>>();
          _logger.info('Friends fetched successfully');
          _logger.info(_friends);
      }
    }
    catch (e){
      _logger.severe('Error loading friends: $e');
    }
    return _friends!;
  }

}
