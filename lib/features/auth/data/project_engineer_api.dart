import 'dart:convert';

import 'package:http/http.dart' as http;

class ProjectEngineerApi {
  ProjectEngineerApi({http.Client? client, this.baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000')}) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<String> login({required String phone, required String password}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/projectengineerlogin'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    final Map<String, dynamic> result;
    try {
      result = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const ApiException('The server returned an invalid response.');
    }
    if (response.statusCode != 200 || result['success'] != true) {
      throw ApiException(result['message']?.toString() ?? 'Login failed (${response.statusCode}).');
    }
    final token = result['token']?.toString();
    if (token == null || token.isEmpty) throw const ApiException('Login response did not include a token.');
    return token;
  }

  Future<Map<String, dynamic>> siteEngineerLogin({required String name, required String password}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/siteadminlogin'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'password': password}),
    );
    final result = _decode(response.body);
    if (response.statusCode != 200 || result['success'] == false) {
      throw ApiException(result['message']?.toString() ?? 'Login failed (${response.statusCode}).');
    }
    final token = result['token']?.toString();
    if (token == null || token.isEmpty) throw const ApiException('Login response did not include a token.');
    return {...result, 'token': token};
  }

  Future<String> estimatorLogin({required String phone, required String password}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/estimatorlogin'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    final result = _decode(response.body);
    if (response.statusCode != 200 || result['success'] == false) {
      throw ApiException(result['message']?.toString() ?? 'Login failed (${response.statusCode}).');
    }
    final token = result['token']?.toString();
    if (token == null || token.isEmpty) throw const ApiException('Login response did not include a token.');
    return token;
  }

  Future<Map<String, dynamic>> getProjects(String token) => _request('GET', '/api/getprojects', token: token);
  Future<Map<String, dynamic>> getEstimatorProjects(String token) => _request('GET', '/api/estimator/projects', token: token);
  Future<Map<String, dynamic>> getProjectCounts(String token) => _request('GET', '/api/getprojectcounts', token: token);
  Future<Map<String, dynamic>> getAssignedProjects(String token, {String? siteEngineer}) {
    final query = siteEngineer == null || siteEngineer.trim().isEmpty
        ? ''
        : '?siteEngineer=${Uri.encodeQueryComponent(siteEngineer.trim())}';
    return _request('GET', '/api/getassignedprojects$query', token: token);
  }
  Future<Map<String, dynamic>> createProject(String token, {required String projectName, required String title, required String description}) =>
      _request('POST', '/api/createproject', token: token, body: {'projectname': projectName, 'title': title, 'description': description}, expectedStatus: 201);
  Future<Map<String, dynamic>> updateProject(String token, String id, {required String title, required String description}) =>
      _request('PUT', '/api/updateproject/${Uri.encodeComponent(id)}', token: token, body: {'title': title, 'description': description});
  Future<Map<String, dynamic>> assignProject(String token, String id, {required String siteEngineer}) =>
      _request('PUT', '/api/assignproject/${Uri.encodeComponent(id)}', token: token, body: {'siteEngineer': siteEngineer});

  Future<Map<String, dynamic>> createMeasurement(String token, Map<String, dynamic> body) => _request('POST', '/api/createmaeasurment', token: token, body: body);
  Future<Map<String, dynamic>> createLabour(String token, Map<String, dynamic> body) => _request('POST', '/api/cretaelabour', token: token, body: body);
  Future<Map<String, dynamic>> createMaterial(String token, Map<String, dynamic> body) => _request('POST', '/api/creatematerial', token: token, body: body);
  Future<Map<String, dynamic>> getMeasurements(String token, {String? projectId, String? siteEngineer, String? status}) => _reportList(token, '/api/getmeasurement', projectId: projectId, siteEngineer: siteEngineer, status: status);
  Future<Map<String, dynamic>> getLabourReports(String token, {String? projectId, String? siteEngineer, String? status}) => _reportList(token, '/api/getlabour', projectId: projectId, siteEngineer: siteEngineer, status: status);
  Future<Map<String, dynamic>> getMaterialReports(String token, {String? projectId, String? siteEngineer, String? status}) => _reportList(token, '/api/getmaterial', projectId: projectId, siteEngineer: siteEngineer, status: status);
  Future<Map<String, dynamic>> updateMeasurement(String token, String id, Map<String, dynamic> body) => _request('PUT', '/api/updatemeasurement/${Uri.encodeComponent(id)}', token: token, body: body);
  Future<Map<String, dynamic>> updateLabour(String token, String id, Map<String, dynamic> body) => _request('PUT', '/api/updatelabour/${Uri.encodeComponent(id)}', token: token, body: body);
  Future<Map<String, dynamic>> updateMaterial(String token, String id, Map<String, dynamic> body) => _request('PUT', '/api/updatematerial/${Uri.encodeComponent(id)}', token: token, body: body);
  Future<Map<String, dynamic>> workflowPreview(String token, {required String projectId, required String siteEngineer}) => _request('GET', '/api/workflowpreview?projectId=${Uri.encodeQueryComponent(projectId)}&siteEngineer=${Uri.encodeQueryComponent(siteEngineer)}', token: token);
  Future<Map<String, dynamic>> submitWorkflow(String token, {required String projectId, required String siteEngineer}) => _request('PUT', '/api/submitworkflow', token: token, body: {'projectId': projectId, 'siteEngineer': siteEngineer});
  Future<Map<String, dynamic>> submitIssue(String token, {required String issueText, List<String> images = const []}) => _request('POST', '/api/submitissue', token: token, body: {'issueText': issueText, 'images': images});
  Future<Map<String, dynamic>> getIssues(String token) => _request('GET', '/api/getissue', token: token);

  Future<Map<String, dynamic>> _reportList(String token, String path, {String? projectId, String? siteEngineer, String? status}) {
    final query = <String, String>{
      if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
      if (siteEngineer != null && siteEngineer.isNotEmpty) 'siteEngineer': siteEngineer,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final suffix = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    return _request('GET', '$path$suffix', token: token);
  }

  Future<Map<String, dynamic>> _request(String method, String path, {required String token, Map<String, dynamic>? body, int expectedStatus = 200}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
    final response = switch (method) {
      'GET' => await _client.get(uri, headers: headers),
      'POST' => await _client.post(uri, headers: headers, body: jsonEncode(body)),
      'PUT' => await _client.put(uri, headers: headers, body: jsonEncode(body)),
      _ => throw ArgumentError.value(method, 'method'),
    };
    final result = _decode(response.body);
    if (response.statusCode != expectedStatus && !(expectedStatus == 200 && response.statusCode >= 200 && response.statusCode < 300)) {
      throw ApiException(result['message']?.toString() ?? 'Request failed (${response.statusCode}).');
    }
    if (result['success'] == false) throw ApiException(result['message']?.toString() ?? 'The request failed.');
    return result;
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is List) return {'data': decoded};
      return decoded as Map<String, dynamic>;
    } on FormatException {
      throw const ApiException('The server returned an invalid response.');
    } on TypeError {
      throw const ApiException('The server returned an unexpected response.');
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
