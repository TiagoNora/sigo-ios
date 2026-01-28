import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants/ticket_constants.dart';
import '../constants/api_constants.dart';
import 'http_client.dart';
import 'connectivity_service.dart';
import 'network_exception.dart';
import 'not_found_exception.dart';
import 'global_error_service.dart';

class ApiService {
  final String accessToken;
  final String baseUrl;
  final Dio _dio;

  /// Creates an ApiService instance.
  ///
  /// If [authService] is provided (AuthService or AuthRepository), the service
  /// will automatically handle 401 errors by clearing the local session and
  /// requiring the user to sign in again.
  ///
  /// Note: Accepts dynamic to support both AuthService (legacy) and AuthRepository (new).
  /// This will be fully migrated to injectable pattern in later phases.
  ApiService(
    this.accessToken, {
    required this.baseUrl,
    dynamic authService,
  }) : _dio = createDioClient(baseUrl: baseUrl, authService: authService) {
    // Set default headers
    _dio.options.headers.addAll({
      'authorization': 'Bearer $accessToken',
      'content-type': 'application/json',
    });

    // Log outgoing requests (headers + body) for debugging purposes.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint(
            'API REQUEST: ${options.method} ${options.uri}\n'
            'Headers: ${options.headers}\n'
            'Body: ${_formatData(options.data)}',
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            'API RESPONSE: ${response.requestOptions.method} '
            '${response.requestOptions.uri} '
            'STATUS: ${response.statusCode}\n'
            'Headers: ${response.headers.map}\n'
            'Body: ${_formatData(response.data)}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint(
            'API ERROR: ${error.requestOptions.method} ${error.requestOptions.uri}\n'
            'Type: ${error.type}\n'
            'Message: ${error.message}\n'
            'Response: ${_formatData(error.response?.data)}',
          );
          handler.next(error);
        },
      ),
    );
  }

  String _formatData(Object? data) {
    if (data == null) return 'null';
    if (data is FormData) {
      final fieldEntries = data.fields.map((e) => '${e.key}=${e.value}').join(', ');
      final fileEntries =
          data.files.map((f) => f.key).toList(growable: false).join(', ');
      return 'FormData(fields: [$fieldEntries], files: [$fileEntries])';
    }
    if (data is Map || data is List) {
      try {
        return json.encode(data);
      } catch (e) {
        // JSON encoding failed, fallback to toString()
        debugPrint('Failed to encode data as JSON: $e');
        return data.toString();
      }
    }
    return data.toString();
  }

  bool _isNetworkError(Object e) {
    if (e is SocketException) return true;
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.error is SocketException;
    }
    return false;
  }

  void _handleNetworkError(Object e) {
    if (_isNetworkError(e)) {
      debugPrint('Network error detected: ${e.runtimeType} -> $e');
      String message = 'Network connection error';
      bool isServiceUnreachable = false;

      if (e is DioException) {
        debugPrint('Dio error details: type=${e.type} message=${e.message}');

        // Check if it's a timeout or DNS/host lookup failure (service not reachable)
        final errorMsg = e.message?.toLowerCase() ?? '';
        final errorStr = e.toString().toLowerCase();

        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            errorMsg.contains('host lookup') ||
            errorMsg.contains('socketexception') ||
            errorStr.contains('host lookup') ||
            errorStr.contains('failed host lookup')) {
          message = 'Service not reachable';
          isServiceUnreachable = true;

          // Broadcast error immediately to show dialog
          GlobalErrorService.instance.notifyError(message);
        } else {
          message = e.message ?? message;
        }
      }

      // Only mark offline for actual connectivity issues, not service unavailability
      if (!isServiceUnreachable) {
        ConnectivityService.instance?.markOffline();
      }

      throw NetworkException(message: message, originalError: e);
    }
  }

  Future<Map<String, dynamic>> searchTickets({
    int pageIndex = 0,
    int pageSize = ApiConstants.defaultPageSize,
    String orderByAttribute = 'id',
    String orderByDirection = 'desc',
    Map<String, dynamic>? query,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'orderBy': [
          {
            'attribute': orderByAttribute,
            'direction': orderByDirection,
          }
        ],
        'paging': {
          'index': pageIndex,
          'size': pageSize,
        }
      };

      // Add query conditions if provided (from saved filter)
      // Wrap the config inside a 'query' object
      if (query != null) {
        debugPrint('Applying saved filter query: ${json.encode(query)}');
        requestBody['query'] = query;
      }

      debugPrint('Search request body: ${json.encode(requestBody)}');

      final response = await _dio.post(
        '/sigo-api/v1/onecare/ttks/search',
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        debugPrint('Search response: ${responseData['results']?.length ?? 0} tickets found');
        return responseData;
      } else {
        debugPrint('Search tickets failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error searching tickets: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTicketById(String ticketId) async {
    try {
      final response = await _dio.get('/sigo-api/v1/onecare/ttks/$ticketId');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw NotFoundException(
          message: 'Ticket not found',
          resourceType: 'Ticket',
          resourceId: ticketId,
        );
      } else {
        debugPrint('Get ticket failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to load ticket: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error getting ticket: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createTicket(
    Map<String, dynamic> ticketData, {
    List<PlatformFile>? files,
  }) async {
    try {
      // If files are provided, use multipart/form-data
      if (files != null && files.isNotEmpty) {
        final formData = FormData();
        formData.fields.add(MapEntry('ttk', json.encode(ticketData)));

        for (final file in files) {
          if (file.path != null) {
            formData.files.add(
              MapEntry(
                'file',
                await MultipartFile.fromFile(
                  file.path!,
                  filename: file.name,
                ),
              ),
            );
          } else if (file.bytes != null) {
            formData.files.add(
              MapEntry(
                'file',
                MultipartFile.fromBytes(
                  file.bytes!,
                  filename: file.name,
                ),
              ),
            );
          }
        }

        debugPrint('Sending multipart request with ${files.length} file(s)');

        final response = await _dio.post(
          '/sigo-api/v1/onecare/ttks',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return response.data as Map<String, dynamic>;
        } else {
          debugPrint('Create ticket failed: ${response.statusCode} - ${response.data}');
          throw Exception('Failed to create ticket: ${response.statusCode}');
        }
      } else {
        final response = await _dio.post(
          '/sigo-api/v1/onecare/ttks',
          data: ticketData,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return response.data as Map<String, dynamic>;
        } else {
          debugPrint('Create ticket failed: ${response.statusCode} - ${response.data}');
          throw Exception('Failed to create ticket: ${response.statusCode}');
        }
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error creating ticket: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateTicket(String ticketId, Map<String, dynamic> ticketData) async {
    try {
      final response = await _dio.put(
        '/sigo-api/v1/onecare/$ticketId',
        data: ticketData,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Update ticket failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to update ticket: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error updating ticket: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> cancelTicket(String ticketId, String comment) async {
    try {
      final response = await _dio.patch(
        '/sigo-api/v1/onecare/ttks/$ticketId',
        data: {
          'status': TicketStatusStrings.cancelled,
          'comment': comment,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Cancel ticket failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to cancel ticket: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error cancelling ticket: $e');
      rethrow;
    }
  }

  Future<void> deleteTicket(String ticketId) async {
    try {
      final response = await _dio.delete('/sigo-api/v1/onecare/$ticketId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        debugPrint('Delete ticket failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to delete ticket: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error deleting ticket: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reopenTicket(String ticketId, String comment) async {
    try {
      final response = await _dio.patch(
        '/sigo-api/v1/onecare/ttks/$ticketId',
        data: {
          'status': TicketStatusStrings.inProgress,
          'comment': comment,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Reopen ticket failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to reopen ticket: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error reopening ticket: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> validateTicket(String ticketId, {String? comment}) async {
    try {
      final payload = <String, dynamic>{
        'status': TicketStatusStrings.closed,
      };
      if (comment != null && comment.trim().isNotEmpty) {
        payload['comment'] = comment;
      }

      final response = await _dio.patch(
        '/sigo-api/v1/onecare/ttks/$ticketId',
        data: payload,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Validate ticket failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to validate ticket: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error validating ticket: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getNotes(String ticketId) async {
    try {
      final response = await _dio.get('/sigo-api/v1/onecare/ttks/$ticketId/notes');

      if (response.statusCode == 200) {
        return response.data as List;
      } else {
        debugPrint('Get notes failed: ${response.statusCode} - ${response.data}');
        return [];
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error getting notes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createNote(String ticketId, String content) async {
    try {
      final response = await _dio.post(
        '/sigo-api/v1/onecare/ttks/$ticketId/notes',
        data: {
          'content': content,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Create note failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to create note: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error creating note: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateNote(String ticketId, int noteId, String content) async {
    try {
      final response = await _dio.put(
        '/sigo-api/v1/onecare/ttks/$ticketId/notes',
        data: {
          'id': noteId,
          'content': content,
          'visibleToTeam': null,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Update note failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to update note: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error updating note: $e');
      rethrow;
    }
  }

  Future<List<int>> downloadAttachment(String ticketId, String fileName) async {
    try {
      final encodedFileName = Uri.encodeComponent(fileName);
      final response = await _dio.get<List<int>>(
        '/sigo-api/v1/onecare/ttks/$ticketId/attachments/$encodedFileName',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      } else {
        debugPrint('Download attachment failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to download attachment: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error downloading attachment: $e');
      rethrow;
    }
  }

  Future<void> deleteAttachment(String ticketId, String fileName) async {
    try {
      final encodedFileName = Uri.encodeComponent(fileName);
      final response = await _dio.delete(
        '/sigo-api/v1/onecare/ttks/$ticketId/attachments/$encodedFileName',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        debugPrint('Delete attachment failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to delete attachment: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error deleting attachment: $e');
      rethrow;
    }
  }

  Future<dynamic> uploadAttachment(
    String ticketId,
    String filePath,
    String fileName,
    String mimeType,
  ) async {
    try {
      final attachmentMetadata = json.encode({
        'attachments': [
          {
            'name': fileName,
            'description': fileName,
            'attachmentType': mimeType,
            'visibleToTeam': null,
          }
        ]
      });

      final formData = FormData.fromMap({
        'ttk': attachmentMetadata,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(
        '/sigo-api/v1/onecare/ttks/$ticketId/attachments',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        debugPrint('Upload attachment failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to upload attachment: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error uploading attachment: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getLogs(String ticketId) async {
    try {
      final response = await _dio.get('/sigo-api/v1/onecare/ttks/$ticketId/logs');

      if (response.statusCode == 200) {
        return response.data as List;
      } else {
        debugPrint('Get logs failed: ${response.statusCode} - ${response.data}');
        return [];
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error getting logs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getImpacts() async {
    try {
      final response = await _dio.get('/sigo-api/v1/catalogs/impacts?all=true');

      if (response.statusCode == 200) {
        final List<dynamic> impacts = response.data;
        final result = impacts.map((impact) => impact as Map<String, dynamic>).toList();

        // Sort by level from low to high
        result.sort((a, b) => (a['level'] ?? 0).compareTo(b['level'] ?? 0));

        return result;
      } else {
        debugPrint('Get impacts failed: ${response.statusCode} - ${response.data}');
        return [];
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error getting impacts: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSeverities() async {
    try {
      final response = await _dio.get('/sigo-api/v1/catalogs/severities?all=true');

      if (response.statusCode == 200) {
        final List<dynamic> severities = response.data;
        final result = severities.map((severity) => severity as Map<String, dynamic>).toList();

        // Sort by level from low to high
        result.sort((a, b) => (a['level'] ?? 0).compareTo(b['level'] ?? 0));

        return result;
      } else {
        debugPrint('Get severities failed: ${response.statusCode} - ${response.data}');
        return [];
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error getting severities: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateTicketField(String ticketId, Map<String, dynamic> fieldData) async {
    try {
      final response = await _dio.patch(
        '/sigo-api/v1/onecare/ttks/$ticketId',
        data: fieldData,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Update ticket field failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to update ticket field: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error updating ticket field: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getUserTeams() async {
    try {
      final response = await _dio.get('/sigo-api/v1/onecare/user/teams');

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        debugPrint('Get user teams failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to load user teams: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error getting user teams: $e');
      rethrow;
    }
  }

  Future<void> updateDefaultTeam(String teamName) async {
    try {
      final encodedTeam = Uri.encodeComponent(teamName);
      final response = await _dio.post('/sigo-api/v1/onecare/user/defaultTeam/$encodedTeam');

      if (response.statusCode != 200) {
        debugPrint('Update default team failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to update default team: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error updating default team: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> searchCIS({
    required bool isEquipment,
    required String provider,
    String searchQuery = '',
    int pageIndex = 0,
    int pageSize = 15,
    List<String>? ciTypes,
    List<String>? serviceTypes,
  }) async {
    try {
      Map<String, dynamic> requestBody;

      if (isEquipment) {
        // Equipment search - use provided ciTypes or fallback to defaults
        final equipmentTypes = ciTypes ?? [
          'BPO',
          'Nossis One',
          'Peripheral Devices',
          'ME.HOP',
          'ME.OLT',
          'ME.GFADO',
          'ME.ODF',
          'ME.PDPEQ',
          'LO.CENTRAL',
          'ME.CPE.ONT'
        ];

        requestBody = {
          'paging': {
            'index': pageIndex,
            'size': pageSize,
          },
          'query': {
            'name': 'Search WO',
            'operator': 'AND',
            'conditions': [
              {
                'attribute': 'name',
                'value': searchQuery,
                'operator': 'containsIgnoreCase',
              },
              {
                'attribute': 'type',
                'value': equipmentTypes,
                'operator': 'in',
              },
              {
                'attribute': 'provider',
                'value': provider,
                'operator': 'equals',
              },
            ],
          }
        };
      } else {
        // Service search - use provided serviceTypes or fallback to defaults
        final types = serviceTypes ?? [
          'NE3ANE3B.FILE.IMPORT',
          'SD_IT_SERVICE',
          'Ticketing',
          'BSS',
          'FTTH.BSA',
          'CFS.FTTH.BSA',
          'Tipo de Seviço do Onecare',
          'OSS',
          'NEW_TEST',
          'RFS.CPE',
          'Peripheral Devices',
          'Email.TTK',
          'OIT',
          'WHOLESALE',
          'BPO Service'
        ];

        requestBody = {
          'paging': {
            'index': pageIndex,
            'size': pageSize,
          },
          'query': {
            'name': 'Search WO',
            'operator': 'AND',
            'conditions': [
              {
                'attribute': 'name',
                'value': searchQuery,
                'operator': 'containsIgnoreCase',
              },
              {
                'attribute': 'serviceType',
                'value': types,
                'operator': 'in',
              },
              {
                'attribute': 'provider',
                'value': provider,
                'operator': 'equals',
              },
              {
                'attribute': 'type',
                'value': 'Service',
                'operator': 'equals',
              }
            ],
          }
        };
      }

      debugPrint('CIS Search Request Body: ${json.encode(requestBody)}');

      final response = await _dio.post(
        '/sigo-api/v1/onecare/cis/search',
        data: requestBody,
      );

      debugPrint('CIS Search Response Status: ${response.statusCode}');
      debugPrint('CIS Search Response Body: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Search CIS failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to search CIS: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error searching CIS: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final response = await _dio.get('/sigo-api/v1/user/info');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Get user info failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to get user info: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error getting user info: $e');
      rethrow;
    }
  }

  // Get all saved filters
  Future<List<dynamic>> getSavedFilters() async {
    try {
      final response = await _dio.get('/sigo-api/v1/user/configs/workbenches?type=ONECARE_FILTER');

      if (response.statusCode == 200) {
        return response.data as List;
      } else {
        debugPrint('Get saved filters failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to get saved filters: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error getting saved filters: $e');
      rethrow;
    }
  }

  // Create a new filter
  Future<Map<String, dynamic>> createFilter(Map<String, dynamic> filterData) async {
    try {
      final response = await _dio.post(
        '/sigo-api/v1/user/configs/workbenches',
        data: filterData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Create filter failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to create filter: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error creating filter: $e');
      rethrow;
    }
  }

  // Update an existing filter
  Future<Map<String, dynamic>> updateFilter(Map<String, dynamic> filterData) async {
    try {
      final response = await _dio.put(
        '/sigo-api/v1/user/configs/workbenches',
        data: filterData,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Update filter failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to update filter: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error updating filter: $e');
      rethrow;
    }
  }

  // Delete a filter
  Future<void> deleteFilter(int filterId) async {
    try {
      final response = await _dio.delete('/sigo-api/v1/user/configs/workbenches/$filterId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        debugPrint('Delete filter failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to delete filter: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error deleting filter: $e');
      rethrow;
    }
  }

  // Get workbench by ID (for views and filters)
  Future<Map<String, dynamic>> getWorkbenchById(int workbenchId) async {
    try {
      final response = await _dio.get('/sigo-api/v1/user/configs/workbenches/$workbenchId');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Get workbench failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to get workbench: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error getting workbench: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getPriorities() async {
    try {
      final response = await _dio.get('/sigo-api/v1/catalogs/priorities');

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        debugPrint('Get priorities failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to get priorities: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error getting priorities: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _dio.get('/sigo-api/v1/catalogs/categories?all=true');

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        debugPrint('Get categories failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to get categories: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error getting categories: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getSubcategories() async {
    try {
      final response = await _dio.get('/sigo-api/v1/catalogs/subcategories?all=true');

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        debugPrint('Get subcategories failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to get subcategories: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error getting subcategories: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getSeveritiesFromCatalog() async {
    try {
      final response = await _dio.get('/sigo-api/v1/catalogs/severities');

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        debugPrint('Get severities failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to get severities: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error getting severities: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> evaluateTicket(Map<String, dynamic> ticketData) async {
    try {
      final response = await _dio.post(
        '/sigo-api/v1/onecare/ttks/evaluate',
        data: ticketData,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('Evaluate ticket failed: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to evaluate ticket: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error evaluating ticket: $e');
      rethrow;
    }
  }

  Future<void> registerDeviceToken({
    required String userId,
    required String deviceToken,
  }) async {
    try {
      final response = await _dio.post(
        '/sigo-api/api/tokens/register',
        data: {
          'userId': userId,
          'deviceToken': deviceToken,
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Register device token failed: ${response.statusCode} - ${response.data}',
        );
        throw Exception('Failed to register device token: ${response.statusCode}');
      }
      debugPrint('Device token registered for user: $userId');
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error registering device token: $e');
      rethrow;
    }
  }

  Future<void> unregisterDeviceToken(String deviceToken) async {
    try {
      final encodedToken = Uri.encodeComponent(deviceToken);
      final response = await _dio.delete('/sigo-api/api/tokens/unregister?token=$encodedToken');

      if (response.statusCode != 200 && response.statusCode != 204) {
        debugPrint(
          'Unregister device token failed: ${response.statusCode} - ${response.data}',
        );
        throw Exception('Failed to unregister device token: ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error unregistering device token: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendNotificationToUser({
    required String userId,
    required String title,
    String? body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post(
        '/sigo-api/api/notifications/send-to-user',
        data: {
          'userId': userId,
          'title': title,
          'body': body,
          'data': data ?? const <String, dynamic>{},
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      debugPrint(
        'Send notification to user failed: ${response.statusCode} - ${response.data}',
      );
      throw Exception('Failed to send notification: ${response.statusCode}');
    } catch (e) {
      _handleNetworkError(e);
      debugPrint('Error sending notification: $e');
      rethrow;
    }
  }
}
