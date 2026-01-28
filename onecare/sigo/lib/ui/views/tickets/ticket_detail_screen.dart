import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/ticket.dart';
import '../../../models/ticket_extensions.dart';
import '../../../core/di/injection.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/priority_repository.dart';
import '../../../domain/repositories/catalog_repository.dart';
import '../../../domain/repositories/impact_severity_repository.dart';
import '../../../services/api_service.dart';
import '../../../blocs/locale_cubit.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/network_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/beautiful_snackbar.dart';
import '../../widgets/tickets/status_chip.dart';
import 'widgets/ticket_info_rows.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  static const double _labelWidth = 150;
  static const double _labelGap = 12;

  Ticket? _ticket;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _logs = [];
  bool _isLoadingLogs = false;
  bool _isLogsExpanded = false;
  bool _isFilesExpanded = false;
  bool _isNotesExpanded = false;
  String? _lastLocaleCode;
  bool _offlineError = false;
  StreamSubscription<Locale>? _localeSubscription;
  List<dynamic>? _cachedImpacts;
  List<dynamic>? _cachedSeverities;
  bool _isEvaluating = false;
  bool _canEditImpactUrgency = true;

  // Cache ApiService instance to avoid recreating it on every API call
  ApiService? _cachedApiService;
  ApiService get _apiService {
    final authRepository = getIt<AuthRepository>();
    if (_cachedApiService == null) {
      _cachedApiService = ApiService(
        authRepository.accessToken!,
        baseUrl: authRepository.tenantConfig?.baseUrl ?? "",
        authService: authRepository,
      );
    }
    return _cachedApiService!;
  }

  @override
  void initState() {
    super.initState();
    _lastLocaleCode = context.read<LocaleCubit>().state.languageCode;
    _localeSubscription = context.read<LocaleCubit>().stream.listen((locale) {
      final localeCode = locale.languageCode;
      if (_lastLocaleCode != localeCode) {
        _lastLocaleCode = localeCode;
        _handleLocaleChange();
      }
    });
    _loadTicketDetails();
    _loadAuxiliaryData();
  }

  @override
  void dispose() {
    _localeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAuxiliaryData() async {
    final priorityService = getIt<PriorityRepository>();
    final catalogService = getIt<CatalogRepository>();
    final impactSeverityService = getIt<ImpactSeverityRepository>();

    await Future.wait([
      priorityService.loadPriorities(),
      catalogService.loadCatalogs(),
      impactSeverityService.loadImpactsAndSeverities(),
    ]);

    if (mounted) setState(() {});
  }

  Future<void> _loadTicketDetails({bool forceRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _offlineError = false;
    });

    try {
      final connectivity = context.read<ConnectivityService>();
      if (!connectivity.isOnline) {
        if (!mounted) return;
        setState(() {
          _error = AppLocalizations.of(context).noInternet;
          _isLoading = false;
        });
        return;
      }

      // Always fetch fresh data from API to ensure notes and attachments are included
      final apiService = _apiService;

      final ticketJson = await apiService.getTicketById(widget.ticketId);
      final ticket = Ticket.fromJson(ticketJson);

      if (!mounted) return;

      // Single setState with all updates
      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });

      // Load evaluate and logs without blocking the main UI
      unawaited(_prefetchEvaluate(ticketJson));
      unawaited(_loadLogs());
    } on NetworkException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _offlineError = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load ticket details: $e';
        _isLoading = false;
      });
    }
  }

  List<dynamic> _filterAndSortByLevel(List<dynamic> items) {
    final filtered = items.where((item) {
      final apiOnly = item['apiOnly'] ?? false;
      return !apiOnly;
    }).toList();
    filtered.sort((a, b) => (a['level'] ?? 0).compareTo(b['level'] ?? 0));
    return filtered;
  }

  bool _isEvaluateBadRequest(Object e) {
    if (e is DioException && e.response?.statusCode == 400) {
      return true;
    }
    return e
        .toString()
        .contains('Failed to evaluate ticket: 400');
  }

  String _cancelTicketErrorMessage(AppLocalizations l10n, Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final code = data['code'];
        if (code == 'SIGO_INVALID_STATUS_CHANGE') {
          return l10n.cancelTicketBlockedByOpenActivities;
        }
        final description = data['description'];
        if (description is String && description.trim().isNotEmpty) {
          return description;
        }
      } else if (data is String && data.trim().isNotEmpty) {
        return data;
      }
    }
    return e.toString();
  }

  Future<void> _prefetchEvaluate(Map<String, dynamic> ticketData) async {
    if (!mounted || _isEvaluating) return;
    if (_cachedImpacts != null && _cachedSeverities != null) return;

    _isEvaluating = true;

    try {
      final apiService = _apiService;
      final evaluateResult = await apiService.evaluateTicket(ticketData);
      final impacts = evaluateResult['impacts'] as List<dynamic>? ?? [];
      final severities = evaluateResult['severities'] as List<dynamic>? ?? [];

      if (!mounted) return;

      // These will be set during the parent's setState
      _cachedImpacts = _filterAndSortByLevel(impacts);
      _cachedSeverities = _filterAndSortByLevel(severities);
      _canEditImpactUrgency = true;
    } catch (e) {
      if (_isEvaluateBadRequest(e)) {
        _canEditImpactUrgency = false;
        return;
      }
      debugPrint('Error prefetching evaluate data: $e');
    } finally {
      _isEvaluating = false;
    }
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLogs = true;
    });

    try {
      final connectivity = context.read<ConnectivityService>();
      if (!connectivity.isOnline) {
        _isLoadingLogs = false;
        return;
      }

      final apiService = _apiService;
      final logs = await apiService.getLogs(widget.ticketId);

      if (!mounted) return;

      setState(() {
        _logs = logs;
        _isLoadingLogs = false;
      });
    } on NetworkException {
      if (!mounted) return;
      setState(() {
        _isLoadingLogs = false;
      });
      _offlineError = true;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLogs = false;
      });
    }
  }

  Future<void> _addNote() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addNote),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            maxLines: 5,
            autofocus: true,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.enterNoteContent,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      try {
        final apiService = _apiService;
        await apiService.createNote(widget.ticketId, controller.text);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          );
          BeautifulSnackbar.success(context, l10n.noteAddedSuccessfully);
          // Reload ticket details to get updated notes
          _loadTicketDetails(forceRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          BeautifulSnackbar.error(context, '${l10n.failedToAddNote}: $e');
        }
      }
    }
  }

  Future<void> _showCancelTicketDialog() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.cancelTicket),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.cancelTicketJustification,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.enterJustification,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.cancelTicket),
            ),
          ],
        ),
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      try {
        final apiService = _apiService;

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          );
          BeautifulSnackbar.info(context, l10n.cancellingTicket);
        }

        await apiService.cancelTicket(widget.ticketId, controller.text);

        if (mounted) {
          BeautifulSnackbar.success(context, l10n.ticketCancelledSuccessfully);
          // Reload ticket details to show updated status
          _loadTicketDetails(forceRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          final message = _cancelTicketErrorMessage(l10n, e);
          BeautifulSnackbar.error(context, '${l10n.failedToCancelTicket}: $message');
        }
      }
    }
  }

  Future<void> _showReopenTicketDialog() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.reopenTicket),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reopenTicketJustification,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.enterJustification,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.reopenTicket),
            ),
          ],
        ),
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      try {
        final apiService = _apiService;

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          );
          BeautifulSnackbar.info(context, l10n.reopeningTicket);
        }

        final updatedTicket = await apiService.reopenTicket(
          widget.ticketId,
          controller.text,
        );

        if (mounted) {
          setState(() {
            _ticket = Ticket.fromJson(updatedTicket);
          });
          BeautifulSnackbar.success(context, l10n.ticketReopenedSuccessfully);
          _loadTicketDetails(forceRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          BeautifulSnackbar.error(context, '${l10n.failedToReopenTicket}: $e');
        }
      }
    } else if (result == true && controller.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        );
        BeautifulSnackbar.warning(context, l10n.justificationRequired);
      }
    }
  }

  Future<void> _showValidateTicketDialog() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.validateTicket),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.validateTicketJustification,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 5,
                autofocus: true,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l10n.enterJustification,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.validateTicket),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final apiService = _apiService;

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          );
          BeautifulSnackbar.info(context, l10n.validatingTicket);
        }

        final updatedTicket = await apiService.validateTicket(
          widget.ticketId,
          comment: controller.text,
        );

        if (mounted) {
          setState(() {
            _ticket = Ticket.fromJson(updatedTicket);
          });
          BeautifulSnackbar.success(context, l10n.ticketValidatedSuccessfully);
          _loadTicketDetails(forceRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          BeautifulSnackbar.error(context, '${l10n.failedToValidateTicket}: $e');
        }
      }
    }
  }

  void _copyTicketId() {
    final l10n = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(text: widget.ticketId));
    ScaffoldMessenger.of(
      context,
    );
    BeautifulSnackbar.success(context, l10n.ticketIdCopied);
  }

  void _copyTicketUrl() {
    final l10n = AppLocalizations.of(context);
    final url =
        'https://sigo-onecare.10.113.140.101.nip.io/nossis/portal/sigoonecare/oc/view/${widget.ticketId}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(
      context,
    );
    BeautifulSnackbar.success(context, l10n.ticketUrlCopied);
  }

  Future<void> _editImpact() async {
    final l10n = AppLocalizations.of(context);
    final localeCode = context.read<LocaleCubit>().state.languageCode;
    final impactSeverityService = getIt<ImpactSeverityRepository>();

    try {
      if (!_canEditImpactUrgency) {
        if (mounted) {
          BeautifulSnackbar.warning(
            context,
            l10n.cannotEditImpactAndUrgency,
          );
        }
        return;
      }
      final filteredImpacts =
          _cachedImpacts ??
          await () async {
            try {
              final apiService = _apiService;
              final ticketData = await apiService.getTicketById(widget.ticketId);
              final evaluateResult = await apiService.evaluateTicket(ticketData);
              final impacts =
                  evaluateResult['impacts'] as List<dynamic>? ?? [];
              final filtered = _filterAndSortByLevel(impacts);
              if (mounted) {
                setState(() {
                  _cachedImpacts = filtered;
                  _canEditImpactUrgency = true;
                });
              }
              return filtered;
            } catch (e) {
              if (mounted && _isEvaluateBadRequest(e)) {
                setState(() {
                  _canEditImpactUrgency = false;
                });
              }
              rethrow;
            }
          }();

      if (filteredImpacts.isEmpty) {
        if (mounted) {
          BeautifulSnackbar.warning(context, l10n.noImpactOptionsAvailable);
        }
        return;
      }

      if (!mounted) return;

      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.selectImpact),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredImpacts.length,
              itemBuilder: (context, index) {
                final impact = filteredImpacts[index];
                final name = impact['name'] ?? '';
                final translations =
                    impact['translations'] as Map<String, dynamic>? ?? {};
                final translation = translations[localeCode] as String?;
                final displayText = (translation == null || translation.isEmpty)
                    ? name
                    : translation;
                final color = impactSeverityService.parseColor(impact['color']);
                final isSelected = name == _ticket?.impact;

                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.3),
                      border: Border.all(color: color),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  title: Text(
                    displayText,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? color : null,
                    ),
                  ),
                  trailing: isSelected ? Icon(Icons.check, color: color) : null,
                  onTap: () => Navigator.pop(context, impact),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );

      if (selected != null) {
        final apiService = _apiService;
        await apiService.updateTicketField(widget.ticketId, {
          'impact': selected['name'],
        });

        if (mounted) {
          BeautifulSnackbar.success(context, l10n.impactUpdatedSuccessfully);
          setState(() {
            _isLoading = true;
          });
          _loadTicketDetails(forceRefresh: true);
        }
      }
    } catch (e) {
      if (mounted && _isEvaluateBadRequest(e)) {
        BeautifulSnackbar.warning(
          context,
          l10n.cannotEditImpactAndUrgency,
        );
        return;
      }
      if (mounted) {
        BeautifulSnackbar.error(context, '${l10n.failedToUpdateImpact}: $e');
      }
    }
  }

  Future<void> _editUrgency() async {
    final l10n = AppLocalizations.of(context);
    final localeCode = context.read<LocaleCubit>().state.languageCode;
    final impactSeverityService = getIt<ImpactSeverityRepository>();

    try {
      if (!_canEditImpactUrgency) {
        if (mounted) {
          BeautifulSnackbar.warning(
            context,
            l10n.cannotEditImpactAndUrgency,
          );
        }
        return;
      }
      final filteredSeverities =
          _cachedSeverities ??
          await () async {
            try {
              final apiService = _apiService;
              final ticketData = await apiService.getTicketById(widget.ticketId);
              final evaluateResult = await apiService.evaluateTicket(ticketData);
              final severities =
                  evaluateResult['severities'] as List<dynamic>? ?? [];
              final filtered = _filterAndSortByLevel(severities);
              if (mounted) {
                setState(() {
                  _cachedSeverities = filtered;
                  _canEditImpactUrgency = true;
                });
              }
              return filtered;
            } catch (e) {
              if (mounted && _isEvaluateBadRequest(e)) {
                setState(() {
                  _canEditImpactUrgency = false;
                });
              }
              rethrow;
            }
          }();

      if (filteredSeverities.isEmpty) {
        if (mounted) {
          BeautifulSnackbar.warning(context, l10n.noUrgencyOptionsAvailable);
        }
        return;
      }

      if (!mounted) return;

      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.selectUrgency),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredSeverities.length,
              itemBuilder: (context, index) {
                final severity = filteredSeverities[index];
                final name = severity['name'] ?? '';
                final translations =
                    severity['translations'] as Map<String, dynamic>? ?? {};
                final translation = translations[localeCode] as String?;
                final displayText = (translation == null || translation.isEmpty)
                    ? name
                    : translation;
                final color = impactSeverityService.parseColor(
                  severity['color'],
                );
                final isSelected = name == _ticket?.severity;

                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.3),
                      border: Border.all(color: color),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  title: Text(
                    displayText,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? color : null,
                    ),
                  ),
                  trailing: isSelected ? Icon(Icons.check, color: color) : null,
                  onTap: () => Navigator.pop(context, severity),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );

      if (selected != null) {
        final apiService = _apiService;
        await apiService.updateTicketField(widget.ticketId, {
          'severity': selected['name'],
        });

        if (mounted) {
          BeautifulSnackbar.success(context, l10n.urgencyUpdatedSuccessfully);
          setState(() {
            _isLoading = true;
          });
          _loadTicketDetails(forceRefresh: true);
        }
      }
    } catch (e) {
      if (mounted && _isEvaluateBadRequest(e)) {
        BeautifulSnackbar.warning(
          context,
          l10n.cannotEditImpactAndUrgency,
        );
        return;
      }
      if (mounted) {
        BeautifulSnackbar.error(context, '${l10n.failedToUpdateUrgency}: $e');
      }
    }
  }

  Future<void> _handleLocaleChange() async {
    // Reload details so translated fields reflect the new locale
    await _loadTicketDetails();
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.read<ConnectivityService>();

    return StreamBuilder<ConnectionStateStatus>(
      stream: connectivity.statusStream,
      initialData: connectivity.status,
        builder: (context, snapshot) {
          final l10n = AppLocalizations.of(context);
          final status = snapshot.data ?? connectivity.status;
          final canCancelTicket =
              _ticket != null &&
              (_ticket!.status == TicketStatus.inProgress ||
                  _ticket!.status == TicketStatus.acknowledged ||
                  _ticket!.status == TicketStatus.held ||
                  _ticket!.status == TicketStatus.pending);
          final canReopenTicket =
              _ticket != null && _ticket!.status == TicketStatus.resolved;
          final canValidateTicket =
              _ticket != null && _ticket!.status == TicketStatus.resolved;

        if (status == ConnectionStateStatus.checking) {
          return Scaffold(
            body: _buildTicketSkeleton(),
          );
        }

        if (status != ConnectionStateStatus.online || _offlineError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noInternet,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.checkConnectionAndRetry,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await connectivity.recheck();
                          if (connectivity.isOnline) {
                            _loadTicketDetails(forceRefresh: true);
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              l10n.ticketDetails,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF37414A),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'cancel') {
                      if (canCancelTicket) {
                        _showCancelTicketDialog();
                      }
                    } else if (value == 'reopen') {
                      if (canReopenTicket) {
                        _showReopenTicketDialog();
                      }
                    } else if (value == 'validate') {
                      if (canValidateTicket) {
                        _showValidateTicketDialog();
                      }
                    } else if (value == 'copy_id') {
                      _copyTicketId();
                    } else if (value == 'copy_url') {
                      _copyTicketUrl();
                    }
                },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'copy_id',
                      child: Row(
                        children: [
                          const Icon(Icons.copy, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(l10n.copyId),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy_url',
                      child: Row(
                        children: [
                          const Icon(Icons.link, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(l10n.copyUrl),
                        ],
                      ),
                    ),
                    if (canReopenTicket)
                      PopupMenuItem(
                        value: 'reopen',
                        child: Row(
                          children: [
                            const Icon(Icons.restart_alt, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(l10n.reopenTicket),
                          ],
                        ),
                      ),
                    if (canValidateTicket)
                      PopupMenuItem(
                        value: 'validate',
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(l10n.validateTicket),
                          ],
                        ),
                      ),
                    if (canCancelTicket)
                      PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            const Icon(Icons.cancel, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(l10n.cancelTicket),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          body: _isLoading
              ? _buildTicketSkeleton()
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTicketDetails,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : _ticket == null
              ? Center(child: Text(l10n.ticketNotFound))
              : RefreshIndicator(
                  onRefresh: _loadTicketDetails,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ticket ID and Status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _ticket!.id,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            StatusChip(status: _ticket!.status),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Type and reporting info
                        Row(
                          children: [
                            Icon(
                              _getTypeIcon(_ticket!.type),
                              size: 22,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _ticket!.type.getLocalizedType(l10n),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${l10n.createdBy}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_ticket!.assignedTo ?? l10n.na} / ${_ticket!.requesterName}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.home,
                              size: 16,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _ticket!.tenant ?? l10n.na,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        if (_ticket!.externalId != null &&
                            _ticket!.externalId!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.local_offer,
                                size: 16,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _ticket!.externalId!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Global Information (Equipment)
                        _buildSectionTitle(l10n.globalInformation),
                        const SizedBox(height: 12),
                        _buildGlobalInformationSection(l10n),
                        const SizedBox(height: 24),

                        // Dates
                        _buildSectionTitle(l10n.dates),
                        const SizedBox(height: 12),
                        _buildDatesSection(l10n),
                        const SizedBox(height: 24),

                        // Other Information
                        _buildSectionTitle(l10n.otherInformation),
                        const SizedBox(height: 12),
                        _buildOtherInformationSection(l10n),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildGlobalInformationSection(AppLocalizations l10n) {
    final hasEquipment = _ticket!.cis != null && _ticket!.cis!.isNotEmpty;
    final hasService =
        _ticket!.services != null && _ticket!.services!.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildScopeRow(l10n),
            // Show Affected Item type and details based on what's available
            if (hasEquipment) ...[
              _buildAffectedItemRow(l10n.equipment, FontAwesomeIcons.server),
              InfoRow(label: l10n.equipment, value: _getEquipmentName(l10n)),
              InfoRow(label: l10n.equipmentType, value: _ticket!.ciType ?? l10n.na),
            ] else if (hasService) ...[
              _buildAffectedItemRow(
                l10n.service,
                FontAwesomeIcons.fileCircleMinus,
              ),
              InfoRow(label: l10n.service, value: _getServiceName(l10n)),
              InfoRow(label: l10n.serviceType, value: _getServiceType(l10n)),
            ],
            _buildCatalogRow(
              l10n.category,
              _ticket!.category,
              isCategoryType: true,
            ),
            if (_ticket!.subcategory != null)
              _buildCatalogRow(
                l10n.subcategory,
                _ticket!.subcategory!,
                isCategoryType: false,
              ),
            // Impact and Urgency editable for ACKNOWLEDGED, PENDING, IN_PROGRESS
    ([
                  TicketStatus.acknowledged,
                  TicketStatus.pending,
                  TicketStatus.inProgress,
                ].contains(_ticket!.status) && _canEditImpactUrgency)
                ? _buildEditableImpactSeverityRow(
                    l10n.impact,
                    _ticket!.impact,
                    _editImpact,
                    isImpact: true,
                  )
                : _buildImpactSeverityRow(
                    l10n.impact,
                    _ticket!.impact,
                    isImpact: true,
                  ),
    ([
                  TicketStatus.acknowledged,
                  TicketStatus.pending,
                  TicketStatus.inProgress,
                ].contains(_ticket!.status) && _canEditImpactUrgency)
                ? _buildEditableImpactSeverityRow(
                    l10n.urgency,
                    _ticket!.severity ?? '',
                    _editUrgency,
                    isImpact: false,
                  )
                : (_ticket!.severity != null
                      ? _buildImpactSeverityRow(
                          l10n.urgency,
                          _ticket!.severity!,
                          isImpact: false,
                        )
                      : InfoRow(label: l10n.urgency, value: l10n.na)),
            InfoRow(label: l10n.title, value: _ticket!.title),
            InfoRow(label: l10n.description, value: _ticket!.description),
          ],
        ),
      ),
    );
  }

  Widget _buildAffectedItemRow(String value, IconData icon) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              l10n.affectedItem,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: _labelGap),
          Expanded(
            child: Row(
              children: [
                FaIcon(icon, size: 18),
                const SizedBox(width: 6),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeRow(AppLocalizations l10n) {
    final scope = _ticket!.scope ?? l10n.na;
    final scopeLower = scope.toLowerCase();

    Icon? scopeIcon;
    if (scopeLower.contains('personal')) {
      scopeIcon = const Icon(Icons.person, size: 18);
    } else if (scopeLower.contains('team')) {
      scopeIcon = const Icon(Icons.people, size: 18);
    }

    String localizedScope = scope;
    if (scopeLower.contains('personal') || scopeLower.contains('individual')) {
      localizedScope = l10n.scopeIndividual;
    } else if (scopeLower.contains('team')) {
      localizedScope = l10n.scopeTeam;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              l10n.scope,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: _labelGap),
          Expanded(
            child: Row(
              children: [
                if (scopeIcon != null) ...[scopeIcon, const SizedBox(width: 6)],
                Expanded(
                  child: Text(
                    localizedScope,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SLA Progress
            if (_ticket!.slaInMinutes != null) _buildSLAProgress(l10n),
            if (_ticket!.slaInMinutes != null) const SizedBox(height: 16),

            // Priority
            _buildPriorityRow(l10n.priority, _ticket!.priority),

            // Dates
            DateRow(label: l10n.reportedDate, date: _ticket!.createdAt),
            DateRow(label: l10n.modifiedDate, date: _ticket!.updatedAt),
            DateRow(label: l10n.limitDate, date: _ticket!.expectedResolutionDate),
            DateRow(label: l10n.resolvedDate, date: _ticket!.resolvedAt),
            DateRow(label: l10n.closedDate, date: _ticket!.closedDate),
          ],
        ),
      ),
    );
  }

  Widget _buildSLAProgress(AppLocalizations l10n) {
    final slaMinutes = _ticket!.slaInMinutes!;
    final consumedMinutes = _ticket!.slaConsumedInMinutes ?? 0;
    final progress = consumedMinutes / slaMinutes; // Don't clamp - can be > 1.0
    final remainingMinutes = slaMinutes - consumedMinutes;
    final isOverdue = remainingMinutes < 0;

    // Calculate days, hours, minutes (use absolute value if overdue)
    final absRemainingMinutes = remainingMinutes.abs();
    final days = absRemainingMinutes ~/ (24 * 60);
    final hours = (absRemainingMinutes % (24 * 60)) ~/ 60;
    final minutes = absRemainingMinutes % 60;

    Color progressColor;
    if (progress >= 1.0) {
      progressColor = Colors.red;
    } else if (progress >= 0.8) {
      progressColor = Colors.orange;
    } else if (progress >= 0.5) {
      progressColor = Colors.amber;
    } else {
      progressColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.slaProgress,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(
            0.0,
            1.0,
          ), // Clamp only for the indicator display
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          minHeight: 10,
        ),
        const SizedBox(height: 8),
        progress >= 1.0
            ? Text(
                l10n.overdue,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  children: [
                    TextSpan(
                      text: '${l10n.timeRemaining}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '${days}d ${hours}h ${minutes}m'),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _buildOtherInformationSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.notes,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCountBadge(_ticket!.apiNotes?.length ?? 0),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addNote,
                      tooltip: l10n.addNote,
                    ),
                    IconButton(
                      icon: Icon(
                        _isNotesExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed: () {
                        setState(() {
                          _isNotesExpanded = !_isNotesExpanded;
                        });
                      },
                      tooltip: _isNotesExpanded
                          ? l10n.collapseNotes
                          : l10n.expandNotes,
                    ),
                  ],
                ),
              ],
            ),
            if (_isNotesExpanded) ...[
              if (_ticket!.apiNotes == null || _ticket!.apiNotes!.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l10n.noNotesAvailable),
                )
              else
                ..._groupByDay(_ticket!.apiNotes!, 'creationDate').entries.expand(
                  (entry) => [
                    _buildDayHeader(entry.key, l10n),
                    ...entry.value.map((note) => _buildNoteItem(note, l10n)),
                  ],
                ),
            ],
            const SizedBox(height: 16),

            // Files
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.files,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCountBadge(_ticket!.apiAttachments?.length ?? 0),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _uploadAttachment,
                      tooltip: l10n.uploadFile,
                    ),
                    IconButton(
                      icon: Icon(
                        _isFilesExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed: () {
                        setState(() {
                          _isFilesExpanded = !_isFilesExpanded;
                        });
                      },
                      tooltip: _isFilesExpanded
                          ? l10n.collapseFiles
                          : l10n.expandFiles,
                    ),
                  ],
                ),
              ],
            ),
            if (_isFilesExpanded) ...[
              if (_ticket!.apiAttachments == null ||
                  _ticket!.apiAttachments!.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l10n.noFilesAttached),
                )
              else
                ..._groupByDay(_ticket!.apiAttachments!, 'creationDate').entries.expand(
                  (entry) => [
                    _buildDayHeader(entry.key, l10n),
                    ...entry.value.map((attachment) => _buildAttachmentItem(attachment, l10n)),
                  ],
                ),
            ],
            const SizedBox(height: 16),

            // Logs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.logs,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCountBadge(_logs.length),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    _isLogsExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _isLogsExpanded = !_isLogsExpanded;
                    });
                  },
                  tooltip: _isLogsExpanded
                      ? l10n.collapseLogs
                      : l10n.expandLogs,
                ),
              ],
            ),
            if (_isLogsExpanded) ...[
              if (_isLoadingLogs)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF37414A),
                      ),
                    ),
                  ),
                )
              else if (_logs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l10n.noLogsAvailable),
                )
              else
                ..._groupByDay(_logs, 'creationDate').entries.expand(
                  (entry) => [
                    _buildDayHeader(entry.key, l10n),
                    ...entry.value.map((log) => _buildLogItem(log, l10n)),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAttachment(Map<String, dynamic> attachment) async {
    final l10n = AppLocalizations.of(context);
    final fileName = attachment['name'] as String;

    try {
      if (mounted) {
        BeautifulSnackbar.info(context, l10n.downloadingFile);
      }

      // Download the file first
      final apiService = _apiService;
      final responseBytes = Uint8List.fromList(
        await apiService.downloadAttachment(widget.ticketId, fileName),
      );

      // Let user choose where to save the file (with bytes for mobile platforms)
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: l10n.saveFile,
        fileName: fileName,
        bytes: responseBytes,
      );

      if (savePath == null) {
        // User cancelled the save dialog
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          );
          BeautifulSnackbar.info(context, l10n.downloadCancelled);
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        );
        BeautifulSnackbar.success(context, l10n.fileSavedSuccessfully);
      }
    } catch (e) {
      if (mounted) {
        BeautifulSnackbar.error(context, '${l10n.failedToDownloadFile}: $e');
      }
    }
  }

  Future<void> _deleteAttachment(Map<String, dynamic> attachment) async {
    final l10n = AppLocalizations.of(context);
    final fileName = attachment['name'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAttachment),
        content: Text('${l10n.deleteAttachmentConfirmation} "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final apiService = _apiService;
        await apiService.deleteAttachment(widget.ticketId, fileName);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          );
          BeautifulSnackbar.success(context, l10n.fileDeletedSuccessfully);
          // Reload ticket details to refresh attachments list
          _loadTicketDetails(forceRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          BeautifulSnackbar.error(context, '${l10n.failedToDeleteFile}: $e');
        }
      }
    }
  }

  Future<void> _uploadAttachment() async {
    final l10n = AppLocalizations.of(context);
    try {
      final result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final filePath = file.path!;
        final fileName = file.name;

        // Determine MIME type based on file extension
        String mimeType = 'application/octet-stream';
        final extension = fileName.split('.').last.toLowerCase();
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'pdf':
            mimeType = 'application/pdf';
            break;
          case 'doc':
            mimeType = 'application/msword';
            break;
          case 'docx':
            mimeType =
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            break;
          case 'txt':
            mimeType = 'text/plain';
            break;
        }

        if (mounted) {
          BeautifulSnackbar.info(context, l10n.uploadingFile);
        }

        final apiService = _apiService;
        await apiService.uploadAttachment(
          widget.ticketId,
          filePath,
          fileName,
          mimeType,
        );

        if (mounted) {
          BeautifulSnackbar.success(context, l10n.fileUploadedSuccessfully);
          // Reload ticket details to refresh attachments list
          _loadTicketDetails(forceRefresh: true);
        }
      }
    } catch (e) {
      if (mounted) {
        BeautifulSnackbar.error(context, '${l10n.failedToUploadFile}: $e');
      }
    }
  }

  Widget _buildAttachmentItem(
    Map<String, dynamic> attachment,
    AppLocalizations l10n,
  ) {
    final locale = Localizations.localeOf(context);
    final createdAt = attachment['creationDate'] != null
        ? DateTime.parse(attachment['creationDate'])
        : null;

    final isImage =
        attachment['attachmentType']?.toString().startsWith('image/') ?? false;
    final sizeInKB = attachment['size'] != null
        ? (attachment['size'] / 1024).toStringAsFixed(2)
        : '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isImage ? Icons.image : Icons.attach_file,
                size: 20,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  attachment['name'] ?? l10n.unknownFile,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download, size: 18),
                onPressed: () => _downloadAttachment(attachment),
                tooltip: l10n.download,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => _deleteAttachment(attachment),
                tooltip: l10n.delete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  children: [
                    TextSpan(
                      text: '${l10n.size}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '$sizeInKB KB'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (createdAt != null) ...[
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  formatDate(createdAt, locale.toString(), includeTime: true),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editNote(Map<String, dynamic> note) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: note['content']);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editNote),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            maxLines: 5,
            autofocus: true,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.editNoteContent,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == true &&
        controller.text.isNotEmpty &&
        controller.text != note['content']) {
      try {
        final apiService = _apiService;
        await apiService.updateNote(
          widget.ticketId,
          note['id'],
          controller.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          );
          BeautifulSnackbar.success(context, l10n.noteUpdatedSuccessfully);
          // Reload ticket details to get updated notes
          _loadTicketDetails(forceRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          BeautifulSnackbar.error(context, '${l10n.failedToUpdateNote}: $e');
        }
      }
    }
  }

  Widget _buildNoteItem(Map<String, dynamic> note, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context);
    final createdAt = note['creationDate'] != null
        ? DateTime.parse(note['creationDate'])
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user and edit button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          note['username'] ?? l10n.unknown,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (createdAt != null)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatDate(
                              createdAt,
                              locale.toString(),
                              includeTime: true,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _editNote(note),
                tooltip: l10n.editNote,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Note content
          Text(note['content'] ?? '', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  /// Groups items by day based on their creationDate field.
  /// Returns a map where keys are date strings (yyyy-MM-dd) and values are lists of items.
  Map<String, List<Map<String, dynamic>>> _groupByDay(
    List<dynamic> items,
    String dateField,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;

      final dateStr = item[dateField]?.toString();
      String dayKey;

      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          final date = DateTime.parse(dateStr);
          dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        } catch (_) {
          dayKey = 'unknown';
        }
      } else {
        dayKey = 'unknown';
      }

      grouped.putIfAbsent(dayKey, () => []);
      grouped[dayKey]!.add(item);
    }

    // Sort keys in descending order (most recent first)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return {for (final key in sortedKeys) key: grouped[key]!};
  }

  /// Builds a day header widget for grouped sections.
  Widget _buildDayHeader(String dayKey, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    String displayDate;

    if (dayKey == 'unknown') {
      displayDate = l10n.unknown;
    } else {
      try {
        final date = DateTime.parse(dayKey);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final dateOnly = DateTime(date.year, date.month, date.day);

        if (dateOnly == today) {
          displayDate = l10n.today;
        } else if (dateOnly == yesterday) {
          displayDate = l10n.yesterday;
        } else {
          displayDate = formatDate(date, locale, includeTime: false);
        }
      } catch (_) {
        displayDate = dayKey;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[400])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              displayDate,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context);
    final createdAt = log['creationDate'] != null
        ? DateTime.parse(log['creationDate'])
        : null;

    final changes = log['change'] as List? ?? [];
    final username = log['username'] ?? l10n.unknown;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user and timestamp
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (createdAt != null)
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(
                        createdAt,
                        locale.toString(),
                        includeTime: true,
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
            ],
          ),

          // Changes
          if (changes.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...changes.map((change) => _buildChangeItem(change, l10n)),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              l10n.ticketCreated,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _translateAttribute(String attribute, AppLocalizations l10n) {
    switch (attribute.toLowerCase()) {
      case 'cis':
        return l10n.logAttrCis;
      case 'status':
        return l10n.logAttrStatus;
      case 'notes':
        return l10n.logAttrNotes;
      case 'attachments':
        return l10n.logAttrAttachments;
      case 'priority':
        return l10n.logAttrPriority;
      case 'severity':
        return l10n.logAttrSeverity;
      case 'impact':
        return l10n.logAttrImpact;
      case 'category':
        return l10n.logAttrCategory;
      case 'subcategory':
        return l10n.logAttrSubcategory;
      case 'description':
        return l10n.logAttrDescription;
      case 'name':
        return l10n.logAttrName;
      case 'services':
        return l10n.logAttrServices;
      case 'assignedto':
        return l10n.logAttrAssignedTo;
      case 'team':
        return l10n.logAttrTeam;
      case 'resolutiondate':
        return l10n.resolvedDate;
      case 'slainminutes':
        return l10n.slaInMinutes;
      case 'expectedresolutiondate':
        return l10n.expectedResolutionDate;
      default:
        return attribute;
    }
  }

  Widget _buildChangeItem(Map<String, dynamic> change, AppLocalizations l10n) {
    final attributeRaw = change['attribute'] ?? l10n.unknown;
    final attribute = _translateAttribute(attributeRaw, l10n);
    final hasOldValue = change.containsKey('oldValue');
    final hasNewValue = change.containsKey('newValue');

    String changeDescription = '';
    if (!hasOldValue && hasNewValue) {
      changeDescription = '${l10n.added} $attribute';
    } else if (hasOldValue && !hasNewValue) {
      changeDescription = '${l10n.removed} $attribute';
    } else if (hasOldValue && hasNewValue) {
      changeDescription = '${l10n.updated} $attribute';
    } else {
      changeDescription = '${l10n.modified} $attribute';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.edit, size: 14, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              changeDescription,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityRow(String label, String priorityName) {
    final priorityService = getIt<PriorityRepository>();
    final localeCode = context.read<LocaleCubit>().state.languageCode;
    final priority = priorityService.getPriorityByName(priorityName);

    String displayText = priorityName;
    Color? color;

    if (priority != null) {
      displayText = priority.getTranslation(localeCode);
      color = priorityService.parseColor(priority.color);
      debugPrint(
        'Priority: $priorityName, Color: ${priority.color}, Parsed: $color, Translation: $displayText',
      );
    } else {
      debugPrint('Priority not found: $priorityName');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: _labelGap),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (color ?? Colors.grey).withValues(alpha: 0.1),
              border: Border.all(color: color ?? Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogRow(
    String label,
    String name, {
    required bool isCategoryType,
  }) {
    final catalogService = getIt<CatalogRepository>();
    final localeCode = context.read<LocaleCubit>().state.languageCode;

    String displayText = name;

    if (isCategoryType) {
      final category = catalogService.getCategoryByName(name);
      if (category != null) {
        displayText = category.getTranslation(localeCode);
      }
    } else {
      final subcategory = catalogService.getSubcategoryByName(name);
      if (subcategory != null) {
        displayText = subcategory.getTranslation(localeCode);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: _labelGap),
          Expanded(
            child: Text(displayText, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactSeverityRow(
    String label,
    String name, {
    required bool isImpact,
  }) {
    final impactSeverityService = getIt<ImpactSeverityRepository>();
    final localeCode = context.read<LocaleCubit>().state.languageCode;

    String displayText = name;
    Color? color;

    if (isImpact) {
      final impact = impactSeverityService.getImpactByName(name);
      if (impact != null) {
        displayText = impact.getTranslation(localeCode);
        color = impactSeverityService.parseColor(impact.color);
      }
    } else {
      final severity = impactSeverityService.getSeverityByName(name);
      if (severity != null) {
        displayText = severity.getTranslation(localeCode);
        color = impactSeverityService.parseColor(severity.color);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: _labelGap),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (color ?? Colors.grey).withValues(alpha: 0.1),
              border: Border.all(color: color ?? Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableImpactSeverityRow(
    String label,
    String value,
    VoidCallback onEdit, {
    required bool isImpact,
  }) {
    final impactSeverityService = getIt<ImpactSeverityRepository>();
    final localeCode = context.read<LocaleCubit>().state.languageCode;

    String displayText = value;
    Color? color;

    if (isImpact) {
      final impact = impactSeverityService.getImpactByName(value);
      if (impact != null) {
        displayText = impact.getTranslation(localeCode);
        color = impactSeverityService.parseColor(impact.color);
      }
    } else {
      final severity = impactSeverityService.getSeverityByName(value);
      if (severity != null) {
        displayText = severity.getTranslation(localeCode);
        color = impactSeverityService.parseColor(severity.color);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _labelWidth,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: _labelGap),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (color ?? Colors.grey).withValues(alpha: 0.1),
                  border: Border.all(color: color ?? Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 14,
                    color: color ?? Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.edit, size: 16, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableInfoRow(
    String label,
    String value,
    VoidCallback onEdit,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _labelWidth,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: _labelGap),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(value, style: const TextStyle(fontSize: 14)),
                  ),
                  const Icon(Icons.edit, size: 16, color: Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAffectedItem(AppLocalizations l10n) {
    if (_ticket!.cis == null || _ticket!.cis!.isEmpty) {
      return l10n.na;
    }
    return _ticket!.cis!.first['ciFullName'] ??
        _ticket!.cis!.first['name'] ??
        l10n.na;
  }

  String _getEquipmentName(AppLocalizations l10n) {
    if (_ticket!.cis == null || _ticket!.cis!.isEmpty) {
      return l10n.na;
    }
    return _ticket!.cis!.first['name'] ?? l10n.na;
  }

  String _getServiceName(AppLocalizations l10n) {
    if (_ticket!.services == null || _ticket!.services!.isEmpty) {
      return l10n.na;
    }
    return _ticket!.services!.first;
  }

  String _getServiceType(AppLocalizations l10n) {
    if (_ticket!.serviceTypes == null || _ticket!.serviceTypes!.isEmpty) {
      return l10n.na;
    }
    return _ticket!.serviceTypes!.first;
  }

  IconData _getTypeIcon(String? type) {
    switch ((type ?? '').toUpperCase()) {
      case 'INCIDENT':
        return Icons.warning_amber_rounded;
      case 'PROBLEM':
        return FontAwesomeIcons.circleExclamation;
      case 'REQUEST':
        return FontAwesomeIcons.clipboard;
      default:
        return Icons.category;
    }
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTicketSkeleton() {
    return const _TicketDetailSkeleton();
  }
}

class _TicketDetailSkeleton extends StatelessWidget {
  const _TicketDetailSkeleton();

  static const double _labelWidth = 150;
  static const double _labelGap = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final labelWidth = maxWidth * 0.4 > _labelWidth
            ? _labelWidth
            : maxWidth * 0.4;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Expanded(
                    child: _SkeletonBar(width: double.infinity, height: 16),
                  ),
                  SizedBox(width: 12),
                  _SkeletonBar(width: 90, height: 16),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  _SkeletonBar(width: 22, height: 22),
                  SizedBox(width: 8),
                  Expanded(child: _SkeletonBar(width: double.infinity, height: 18)),
                ],
              ),
              const SizedBox(height: 10),
              const _SkeletonBar(width: double.infinity, height: 14),
              const SizedBox(height: 8),
              const _SkeletonBar(width: 200, height: 14),
              const SizedBox(height: 8),
              const _SkeletonBar(width: 160, height: 14),
              const SizedBox(height: 24),
              const _SkeletonBar(width: 140, height: 18),
              const SizedBox(height: 12),
              _buildCardSkeleton(
                child: Column(
                  children: [
                    _buildLabelRow(labelWidth: labelWidth, valueFlex: 6),
                    const SizedBox(height: 12),
                    _buildLabelRow(labelWidth: labelWidth, valueFlex: 7),
                    const SizedBox(height: 12),
                    _buildLabelRow(labelWidth: labelWidth, valueFlex: 5),
                    const SizedBox(height: 12),
                    _buildLabelRow(labelWidth: labelWidth, valueFlex: 7),
                    const SizedBox(height: 12),
                    _buildLabelRow(labelWidth: labelWidth, valueFlex: 4),
                    const SizedBox(height: 12),
                    _buildLabelRow(labelWidth: labelWidth, valueFlex: 4),
                    const SizedBox(height: 12),
                    _buildLabelRow(labelWidth: labelWidth, valueFlex: 8),
                    const SizedBox(height: 12),
                    _buildLabelRow(
                      labelWidth: labelWidth,
                      valueFlex: 10,
                      height: 24,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SkeletonBar(width: 90, height: 18),
              const SizedBox(height: 12),
              _buildCardSkeleton(
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: _SkeletonBar(width: double.infinity, height: 12),
                        ),
                        SizedBox(width: 12),
                        _SkeletonBar(width: 40, height: 12),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _SkeletonBar(width: double.infinity, height: 10),
                    const SizedBox(height: 8),
                    const _SkeletonBar(width: 160, height: 12),
                    const SizedBox(height: 16),
                    _buildLabelRow(labelWidth: labelWidth, valueFlex: 3),
                    const SizedBox(height: 12),
                    _buildLabelRow(labelWidth: labelWidth, valueFlex: 6),
                    const SizedBox(height: 12),
                    _buildLabelRow(labelWidth: labelWidth, valueFlex: 6),
                    const SizedBox(height: 12),
                    _buildLabelRow(labelWidth: labelWidth, valueFlex: 6),
                    const SizedBox(height: 12),
                    _buildLabelRow(labelWidth: labelWidth, valueFlex: 6),
                    const SizedBox(height: 12),
                    _buildLabelRow(labelWidth: labelWidth, valueFlex: 6),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SkeletonBar(width: 170, height: 18),
              const SizedBox(height: 12),
              _buildCardSkeleton(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeaderSkeleton(),
                    const SizedBox(height: 8),
                    const _SkeletonBar(width: 200, height: 14),
                    const SizedBox(height: 8),
                    const _SkeletonBar(width: double.infinity, height: 14),
                    const SizedBox(height: 16),
                    _buildSectionHeaderSkeleton(),
                    const SizedBox(height: 8),
                    const _SkeletonBar(width: 160, height: 14),
                    const SizedBox(height: 8),
                    const _SkeletonBar(width: double.infinity, height: 14),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(
                          child: _SkeletonBar(width: double.infinity, height: 16),
                        ),
                        SizedBox(width: 12),
                        _SkeletonBar(width: 28, height: 28),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _SkeletonBar(width: 140, height: 14),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildCardSkeleton({required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  static Widget _buildLabelRow({
    required double labelWidth,
    required int valueFlex,
    double height = 14,
  }) {
    return Row(
      children: [
        SizedBox(width: labelWidth, child: _SkeletonBar(width: labelWidth, height: height)),
        const SizedBox(width: _labelGap),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: valueFlex,
                child: _SkeletonBar(width: double.infinity, height: height),
              ),
              const Spacer(flex: 10),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildSectionHeaderSkeleton() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SkeletonBar(width: 90, height: 16),
        _SkeletonBar(width: 26, height: 16),
      ],
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.4, end: 0.8),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withValues(alpha: value),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
      onEnd: () {},
    );
  }
}
