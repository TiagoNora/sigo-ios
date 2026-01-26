import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:convert';
import '../../../models/ticket.dart';
import '../../../models/saved_filter.dart';
import '../../../core/di/injection.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../services/api_service.dart';
import '../../../blocs/ticket_bloc.dart';
import '../../../blocs/locale_cubit.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/ticket_extensions.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/beautiful_snackbar.dart';

class FilterScreen extends StatefulWidget {
  final TicketStatus? initialStatus;
  final TicketPriority? initialPriority;
  final String? initialCategory;
  final Map<String, dynamic>? initialQuery;
  final int? initialSourceFilterId;
  final String? initialFilterLabel;
  final String? initialFilterLabelKey;

  const FilterScreen({
    super.key,
    this.initialStatus,
    this.initialPriority,
    this.initialCategory,
    this.initialQuery,
    this.initialSourceFilterId,
    this.initialFilterLabel,
    this.initialFilterLabelKey,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen>
    with SingleTickerProviderStateMixin {
  final Set<TicketStatus> _selectedStatuses = {};
  final Set<String> _selectedTypes = {};
  final Set<String> _selectedScopes = {};
  final Set<String> _selectedImpacts = {};
  final Set<String> _selectedSeverities = {};
  String? _selectedCreationDateRange;
  String? _selectedResolutionDateRange;
  DateTimeRange? _customCreationDateRange;
  DateTimeRange? _customResolutionDateRange;

  List<SavedFilter> _savedFilters = [];
  bool _isLoadingFilters = true;
  SavedFilter? _selectedSavedFilter;
  Map<String, dynamic>? _activeFilterQuery;
  int? _activeFilterSourceId;
  int? _draftSourceFilterId;
  String? _activeFilterLabelKey;
  String? _pendingSelectFilterName;
  Map<String, dynamic>? _pendingSelectFilterQuery;
  DateTime? _draftLastUpdated;
  bool _hydratedFromBloc = false;
  Map<String, dynamic>? _lastHydratedQuery;
  String? _cachedActiveQueryHash;

  List<Map<String, dynamic>> _impactOptions = [];
  List<Map<String, dynamic>> _severityOptions = [];
  bool _isLoadingCatalogs = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to show/hide bottom button
      }
    });
    final state = context.read<TicketBloc>().state;
    final initialQuery = widget.initialQuery ?? state.filterQuery;
    final initialSourceId =
        widget.initialSourceFilterId ?? state.filterSourceId;
    final initialLabelKey =
        widget.initialFilterLabelKey ?? state.filterLabelKey;
    _setActiveFilter(
      initialQuery,
      sourceId: initialLabelKey == 'draft_filter' ? null : initialSourceId,
      draftSourceId: initialLabelKey == 'draft_filter' ? initialSourceId : null,
      labelKey: initialLabelKey,
      markHydrated: true,
    );
    _loadSavedFilters();
    _loadCatalogs();
  }

  Map<String, dynamic>? _asJsonQuery(Map<String, dynamic>? query) {
    if (query == null) return null;
    if (query is! Map) return null;
    final normalized = Map<String, dynamic>.from(query);
    final rawConditions = normalized['conditions'];
    if (rawConditions is List) {
      normalized['conditions'] = rawConditions
          .map((c) {
            if (c is Map<String, dynamic>) return Map<String, dynamic>.from(c);
            if (c is Map) return Map<String, dynamic>.from(c as Map);
            if (c is FilterCondition) return c.toJson();
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return normalized;
  }

  void _setActiveFilter(
    Map<String, dynamic>? query, {
    int? sourceId,
    int? draftSourceId,
    String? labelKey,
    bool populate = true,
    bool markHydrated = false,
  }) {
    _activeFilterQuery = _asJsonQuery(query);
    _activeFilterLabelKey = labelKey;

    // Cache the normalized hash of the active query
    if (_activeFilterQuery != null) {
      final normalized = _normalizeQueryForCompare(_activeFilterQuery);
      _cachedActiveQueryHash = json.encode(normalized);
    } else {
      _cachedActiveQueryHash = null;
    }

    if (draftSourceId != null) {
      _draftSourceFilterId = draftSourceId;
      _activeFilterSourceId = null;
    } else {
      _activeFilterSourceId = sourceId;
      if (sourceId != null) {
        _draftSourceFilterId = null;
      }
    }
    _lastHydratedQuery = _activeFilterQuery;
    if (markHydrated) {
      _hydratedFromBloc = true;
    }
    if (populate && _activeFilterQuery != null) {
      _populateQuickFiltersFromActiveQuery();
    }
  }

  Map<String, dynamic>? _normalizeQueryForCompare(Map<String, dynamic>? query) {
    if (query == null) return null;

    final operator = query['operator'];
    final rawConditions = query['conditions'];
    final conditions = <Map<String, dynamic>>[];

    if (rawConditions is List) {
      for (final condition in rawConditions) {
        Map<String, dynamic>? m;
        if (condition is Map) {
          m = Map<String, dynamic>.from(condition);
        } else if (condition is FilterCondition) {
          m = condition.toJson();
        }
        if (m == null) continue;
        conditions.add({
          'attribute': m['attribute'],
          'operator': m['operator'],
          'value': _normalizeQueryValue(m['value']),
        });
      }
    }

    conditions.sort((a, b) {
      final attrA = (a['attribute'] ?? '').toString();
      final attrB = (b['attribute'] ?? '').toString();
      final attrCmp = attrA.compareTo(attrB);
      if (attrCmp != 0) return attrCmp;

      final opA = (a['operator'] ?? '').toString();
      final opB = (b['operator'] ?? '').toString();
      final opCmp = opA.compareTo(opB);
      if (opCmp != 0) return opCmp;

      final valA = json.encode(a['value']);
      final valB = json.encode(b['value']);
      return valA.compareTo(valB);
    });

    return {'operator': operator, 'conditions': conditions};
  }

  dynamic _normalizeQueryValue(dynamic value) {
    if (value is List) {
      final items = value.map(_normalizeQueryValue).toList();
      items.sort((a, b) => json.encode(a).compareTo(json.encode(b)));
      return items;
    }

    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      final normalized = <String, dynamic>{};
      for (final key in keys) {
        normalized[key] = _normalizeQueryValue(value[key]);
      }
      return normalized;
    }

    return value;
  }

  bool _queriesEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    final normalizedA = _normalizeQueryForCompare(a);
    final normalizedB = _normalizeQueryForCompare(b);
    return json.encode(normalizedA) == json.encode(normalizedB);
  }

  void _populateQuickFiltersFromActiveQuery() {
    final query = _asJsonQuery(_activeFilterQuery);
    if (query == null) return;

    final conditions = query['conditions'] as List<dynamic>?;
    if (conditions == null) return;

    // Clear existing selections first
    _selectedStatuses.clear();
    _selectedTypes.clear();
    _selectedScopes.clear();
    _selectedImpacts.clear();
    _selectedSeverities.clear();
    _selectedCreationDateRange = null;
    _selectedResolutionDateRange = null;
    _customCreationDateRange = null;
    _customResolutionDateRange = null;

    // Parse each condition
    for (final condition in conditions) {
      if (condition is! Map<String, dynamic>) continue;

      final attribute = condition['attribute'] as String?;
      final operator = condition['operator'] as String?;
      final value = condition['value'];

      if (attribute == null || operator == null) continue;

      switch (attribute) {
        case 'status':
          if (operator == 'in' && value is List) {
            for (final statusValue in value) {
              try {
                final status = TicketStatus.values.firstWhere(
                  (s) => s.toApiValue() == statusValue,
                );
                _selectedStatuses.add(status);
              } catch (e) {
                // Status not found, skip it
                if (kDebugMode) {
                  debugPrint('Unknown status value: $statusValue');
                }
              }
            }
          }
          break;

        case 'scope':
          if (operator == 'in' && value is List) {
            _selectedScopes.addAll(value.cast<String>());
          }
          break;

        case 'type':
          if (operator == 'in' && value is List) {
            _selectedTypes.addAll(value.cast<String>());
          }
          break;

        case 'impact':
          if (operator == 'in' && value is List) {
            _selectedImpacts.addAll(value.cast<String>());
          }
          break;

        case 'severity':
          if (operator == 'in' && value is List) {
            _selectedSeverities.addAll(value.cast<String>());
          }
          break;

        case 'creationDate':
          if (operator == 'ge' && value is String) {
            // Map placeholder back to the selection key
            final dateRangeMap = {
              r'${today}': 'today',
              r'${last24Hours}': 'last24Hours',
              r'${lastWeek}': 'lastWeek',
              r'${lastMonth}': 'lastMonth',
              r'${last3Months}': 'last3Months',
              'today': 'today',
              'last24Hours': 'last24Hours',
              'lastWeek': 'lastWeek',
              'lastMonth': 'lastMonth',
              'last3Months': 'last3Months',
            };
            _selectedCreationDateRange = dateRangeMap[value];
          } else if (operator == 'between' && value is List && value.length == 2) {
            // Parse custom date range
            try {
              final startDate = DateTime.parse(value[0] as String);
              final endDate = DateTime.parse(value[1] as String);
              _customCreationDateRange = DateTimeRange(
                start: startDate,
                end: endDate,
              );
              _selectedCreationDateRange = 'custom';
            } catch (e) {
              if (kDebugMode) {
                debugPrint('Error parsing custom creation date range: $e');
              }
            }
          }
          break;

        case 'resolutionDate':
          if (operator == 'ge' && value is String) {
            // Map placeholder back to the selection key
            final dateRangeMap = {
              r'${today}': 'today',
              r'${last24Hours}': 'last24Hours',
              r'${lastWeek}': 'lastWeek',
              r'${lastMonth}': 'lastMonth',
              r'${last3Months}': 'last3Months',
              'today': 'today',
              'last24Hours': 'last24Hours',
              'lastWeek': 'lastWeek',
              'lastMonth': 'lastMonth',
              'last3Months': 'last3Months',
            };
            _selectedResolutionDateRange = dateRangeMap[value];
          } else if (operator == 'between' && value is List && value.length == 2) {
            // Parse custom date range
            try {
              final startDate = DateTime.parse(value[0] as String);
              final endDate = DateTime.parse(value[1] as String);
              _customResolutionDateRange = DateTimeRange(
                start: startDate,
                end: endDate,
              );
              _selectedResolutionDateRange = 'custom';
            } catch (e) {
              if (kDebugMode) {
                debugPrint('Error parsing custom resolution date range: $e');
              }
            }
          }
          break;
      }
    }

    setState(() {});
  }

  Future<void> _showCustomDateRangePicker(
    BuildContext context,
    bool isCreationDate,
  ) async {
    final l10n = AppLocalizations.of(context);
    final existingRange = isCreationDate
        ? _customCreationDateRange
        : _customResolutionDateRange;

    // Pick start date
    final startDate = await showDatePicker(
      context: context,
      initialDate: existingRange?.start ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF37414A),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (startDate == null) return;

    // Pick start time
    final startTime = await showTimePicker(
      context: context,
      initialTime: existingRange != null
          ? TimeOfDay.fromDateTime(existingRange.start)
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF37414A),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (startTime == null) return;

    // Pick end date
    final endDate = await showDatePicker(
      context: context,
      initialDate: existingRange?.end ?? startDate,
      firstDate: startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF37414A),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (endDate == null) return;

    // Pick end time
    final endTime = await showTimePicker(
      context: context,
      initialTime: existingRange != null
          ? TimeOfDay.fromDateTime(existingRange.end)
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF37414A),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (endTime == null) return;

    // Combine date and time
    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );

    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
    );

    // Validate that end is after start
    if (end.isBefore(start)) {
      if (mounted) {
        BeautifulSnackbar.error(
          context,
          l10n.endDateMustBeAfterStartDate,
        );
      }
      return;
    }

    setState(() {
      if (isCreationDate) {
        _customCreationDateRange = DateTimeRange(start: start, end: end);
        _selectedCreationDateRange = 'custom';
      } else {
        _customResolutionDateRange = DateTimeRange(start: start, end: end);
        _selectedResolutionDateRange = 'custom';
      }
      _markDraftFromActive();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedFilters() async {
    setState(() {
      _isLoadingFilters = true;
    });

    try {
      final authRepository = getIt<AuthRepository>();
      final apiService = ApiService(
        authRepository.accessToken!,
        baseUrl: authRepository.tenantConfig?.baseUrl ?? "",
        authService: authRepository,
      );
      final filtersJson = await apiService.getSavedFilters();

      setState(() {
        _savedFilters = filtersJson
            .map((json) => SavedFilter.fromJson(json))
            .toList();
        _isLoadingFilters = false;

        if (_activeFilterSourceId != null) {
          try {
            _selectedSavedFilter = _savedFilters.firstWhere(
              (f) => f.id == _activeFilterSourceId,
            );
            // If we only had the id, hydrate the query from the saved filter
            _activeFilterQuery ??= _selectedSavedFilter?.config.toJson();
          } catch (e) {
            // Filter not found in saved filters, continue without it
            if (kDebugMode) {
              debugPrint('Saved filter not found: $e');
            }
          }
        }
      });

      if (_pendingSelectFilterName != null &&
          _pendingSelectFilterQuery != null) {
        final normalized = _pendingSelectFilterName!.trim().toLowerCase();
        try {
          final match = _savedFilters.firstWhere(
            (filter) =>
                filter.visibility == 'PRIVATE' &&
                filter.name.trim().toLowerCase() == normalized,
          );
          setState(() {
            _setActiveFilter(
              _pendingSelectFilterQuery,
              sourceId: match.id,
              draftSourceId: null,
              labelKey: null,
              populate: false,
            );
            _pendingSelectFilterName = null;
            _pendingSelectFilterQuery = null;
          });
        } catch (_) {
          // No match found; clear pending selection.
          setState(() {
            _pendingSelectFilterName = null;
            _pendingSelectFilterQuery = null;
          });
        }
      }

      if (_activeFilterQuery != null) {
        _setActiveFilter(
          _activeFilterQuery,
          sourceId:
              _activeFilterLabelKey == 'draft_filter' ? null : _activeFilterSourceId,
          draftSourceId: _activeFilterLabelKey == 'draft_filter'
              ? _draftSourceFilterId
              : null,
          labelKey: _activeFilterLabelKey,
          populate: true,
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingFilters = false;
      });
      if (mounted) {
        BeautifulSnackbar.error(
          context,
          AppLocalizations.of(context).failedToLoadSavedFilters,
        );
      }
    }
  }

  Future<void> _loadCatalogs() async {
    setState(() {
      _isLoadingCatalogs = true;
    });

    try {
      final authRepository = getIt<AuthRepository>();
      final apiService = ApiService(
        authRepository.accessToken!,
        baseUrl: authRepository.tenantConfig?.baseUrl ?? "",
        authService: authRepository,
      );

      final impacts = await apiService.getImpacts();
      final severities = await apiService.getSeverities();

      setState(() {
        _impactOptions = impacts;
        _severityOptions = severities;
        _isLoadingCatalogs = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCatalogs = false;
      });
      if (kDebugMode) {
        debugPrint('Error loading catalogs: $e');
      }
    }
  }

  void _applyQuickFilters() {
    final l10n = AppLocalizations.of(context);
    final query = _buildQuickFilterQuery(l10n);
    _draftLastUpdated = DateTime.now();
    _setActiveFilter(
      query,
      sourceId: null,
      draftSourceId: _draftSourceFilterId,
      labelKey: 'draft_filter',
      populate: true,
    );
    Navigator.pop(context, {
      'status': null,
      'priority': null,
      'category': null,
      'savedFilter': null,
      'query': query,
      'sourceFilterId': _draftSourceFilterId,
      'filterName': l10n.draftFilter,
      'filterNameKey': 'draft_filter',
    });
  }

  void _markDraftFromActive() {
    if (_activeFilterSourceId != null) {
      _draftSourceFilterId = _activeFilterSourceId;
      _activeFilterSourceId = null;
    }
    _activeFilterLabelKey = 'draft_filter';
    _draftLastUpdated = DateTime.now();
    _selectedSavedFilter = null;
  }

  bool _hasFilterChanges() {
    final l10n = AppLocalizations.of(context);
    final query = _buildQuickFilterQuery(l10n);

    if (query == null) return false;
    if (_cachedActiveQueryHash == null) return true;

    // Use cached hash for fast comparison
    final normalized = _normalizeQueryForCompare(query);
    final queryHash = json.encode(normalized);
    return queryHash != _cachedActiveQueryHash;
  }

  bool _hasMatchingPrivateFilter(Map<String, dynamic>? query) {
    if (query == null) return false;
    try {
      return _savedFilters.any(
        (filter) =>
            filter.visibility == 'PRIVATE' &&
            _queriesEqual(filter.config.toJson(), query),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking matching private filters: $e');
      }
      return false;
    }
  }

  bool _canSaveQuickFilter() {
    final l10n = AppLocalizations.of(context);
    final query = _buildQuickFilterQuery(l10n);
    if (query == null) return false;
    if (_activeFilterSourceId == null) return true;
    if (_hasFilterChanges()) return true;
    return !_hasMatchingPrivateFilter(query);
  }

  Future<void> _saveQuickFilter() async {
    final l10n = AppLocalizations.of(context);
    final query = _buildQuickFilterQuery(l10n);

    if (query == null) {
      BeautifulSnackbar.warning(context, l10n.noFiltersSelected);
      return;
    }

    SavedFilter? draftSource;
    if (_draftSourceFilterId != null) {
      try {
        draftSource = _savedFilters.firstWhere(
          (f) => f.id == _draftSourceFilterId,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Draft source filter not found: $e');
        }
      }
    }
    final nameController = TextEditingController(
      text: draftSource?.name ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final normalizedName = nameController.text.trim().toLowerCase();
          final hasName = normalizedName.isNotEmpty;
          final publicNameExists = hasName &&
              _savedFilters.any(
                (filter) =>
                    filter.visibility == 'PUBLIC' &&
                    filter.name.trim().toLowerCase() == normalizedName,
              );
          final privateNameExists = hasName &&
              _savedFilters.any(
                (filter) =>
                    filter.visibility == 'PRIVATE' &&
                    filter.name.trim().toLowerCase() == normalizedName,
              );
          final canSave = hasName && !publicNameExists;

          return AlertDialog(
            title: Text(l10n.saveFilter),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.filterName,
                    hintText: l10n.enterFilterName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (publicNameExists) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.filterNameAlreadyExists,
                    style: const TextStyle(color: Colors.red),
                  ),
                ] else if (privateNameExists) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.filterWillReplaceExisting,
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: canSave ? () => Navigator.pop(context, true) : null,
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        final normalizedName = nameController.text.trim().toLowerCase();
        final publicNameExists = _savedFilters.any(
          (filter) =>
              filter.visibility == 'PUBLIC' &&
              filter.name.trim().toLowerCase() == normalizedName,
        );
        if (publicNameExists) {
          if (mounted) {
            BeautifulSnackbar.error(context, l10n.filterNameAlreadyExists);
          }
          return;
        }

        SavedFilter? privateMatch;
        try {
          privateMatch = _savedFilters.firstWhere(
            (filter) =>
                filter.visibility == 'PRIVATE' &&
                filter.name.trim().toLowerCase() == normalizedName,
          );
        } catch (_) {
          privateMatch = null;
        }

        final authRepository = getIt<AuthRepository>();
        final apiService = ApiService(
          authRepository.accessToken!,
          baseUrl: authRepository.tenantConfig?.baseUrl ?? "",
          authService: authRepository,
        );

        final filterData = {
          'type': 'ONECARE_FILTER',
          'name': nameController.text,
          'visibility': 'PRIVATE',
          'config': query,
        };

        int? savedId;
        if (privateMatch != null) {
          filterData['id'] = privateMatch.id;
          await apiService.updateFilter(filterData);
          savedId = privateMatch.id;
          if (mounted) {
            BeautifulSnackbar.success(context, l10n.filterUpdatedSuccessfully);
          }
        } else {
          final created = await apiService.createFilter(filterData);
          final createdId = created['id'];
          if (createdId is int) {
            savedId = createdId;
          } else if (createdId is String) {
            savedId = int.tryParse(createdId);
          }
          if (mounted) {
            BeautifulSnackbar.success(context, l10n.filterSavedSuccessfully);
          }
        }

        if (mounted) {
          setState(() {
            _activeFilterLabelKey = null;
            _draftSourceFilterId = null;
            _draftLastUpdated = null;
            _selectedSavedFilter = null;
            if (savedId != null) {
              _setActiveFilter(
                query,
                sourceId: savedId,
                draftSourceId: null,
                labelKey: null,
                populate: false,
              );
            } else {
              _pendingSelectFilterName = nameController.text;
              _pendingSelectFilterQuery = query;
              _activeFilterSourceId = null;
            }
          });
          _loadSavedFilters();
          Navigator.pop(context, {
            'status': null,
            'priority': null,
            'category': null,
            'savedFilter': null,
            'query': query,
            'sourceFilterId': savedId,
            'filterName': nameController.text,
            'filterNameKey': null,
          });
        }
      } catch (e) {
        if (mounted) {
          BeautifulSnackbar.error(context, 'Failed to save filter: $e');
        }
      }
    }
  }

  void _clearFilters() {
    setState(() {
      // ⚠️ NÃO limpa os status - preserva a seleção do usuário
      // _selectedStatuses.clear();

      // Limpa todos os outros filtros
      _selectedTypes.clear();
      _selectedScopes.clear();
      _selectedImpacts.clear();
      _selectedSeverities.clear();
      _selectedCreationDateRange = null;
      _selectedResolutionDateRange = null;
      _selectedSavedFilter = null;
      _activeFilterSourceId = null;
      _draftSourceFilterId = null;
      _activeFilterLabelKey = null;
      _draftLastUpdated = null;
      _activeFilterQuery = null;
    });
  }

  String _getLocalizedType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'INCIDENT':
        return l10n.incident;
      case 'REQUEST':
        return l10n.request;
      case 'PROBLEM':
        return l10n.problem;
      default:
        return type;
    }
  }

  String _getLocalizedScope(String scope, AppLocalizations l10n) {
    switch (scope) {
      case 'TEAM':
        return l10n.scopeTeam;
      case 'INDIVIDUAL':
        return l10n.scopeIndividual;
      default:
        return scope;
    }
  }

  String _getTranslatedName(Map<String, dynamic> item, String languageCode) {
    final name = item['name'] as String? ?? '';
    final translations = item['translations'] as Map<String, dynamic>?;

    if (translations != null) {
      final translation = translations[languageCode] as String?;
      if (translation != null && translation.isNotEmpty) {
        return translation;
      }
    }

    return name;
  }

  Future<void> _deleteSavedFilter(SavedFilter filter) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteFilterConfirm(filter.name)),
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
        final authRepository = getIt<AuthRepository>();
        final apiService = ApiService(
          authRepository.accessToken!,
          baseUrl: authRepository.tenantConfig?.baseUrl ?? "",
          authService: authRepository,
        );
        await apiService.deleteFilter(filter.id);

        if (mounted) {
          BeautifulSnackbar.success(context, l10n.filterDeletedSuccessfully);
          _loadSavedFilters();
        }
      } catch (e) {
        if (mounted) {
          BeautifulSnackbar.error(context, 'Failed to delete filter: $e');
        }
      }
    }
  }

  bool _isFilterActive(SavedFilter filter) {
    if (_activeFilterLabelKey == 'draft_filter') return false;
    if (_activeFilterSourceId != null) {
      return filter.id == _activeFilterSourceId;
    }

    if (_activeFilterQuery == null) return false;

    // Compare only the filter logic (ignore map key order and names)
    return _queriesEqual(filter.config.toJson(), _activeFilterQuery);
  }

  bool _hasDraftActiveFilter() {
    if (_activeFilterQuery == null) return false;
    return _activeFilterLabelKey == 'draft_filter';
  }

  SavedFilter? _findDraftSourceFilter() {
    if (_draftSourceFilterId == null) return null;
    try {
      return _savedFilters.firstWhere((f) => f.id == _draftSourceFilterId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Draft source filter not found: $e');
      }
      return null;
    }
  }

  Widget _buildDraftFilterCard(AppLocalizations l10n, String locale) {
    final sourceFilter = _findDraftSourceFilter();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.green[50],
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _activeFilterQuery == null
            ? null
            : () {
                Navigator.pop(context, {
                  'status': null,
                  'priority': null,
                  'category': null,
                  'savedFilter': null,
                  'query': _activeFilterQuery,
                  'sourceFilterId': _draftSourceFilterId,
                  'filterName': l10n.draftFilter,
                  'filterNameKey': 'draft_filter',
                });
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.edit_note, color: Colors.green, size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.draftFilter,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        Text(
                          l10n.currentlyActive,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      'LOCAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic>? _buildQuickFilterQuery(AppLocalizations l10n) {
    final conditions = <Map<String, dynamic>>[];

    if (_selectedStatuses.isNotEmpty) {
      conditions.add({
        'attribute': 'status',
        'operator': 'in',
        'value': _selectedStatuses.map((s) => s.toApiValue()).toList(),
      });
    }

    if (_selectedScopes.isNotEmpty) {
      conditions.add({
        'attribute': 'scope',
        'operator': 'in',
        'value': _selectedScopes.toList(),
      });
    }

    if (_selectedTypes.isNotEmpty) {
      conditions.add({
        'attribute': 'type',
        'operator': 'in',
        'value': _selectedTypes.toList(),
      });
    }

    if (_selectedCreationDateRange != null) {
      if (_selectedCreationDateRange == 'custom' &&
          _customCreationDateRange != null) {
        // Use 'between' operator for custom date ranges with exact times
        final startDate = _customCreationDateRange!.start.toUtc().toIso8601String();
        final endDate = _customCreationDateRange!.end.toUtc().toIso8601String();
        conditions.add({
          'attribute': 'creationDate',
          'operator': 'between',
          'value': [startDate, endDate],
        });
      } else {
        final placeholder = {
          'today': r'${today}',
          'last24Hours': r'${last24Hours}',
          'lastWeek': r'${lastWeek}',
          'lastMonth': r'${lastMonth}',
          'last3Months': r'${last3Months}',
        }[_selectedCreationDateRange];

        if (placeholder != null) {
          conditions.add({
            'attribute': 'creationDate',
            'operator': 'ge',
            'value': placeholder,
          });
        }
      }
    }

    if (_selectedResolutionDateRange != null) {
      if (_selectedResolutionDateRange == 'custom' &&
          _customResolutionDateRange != null) {
        // Use 'between' operator for custom date ranges with exact times
        final startDate = _customResolutionDateRange!.start.toUtc().toIso8601String();
        final endDate = _customResolutionDateRange!.end.toUtc().toIso8601String();
        conditions.add({
          'attribute': 'resolutionDate',
          'operator': 'between',
          'value': [startDate, endDate],
        });
      } else {
        final placeholder = {
          'today': r'${today}',
          'last24Hours': r'${last24Hours}',
          'lastWeek': r'${lastWeek}',
          'lastMonth': r'${lastMonth}',
          'last3Months': r'${last3Months}',
        }[_selectedResolutionDateRange];

        if (placeholder != null) {
          conditions.add({
            'attribute': 'resolutionDate',
            'operator': 'ge',
            'value': placeholder,
          });
        }
      }
    }

    if (_selectedImpacts.isNotEmpty) {
      conditions.add({
        'attribute': 'impact',
        'operator': 'in',
        'value': _selectedImpacts.toList(),
      });
    }

    if (_selectedSeverities.isNotEmpty) {
      conditions.add({
        'attribute': 'severity',
        'operator': 'in',
        'value': _selectedSeverities.toList(),
      });
    }

    if (conditions.isEmpty) return null;

    return {
      'name': l10n.quickFilters,
      'operator': 'AND',
      'conditions': conditions,
    };
  }

  Widget _buildSavedFiltersTab() {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final hasDraft = _hasDraftActiveFilter();
    final draftSource = _findDraftSourceFilter();

    if (_isLoadingFilters) {
      return const _SavedFiltersSkeletonList();
    }

    if (_savedFilters.isEmpty && !hasDraft) {
      return RefreshIndicator(
        onRefresh: _loadSavedFilters,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_alt_off,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noSavedFilters,
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.pullDownToRefresh,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    final orderedFilters = List<SavedFilter>.from(_savedFilters);
    final activeIndex = orderedFilters.indexWhere(_isFilterActive);
    if (activeIndex > 0) {
      final activeFilter = orderedFilters.removeAt(activeIndex);
      orderedFilters.insert(0, activeFilter);
    }

    return RefreshIndicator(
      onRefresh: _loadSavedFilters,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orderedFilters.length + (hasDraft ? 1 : 0),
        itemBuilder: (context, index) {
          if (hasDraft && index == 0) {
            return _buildDraftFilterCard(l10n, locale.toString());
          }

          final filterIndex = hasDraft ? index - 1 : index;
          final filter = orderedFilters[filterIndex];
          final isActive = _isFilterActive(filter);
          final isDraftSource =
              _draftSourceFilterId != null &&
              filter.id == _draftSourceFilterId;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isActive ? Colors.green[50] : null,
            elevation: isActive ? 4 : 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Apply filter immediately
                final queryConfig = filter.config.toJson();
                debugPrint('Selected filter: ${filter.name}');
                debugPrint('Query config: $queryConfig');
                _setActiveFilter(
                  queryConfig,
                  sourceId: filter.id,
                  draftSourceId: null,
                  labelKey: null,
                  populate: true,
                );

                Navigator.pop(context, {
                  'status': null,
                  'priority': null,
                  'category': null,
                  'savedFilter': filter,
                  'query': queryConfig,
                  'sourceFilterId': filter.id,
                  'filterName': filter.name,
                  'filterNameKey': null,
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        if (isActive)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                        if (isDraftSource)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.circle,
                              color: Colors.amber,
                              size: 12,
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                filter.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.green[700] : null,
                                ),
                              ),
                              if (isActive)
                                Text(
                                  l10n.currentlyActive,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: filter.visibility == 'PUBLIC'
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            filter.visibility,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: filter.visibility == 'PUBLIC'
                                  ? Colors.blue
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Footer
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          filter.owner,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          formatDate(
                                            filter.lastUpdate,
                                            locale.toString(),
                                            includeTime: false,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (filter.visibility == 'PRIVATE')
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteSavedFilter(filter),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickFiltersTab() {
    final l10n = AppLocalizations.of(context);

    final statusOptions = const [
      TicketStatus.acknowledged,
      TicketStatus.closed,
      TicketStatus.held,
      TicketStatus.inProgress,
      TicketStatus.pending,
      TicketStatus.resolved,
      TicketStatus.cancelled,
    ];

    const typeOptions = ['INCIDENT', 'REQUEST', 'PROBLEM'];
    const scopeOptions = ['TEAM', 'INDIVIDUAL'];

    final dateOptions = <String, String>{
      'today': l10n.today,
      'last24Hours': l10n.last24Hours,
      'lastWeek': l10n.lastWeek,
      'lastMonth': l10n.lastMonth,
      'last3Months': l10n.last3Months,
      'custom': l10n.customDateRange,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.status,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statusOptions.map((status) {
            final isSelected = _selectedStatuses.contains(status);
            return FilterChip(
              label: Text(status.getLocalizedName(l10n)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedStatuses.add(status);
                  } else {
                    _selectedStatuses.remove(status);
                  }
                  _markDraftFromActive();
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        Text(
          l10n.scope,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: scopeOptions.map((scope) {
            final isSelected = _selectedScopes.contains(scope);
            return FilterChip(
              label: Text(_getLocalizedScope(scope, l10n)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedScopes.add(scope);
                  } else {
                    _selectedScopes.remove(scope);
                  }
                  _markDraftFromActive();
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        Text(
          l10n.type,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: typeOptions.map((type) {
            final isSelected = _selectedTypes.contains(type);
            return FilterChip(
              label: Text(_getLocalizedType(type, l10n)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTypes.add(type);
                  } else {
                    _selectedTypes.remove(type);
                  }
                  _markDraftFromActive();
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        Text(
          l10n.impact,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _isLoadingCatalogs
            ? const _ChipSkeletonRow()
            : Builder(
                builder: (context) {
                  final languageCode = context.select(
                    (LocaleCubit cubit) => cubit.state.languageCode,
                  );

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _impactOptions.map((impact) {
                      final impactName = impact['name'] as String;
                      final displayName = _getTranslatedName(
                        impact,
                        languageCode,
                      );
                      final isSelected = _selectedImpacts.contains(impactName);
                      return FilterChip(
                        label: Text(displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedImpacts.add(impactName);
                            } else {
                              _selectedImpacts.remove(impactName);
                            }
                            _markDraftFromActive();
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
        const SizedBox(height: 24),

        Text(
          l10n.severity,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _isLoadingCatalogs
            ? const _ChipSkeletonRow()
            : Builder(
                builder: (context) {
                  final languageCode = context.select(
                    (LocaleCubit cubit) => cubit.state.languageCode,
                  );

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _severityOptions.map((severity) {
                      final severityName = severity['name'] as String;
                      final displayName = _getTranslatedName(
                        severity,
                        languageCode,
                      );
                      final isSelected = _selectedSeverities.contains(
                        severityName,
                      );
                      return FilterChip(
                        label: Text(displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSeverities.add(severityName);
                            } else {
                              _selectedSeverities.remove(severityName);
                            }
                            _markDraftFromActive();
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
        const SizedBox(height: 24),

        Text(
          l10n.creationDateFilter,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            ...dateOptions.entries.map((entry) {
              final isSelected = _selectedCreationDateRange == entry.key;
              return Column(
                children: [
                  RadioListTile<String>(
                    value: entry.key,
                    groupValue: _selectedCreationDateRange,
                    title: Text(entry.value),
                    onChanged: (value) {
                      if (value == 'custom') {
                        _showCustomDateRangePicker(context, true);
                      } else {
                        setState(() {
                          _selectedCreationDateRange = value;
                          _customCreationDateRange = null;
                          _markDraftFromActive();
                        });
                      }
                    },
                  ),
                  if (entry.key == 'custom' &&
                      isSelected &&
                      _customCreationDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 56, bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${l10n.from}: ${DateFormat('MMM d, y - HH:mm').format(_customCreationDateRange!.start)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${l10n.to}: ${DateFormat('MMM d, y - HH:mm').format(_customCreationDateRange!.end)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () =>
                                  _showCustomDateRangePicker(context, true),
                              tooltip: l10n.changeDates,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          l10n.resolutionDateFilter,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            ...dateOptions.entries.map((entry) {
              final isSelected = _selectedResolutionDateRange == entry.key;
              return Column(
                children: [
                  RadioListTile<String>(
                    value: entry.key,
                    groupValue: _selectedResolutionDateRange,
                    title: Text(entry.value),
                    onChanged: (value) {
                      if (value == 'custom') {
                        _showCustomDateRangePicker(context, false);
                      } else {
                        setState(() {
                          _selectedResolutionDateRange = value;
                          _customResolutionDateRange = null;
                          _markDraftFromActive();
                        });
                      }
                    },
                  ),
                  if (entry.key == 'custom' &&
                      isSelected &&
                      _customResolutionDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 56, bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${l10n.from}: ${DateFormat('MMM d, y - HH:mm').format(_customResolutionDateRange!.start)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${l10n.to}: ${DateFormat('MMM d, y - HH:mm').format(_customResolutionDateRange!.end)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () =>
                                  _showCustomDateRangePicker(context, false),
                              tooltip: l10n.changeDates,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<TicketBloc, TicketState>(
      listenWhen: (prev, curr) {
        if (curr.filterQuery == null) return false;
        final sameQuery = _queriesEqual(curr.filterQuery, _lastHydratedQuery);
        final sameSource = curr.filterSourceId == _activeFilterSourceId;
        final sameLabel = curr.filterLabelKey == _activeFilterLabelKey;
        return !sameQuery || !sameSource || !sameLabel;
      },
      listener: (context, state) {
        if (state.filterQuery == null) return;
        setState(() {
          _setActiveFilter(
            state.filterQuery,
            sourceId:
                state.filterLabelKey == 'draft_filter'
                    ? null
                    : state.filterSourceId,
            draftSourceId:
                state.filterLabelKey == 'draft_filter'
                    ? state.filterSourceId
                    : null,
            labelKey: state.filterLabelKey,
            markHydrated: true,
          );
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.filterTickets,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF37414A),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // Only show clear filters button on Quick Filters tab
            if (_tabController.index == 1)
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  l10n.clearFilters,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: l10n.savedFilters, icon: const Icon(Icons.bookmark)),
              Tab(text: l10n.quickFilters, icon: const Icon(Icons.tune)),
            ],
          ),
        ),
        body: IndexedStack(
          index: _tabController.index,
          children: [_buildSavedFiltersTab(), _buildQuickFiltersTab()],
        ),
        bottomNavigationBar: _tabController.index == 1
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final canSave = _canSaveQuickFilter();
                            return OutlinedButton(
                              onPressed: canSave ? _saveQuickFilter : null,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                l10n.saveFilter,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyQuickFilters,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            l10n.applyFilters,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _SavedFiltersSkeletonList extends StatelessWidget {
  const _SavedFiltersSkeletonList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) => const _FilterSkeletonCard(),
      ),
    );
  }
}

class _FilterSkeletonCard extends StatelessWidget {
  const _FilterSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ShimmerBar(width: 160, height: 16),
            const SizedBox(height: 8),
            Row(
              children: const [
                _ShimmerBar(width: 80, height: 12),
                SizedBox(width: 12),
                _ShimmerBar(width: 60, height: 12),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                _ShimmerPill(width: 70),
                SizedBox(width: 8),
                _ShimmerPill(width: 90),
                SizedBox(width: 8),
                _ShimmerPill(width: 60),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipSkeletonRow extends StatelessWidget {
  const _ChipSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          _ShimmerPill(width: 90),
          _ShimmerPill(width: 70),
          _ShimmerPill(width: 80),
          _ShimmerPill(width: 60),
          _ShimmerPill(width: 100),
        ],
      ),
    );
  }
}

class _ShimmerPill extends StatelessWidget {
  const _ShimmerPill({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return _ShimmerBar(width: width, height: 28);
  }
}

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      tween: Tween(begin: 0.35, end: 0.75),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
