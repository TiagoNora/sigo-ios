import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../../styles/app_theme.dart';
import 'package:mime/mime.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/ticket.dart';
import '../../../core/di/injection.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../services/api_service.dart';
import '../../../blocs/locale_cubit.dart';
import '../../../domain/repositories/impact_severity_repository.dart';
import '../../../domain/repositories/catalog_repository.dart';

class CreateEditTicketScreen extends StatefulWidget {
  final Ticket? ticket;

  const CreateEditTicketScreen({super.key, this.ticket});

  @override
  State<CreateEditTicketScreen> createState() => _CreateEditTicketScreenState();
}

class _CreateEditTicketScreenState extends State<CreateEditTicketScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categorySearchController =
      TextEditingController();
  final TextEditingController _subcategorySearchController =
      TextEditingController();
  final TextEditingController _impactSearchController = TextEditingController();
  final TextEditingController _severitySearchController =
      TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ScrollController _stepScrollController = ScrollController();
  int _currentStep = 0;

  // Form data
  String? _externalReference; // Optional external reference
  String? _caseType; // INCIDENT or REQUEST
  String? _scope; // PERSONAL or TEAM
  String? _affectedItemType; // Equipment or Service
  Map<String, dynamic>? _selectedItem; // Selected equipment or service
  String? _selectedCategory; // Selected category name
  String? _selectedSubcategory; // Selected subcategory name
  String? _selectedImpact; // Selected impact name
  String? _selectedSeverity; // Selected severity name
  String _ticketTitle = ''; // Ticket title (required)
  String _ticketDescription = ''; // Ticket description (optional)
  List<PlatformFile> _selectedFiles = []; // Selected files for upload
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allEquipments =
      []; // All equipment loaded once at start
  List<Map<String, dynamic>> _allServices =
      []; // All services loaded once at start
  List<Map<String, dynamic>> _allCategories =
      []; // All categories loaded once at start
  List<Map<String, dynamic>> _allSubcategories =
      []; // All subcategories loaded once at start
  List<Map<String, dynamic>> _availableCategories =
      []; // Filtered categories for current selection
  List<Map<String, dynamic>> _availableSubcategories =
      []; // Filtered subcategories for current selection
  List<Map<String, dynamic>> _availableImpacts =
      []; // Available impacts from evaluate
  List<Map<String, dynamic>> _availableSeverities =
      []; // Available severities from evaluate
  List<Map<String, dynamic>> _filteredCategories =
      []; // Categories filtered by search
  List<Map<String, dynamic>> _filteredSubcategories =
      []; // Subcategories filtered by search
  List<Map<String, dynamic>> _filteredImpacts =
      []; // Impacts filtered by search
  List<Map<String, dynamic>> _filteredSeverities =
      []; // Severities filtered by search
  bool _isLoadingResults = false;
  bool _isLoadingCategories = false;
  bool _isLoadingSubcategories = false;
  bool _isLoadingImpacts = false;
  bool _isLoadingSeverities = false;
  final TextEditingController _externalReferenceController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load data asynchronously without blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    // Load all data in parallel
    await Future.wait([
      _loadAllCategories(),
      _loadAllSubcategories(),
      _loadAllEquipments(),
      _loadAllServices(),
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _categorySearchController.dispose();
    _subcategorySearchController.dispose();
    _impactSearchController.dispose();
    _severitySearchController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _stepScrollController.dispose();
    _externalReferenceController.dispose();
    super.dispose();
  }

  void _scrollToCurrentStep() {
    if (!_stepScrollController.hasClients) return;

    // Wait for the next frame to ensure layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_stepScrollController.hasClients) return;

      // Calculate scroll position to keep current step visible
      // Each step indicator is approximately 80 pixels wide (32px circle + 40px line + padding)
      final double stepWidth = 80.0;
      final double targetScroll = (_currentStep * stepWidth) - 50;

      // Get the max scroll extent
      final double maxScroll = _stepScrollController.position.maxScrollExtent;

      // Determine the final scroll position
      final double finalScroll;
      if (targetScroll <= 0) {
        finalScroll = 0;
      } else if (targetScroll >= maxScroll) {
        finalScroll = maxScroll;
      } else {
        finalScroll = targetScroll;
      }

      _stepScrollController.animateTo(
        finalScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _nextStep() {
    // Close keyboard when navigating to next step
    FocusScope.of(context).unfocus();

    if (_currentStep < 9) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _scrollToCurrentStep();

      // Load data asynchronously after UI renders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Load initial results when entering Step 5 (Select Item)
        if (_currentStep == 3) {
          _loadInitialResults();
        }

        // Load categories when entering Step 6 (Category)
        if (_currentStep == 4) {
          _loadCategories();
        }

        // Load subcategories when entering Step 7 (Subcategory)
        if (_currentStep == 5) {
          _loadSubcategories();
        }

        // Load impacts and severities when entering Step 8 (Impact)
        if (_currentStep == 6) {
          _loadImpactsAndSeverities();
        }
      });
    }
  }

  void _previousStep() {
    // Close keyboard when navigating to previous step
    FocusScope.of(context).unfocus();

    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _scrollToCurrentStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          l10n.createTicket,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF37414A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
          // Step indicator
          RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _stepScrollController,
                physics: const ClampingScrollPhysics(),
                child: Row(
                children: [
                  _buildStepIndicator(0, l10n.stepType),
                  _buildStepLine(0),
                  _buildStepIndicator(1, l10n.stepScope),
                  _buildStepLine(1),
                  _buildStepIndicator(2, l10n.stepItem),
                  _buildStepLine(2),
                  _buildStepIndicator(3, l10n.stepSelect),
                  _buildStepLine(3),
                  _buildStepIndicator(4, l10n.stepCategory),
                  _buildStepLine(4),
                  _buildStepIndicator(5, l10n.stepSubcategoryShort),
                  _buildStepLine(5),
                  _buildStepIndicator(6, l10n.stepImpact),
                  _buildStepLine(6),
                  _buildStepIndicator(7, l10n.stepUrgency),
                  _buildStepLine(7),
                  _buildStepIndicator(8, l10n.stepDetails),
                  _buildStepLine(8),
                  _buildStepIndicator(9, l10n.stepReview),
                ],
              ),
            ),
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildCaseTypeStep(),
                _buildScopeStep(),
                _buildAffectedItemStep(),
                _buildSelectItemStep(),
                _buildCategoryStep(),
                _buildSubcategoryStep(),
                _buildImpactStep(),
                _buildSeverityStep(),
                _buildDetailsStep(),
                _buildReviewStep(),
              ],
            ),
          ),

          // Navigation buttons
          RepaintBoundary(
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: _previousStep,
                        child: Text(l10n.previous),
                      )
                    else
                      const SizedBox(),
                    ElevatedButton(
                      onPressed: _canProceed()
                          ? (_currentStep < 9 ? _nextStep : _createTicket)
                          : null,
                      child: Text(
                        _currentStep < 9 ? l10n.next : l10n.createTicket,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.primary
                : isActive
                ? AppColors.primary
                : Colors.grey[300],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.primary : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
      color: isCompleted ? AppColors.primary : Colors.grey[300],
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _caseType != null;
      case 1:
        return _scope != null;
      case 2:
        return _affectedItemType != null;
      case 3:
        return _selectedItem != null;
      case 4:
        return _selectedCategory != null;
      case 5:
        return _selectedSubcategory != null;
      case 6:
        return _selectedImpact != null;
      case 7:
        return _selectedSeverity != null;
      case 8:
        return _ticketTitle.trim().isNotEmpty; // Title is required
      case 9:
        return true; // Review step, always can proceed to create
      default:
        return false;
    }
  }

  Widget _buildCaseTypeStep() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectType,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.chooseCaseTypeDescription,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          _buildOptionCard(
            title: l10n.incident,
            description: l10n.incidentOptionDescription,
            icon: Icons.warning_amber_rounded,
            isSelected: _caseType == 'INCIDENT',
            onTap: () {
              setState(() {
                _caseType = 'INCIDENT';
              });
              _nextStep();
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            title: l10n.request,
            description: l10n.requestOptionDescription,
            icon: Icons.help_outline_rounded,
            isSelected: _caseType == 'REQUEST',
            onTap: () {
              setState(() {
                _caseType = 'REQUEST';
              });
              _nextStep();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScopeStep() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectScope,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.chooseScopeDescription,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          _buildOptionCard(
            title: l10n.scopeIndividual,
            description: l10n.scopeIndividualDescription,
            icon: Icons.person,
            isSelected: _scope == 'PERSONAL',
            onTap: () {
              setState(() {
                _scope = 'PERSONAL';
              });
              _nextStep();
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            title: l10n.scopeTeam,
            description: l10n.scopeTeamDescription,
            icon: Icons.people,
            isSelected: _scope == 'TEAM',
            onTap: () {
              setState(() {
                _scope = 'TEAM';
              });
              _nextStep();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAffectedItemStep() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectAffectedItem,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.affectedItemDescription,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          _buildOptionCard(
            title: l10n.service,
            description: l10n.serviceOptionDescription,
            icon: Icons.cloud_outlined,
            isSelected: _affectedItemType == 'Service',
            onTap: () {
              setState(() {
                _affectedItemType = 'Service';
              });
              _nextStep();
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            title: l10n.equipment,
            description: l10n.equipmentOptionDescription,
            icon: Icons.computer,
            isSelected: _affectedItemType == 'Equipment',
            onTap: () {
              setState(() {
                _affectedItemType = 'Equipment';
              });
              _nextStep();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectItemStep() {
    final l10n = AppLocalizations.of(context);
    final itemTitle = _affectedItemType == 'Equipment'
        ? l10n.selectEquipmentTitle
        : _affectedItemType == 'Service'
        ? l10n.selectServiceTitle
        : l10n.selectItemTitleGeneric;
    final itemSubtitle = _affectedItemType == 'Equipment'
        ? l10n.selectEquipmentSubtitle
        : _affectedItemType == 'Service'
        ? l10n.selectServiceSubtitle
        : l10n.selectItemSubtitleGeneric;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itemTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            itemSubtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _affectedItemType == 'Equipment'
                  ? l10n.searchEquipment
                  : l10n.searchService,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadInitialResults();
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              _performSearch(value);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingResults
                ? Center(
                    child: LoadingAnimationWidget.threeRotatingDots(
                      color: const Color(0xFF37414A),
                      size: 40,
                    ),
                  )
                : _searchResults.isEmpty
                ? Center(
                    child: Text(
                      l10n.noResultsFound,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      final isEquipment = _affectedItemType == 'Equipment';
                      final displayName = isEquipment
                          ? '${item['name']} (${item['type']})'
                          : '${item['name']} (${item['serviceType']})';
                      final isSelected = _selectedItem == item;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(displayName),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : null,
                          selected: isSelected,
                          selectedTileColor: const Color(0xFFD4F4F1),
                          onTap: () {
                            setState(() {
                              _selectedItem = item;
                            });
                            _nextStep();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadInitialResults() async {
    setState(() {
      _isLoadingResults = true;
    });

    try {
      debugPrint('Loading initial results for: $_affectedItemType');

      // Use cached data instead of making API call
      final cachedResults = _affectedItemType == 'Equipment'
          ? _allEquipments
          : _allServices;

      debugPrint('Using cached results: ${cachedResults.length} items');

      setState(() {
        _searchResults = cachedResults;
        _isLoadingResults = false;
      });
    } catch (e) {
      debugPrint('Error loading initial results: $e');
      setState(() {
        _searchResults = [];
        _isLoadingResults = false;
      });
    }
  }

  Future<void> _loadAllCategories() async {
    try {
      final authRepository = getIt<AuthRepository>();
      final apiService = ApiService(
        authRepository.accessToken!,
        baseUrl: authRepository.tenantConfig?.baseUrl ?? "",
        authService: authRepository,
      );

      debugPrint('Loading all categories...');
      final categories = await apiService.getCategories();

      if (mounted) {
        setState(() {
          _allCategories = List<Map<String, dynamic>>.from(categories);
        });
      }

      debugPrint('Loaded ${_allCategories.length} categories');
    } catch (e) {
      debugPrint('Error loading all categories: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLoadingCategories),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAllSubcategories() async {
    try {
      final authRepository = getIt<AuthRepository>();
      final apiService = ApiService(
        authRepository.accessToken!,
        baseUrl: authRepository.tenantConfig?.baseUrl ?? "",
        authService: authRepository,
      );

      debugPrint('Loading all subcategories...');
      final subcategories = await apiService.getSubcategories();

      if (mounted) {
        setState(() {
          _allSubcategories = List<Map<String, dynamic>>.from(subcategories);
        });
      }

      debugPrint('Loaded ${_allSubcategories.length} subcategories');
    } catch (e) {
      debugPrint('Error loading all subcategories: $e');
    }
  }

  Future<void> _loadAllEquipments() async {
    try {
      final authRepository = getIt<AuthRepository>();
      final apiService = ApiService(
        authRepository.accessToken!,
        baseUrl: authRepository.tenantConfig?.baseUrl ?? "",
        authService: authRepository,
      );

      debugPrint('Loading all equipments...');
      final response = await apiService.searchCIS(
        isEquipment: true,
        searchQuery: '',
      );

      if (mounted) {
        setState(() {
          _allEquipments = List<Map<String, dynamic>>.from(
            response['results'] ?? [],
          );
        });
      }

      debugPrint('Loaded ${_allEquipments.length} equipments');
    } catch (e) {
      debugPrint('Error loading all equipments: $e');
    }
  }

  Future<void> _loadAllServices() async {
    try {
      final authRepository = getIt<AuthRepository>();
      final apiService = ApiService(
        authRepository.accessToken!,
        baseUrl: authRepository.tenantConfig?.baseUrl ?? "",
        authService: authRepository,
      );

      debugPrint('Loading all services...');
      final response = await apiService.searchCIS(
        isEquipment: false,
        searchQuery: '',
      );

      if (mounted) {
        setState(() {
          _allServices = List<Map<String, dynamic>>.from(
            response['results'] ?? [],
          );
        });
      }

      debugPrint('Loaded ${_allServices.length} services');
    } catch (e) {
      debugPrint('Error loading all services: $e');
    }
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final authRepository = getIt<AuthRepository>();
      final apiService = ApiService(
        authRepository.accessToken!,
        baseUrl: authRepository.tenantConfig?.baseUrl ?? "",
        authService: authRepository,
      );
      final languageCode = context.read<LocaleCubit>().state.languageCode;

      // Build evaluate request body
      Map<String, dynamic> evaluateBody = {
        'externalId': _externalReference ?? '',
        'type': _caseType,
        'scope': _scope,
        'affectedItem': _affectedItemType?.toLowerCase(),
        'createdByTeam': 'Mobile app',
      };

      // Add service types or CI types based on affected item type
      if (_affectedItemType == 'Service') {
        evaluateBody['serviceTypes'] = [_selectedItem!['serviceType']];
      } else {
        evaluateBody['ciTypes'] = _selectedItem;
      }

      debugPrint('Evaluate body: ${json.encode(evaluateBody)}');

      // Call evaluate endpoint
      final evaluateResult = await apiService.evaluateTicket(evaluateBody);
      final categoryNames = List<String>.from(
        evaluateResult['categories'] ?? [],
      );

      debugPrint('Categories from evaluate: $categoryNames');

      // Map category names to full category objects with translations from cached _allCategories
      // Filter out items with enabled: false or apiOnly: true
      final mappedCategories = categoryNames
          .map((categoryName) {
            final category = _allCategories.firstWhere(
              (cat) => cat['name'] == categoryName,
              orElse: () => {'name': categoryName, 'translations': {}},
            );

            final translations =
                category['translations'] as Map<String, dynamic>? ?? {};
            final translation = translations[languageCode] as String?;
            final displayName = (translation == null || translation.isEmpty)
                ? categoryName
                : translation;

            return {
              'name': categoryName,
              'displayName': displayName,
              'translations': translations,
              'enabled': category['enabled'] ?? true,
              'apiOnly': category['apiOnly'] ?? false,
            };
          })
          .where((category) {
            final enabled = category['enabled'] as bool? ?? true;
            final apiOnly = category['apiOnly'] as bool? ?? false;
            return enabled && !apiOnly;
          })
          .toList();

      // Sort alphabetically by display name (case-insensitive)
      mappedCategories.sort(
        (a, b) => (a['displayName'] as String).toLowerCase().compareTo(
          (b['displayName'] as String).toLowerCase(),
        ),
      );

      debugPrint('Mapped categories: ${mappedCategories.length}');

      if (!mounted) return;

      setState(() {
        _availableCategories = mappedCategories;
        _filteredCategories =
            mappedCategories; // Initialize filtered with all categories
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');

      if (!mounted) return;

      setState(() {
        _availableCategories = [];
        _isLoadingCategories = false;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLoadingCategories),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSubcategories() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSubcategories = true;
    });

    try {
      final authRepository = getIt<AuthRepository>();
      final apiService = ApiService(
        authRepository.accessToken!,
        baseUrl: authRepository.tenantConfig?.baseUrl ?? "",
        authService: authRepository,
      );
      final languageCode = context.read<LocaleCubit>().state.languageCode;

      // Build evaluate request body with category
      Map<String, dynamic> evaluateBody = {
        'externalId': _externalReference ?? '',
        'type': _caseType,
        'scope': _scope,
        'affectedItem': _affectedItemType?.toLowerCase(),
        'category': _selectedCategory,
        'createdByTeam': 'Mobile app',
      };

      // Add service types or CI types based on affected item type
      if (_affectedItemType == 'Service') {
        evaluateBody['serviceTypes'] = [_selectedItem!['serviceType']];
      } else {
        evaluateBody['ciTypes'] = _selectedItem;
      }

      debugPrint(
        'Evaluate body for subcategories: ${json.encode(evaluateBody)}',
      );

      // Call evaluate endpoint
      final evaluateResult = await apiService.evaluateTicket(evaluateBody);
      final subcategoryNames = List<String>.from(
        evaluateResult['subcategories'] ?? [],
      );

      debugPrint('Subcategories from evaluate: $subcategoryNames');

      // Map subcategory names to full subcategory objects with translations from cached _allSubcategories
      // Filter out items with enabled: false or apiOnly: true
      final mappedSubcategories = subcategoryNames
          .map((subcategoryName) {
            final subcategory = _allSubcategories.firstWhere(
              (subcat) => subcat['name'] == subcategoryName,
              orElse: () => {'name': subcategoryName, 'translations': {}},
            );

            final translations =
                subcategory['translations'] as Map<String, dynamic>? ?? {};
            final translation = translations[languageCode] as String?;
            final displayName = (translation == null || translation.isEmpty)
                ? subcategoryName
                : translation;

            return {
              'name': subcategoryName,
              'displayName': displayName,
              'translations': translations,
              'enabled': subcategory['enabled'] ?? true,
              'apiOnly': subcategory['apiOnly'] ?? false,
            };
          })
          .where((subcategory) {
            final enabled = subcategory['enabled'] as bool? ?? true;
            final apiOnly = subcategory['apiOnly'] as bool? ?? false;
            return enabled && !apiOnly;
          })
          .toList();

      // Sort alphabetically by display name (case-insensitive)
      mappedSubcategories.sort(
        (a, b) => (a['displayName'] as String).toLowerCase().compareTo(
          (b['displayName'] as String).toLowerCase(),
        ),
      );

      debugPrint('Mapped subcategories: ${mappedSubcategories.length}');

      if (!mounted) return;

      setState(() {
        _availableSubcategories = mappedSubcategories;
        _filteredSubcategories =
            mappedSubcategories; // Initialize filtered with all subcategories
        _isLoadingSubcategories = false;
      });
    } catch (e) {
      debugPrint('Error loading subcategories: $e');

      if (!mounted) return;

      setState(() {
        _availableSubcategories = [];
        _filteredSubcategories = [];
        _isLoadingSubcategories = false;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLoadingSubcategories),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _availableCategories;
      } else {
        _filteredCategories = _availableCategories.where((category) {
          final displayName = (category['displayName'] as String).toLowerCase();
          final name = (category['name'] as String).toLowerCase();
          final searchQuery = query.toLowerCase();
          return displayName.contains(searchQuery) ||
              name.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _filterSubcategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSubcategories = _availableSubcategories;
      } else {
        _filteredSubcategories = _availableSubcategories.where((subcategory) {
          final displayName = (subcategory['displayName'] as String)
              .toLowerCase();
          final name = (subcategory['name'] as String).toLowerCase();
          final searchQuery = query.toLowerCase();
          return displayName.contains(searchQuery) ||
              name.contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _loadImpactsAndSeverities() async {
    if (!mounted) return;

    setState(() {
      _isLoadingImpacts = true;
      _isLoadingSeverities = true;
    });

    try {
      final authRepository = getIt<AuthRepository>();
      final apiService = ApiService(
        authRepository.accessToken!,
        baseUrl: authRepository.tenantConfig?.baseUrl ?? "",
        authService: authRepository,
      );
      final languageCode = context.read<LocaleCubit>().state.languageCode;

      // Build evaluate request body with category and subcategory
      Map<String, dynamic> evaluateBody = {
        'externalId': _externalReference ?? '',
        'type': _caseType,
        'scope': _scope,
        'affectedItem': _affectedItemType?.toLowerCase(),
        'category': _selectedCategory,
        'subcategory': _selectedSubcategory,
        'createdByTeam': 'Mobile app',
      };

      // Add service types or CI types based on affected item type
      if (_affectedItemType == 'Service') {
        evaluateBody['serviceTypes'] = [_selectedItem!['serviceType']];
      } else {
        evaluateBody['ciTypes'] = _selectedItem;
      }

      debugPrint(
        'Evaluate body for impacts/severities: ${json.encode(evaluateBody)}',
      );

      // Call evaluate endpoint
      final evaluateResult = await apiService.evaluateTicket(evaluateBody);
      final impactsData = evaluateResult['impacts'] as List<dynamic>? ?? [];
      final severitiesData =
          evaluateResult['severities'] as List<dynamic>? ?? [];

      debugPrint('Impacts from evaluate: ${impactsData.length}');
      debugPrint('Severities from evaluate: ${severitiesData.length}');

      // Process impacts - filter out apiOnly=true, keep enabled=false, sort by level
      final mappedImpacts = impactsData
          .map((impact) {
            final translations =
                impact['translations'] as Map<String, dynamic>? ?? {};
            final translation = translations[languageCode] as String?;
            final displayName = (translation == null || translation.isEmpty)
                ? impact['name']
                : translation;

            return {
              'name': impact['name'],
              'displayName': displayName,
              'translations': translations,
              'color': impact['color'],
              'level': impact['level'] ?? 0,
              'apiOnly': impact['apiOnly'] ?? false,
            };
          })
          .where((impact) {
            final apiOnly = impact['apiOnly'] as bool? ?? false;
            return !apiOnly;
          })
          .toList();

      // Sort by level (low to high)
      mappedImpacts.sort(
        (a, b) => (a['level'] as int).compareTo(b['level'] as int),
      );

      // Process severities - same logic
      final mappedSeverities = severitiesData
          .map((severity) {
            final translations =
                severity['translations'] as Map<String, dynamic>? ?? {};
            final translation = translations[languageCode] as String?;
            final displayName = (translation == null || translation.isEmpty)
                ? severity['name']
                : translation;

            return {
              'name': severity['name'],
              'displayName': displayName,
              'translations': translations,
              'color': severity['color'],
              'level': severity['level'] ?? 0,
              'apiOnly': severity['apiOnly'] ?? false,
            };
          })
          .where((severity) {
            final apiOnly = severity['apiOnly'] as bool? ?? false;
            return !apiOnly;
          })
          .toList();

      // Sort by level (low to high)
      mappedSeverities.sort(
        (a, b) => (a['level'] as int).compareTo(b['level'] as int),
      );

      debugPrint('Mapped impacts: ${mappedImpacts.length}');
      debugPrint('Mapped severities: ${mappedSeverities.length}');

      if (!mounted) return;

      setState(() {
        _availableImpacts = mappedImpacts;
        _availableSeverities = mappedSeverities;
        _filteredImpacts = mappedImpacts;
        _filteredSeverities = mappedSeverities;
        _isLoadingImpacts = false;
        _isLoadingSeverities = false;
      });
    } catch (e) {
      debugPrint('Error loading impacts and severities: $e');

      if (!mounted) return;

      setState(() {
        _availableImpacts = [];
        _availableSeverities = [];
        _filteredImpacts = [];
        _filteredSeverities = [];
        _isLoadingImpacts = false;
        _isLoadingSeverities = false;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLoadingImpactsAndSeverities),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterImpacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredImpacts = _availableImpacts;
      } else {
        _filteredImpacts = _availableImpacts.where((impact) {
          final displayName = (impact['displayName'] as String).toLowerCase();
          final name = (impact['name'] as String).toLowerCase();
          final searchQuery = query.toLowerCase();
          return displayName.contains(searchQuery) ||
              name.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _filterSeverities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSeverities = _availableSeverities;
      } else {
        _filteredSeverities = _availableSeverities.where((severity) {
          final displayName = (severity['displayName'] as String).toLowerCase();
          final name = (severity['name'] as String).toLowerCase();
          final searchQuery = query.toLowerCase();
          return displayName.contains(searchQuery) ||
              name.contains(searchQuery);
        }).toList();
      }
    });
  }

  Widget _buildCategoryStep() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectCategory,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.chooseCategoryDescription,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _categorySearchController,
            decoration: InputDecoration(
              hintText: l10n.searchCategories,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _categorySearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _categorySearchController.clear();
                        _filterCategories('');
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              _filterCategories(value);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingCategories
                ? Center(
                    child: LoadingAnimationWidget.threeRotatingDots(
                      color: const Color(0xFF37414A),
                      size: 40,
                    ),
                  )
                : _filteredCategories.isEmpty
                ? Center(
                    child: Text(
                      _categorySearchController.text.isNotEmpty
                          ? l10n.noResultsFound
                          : l10n.noCategoriesAvailable,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = _filteredCategories[index];
                      final categoryName = category['name'] as String;
                      final displayName = category['displayName'] as String;
                      final isSelected = _selectedCategory == categoryName;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(displayName),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : null,
                          selected: isSelected,
                          selectedTileColor: const Color(0xFFD4F4F1),
                          onTap: () {
                            setState(() {
                              _selectedCategory = categoryName;
                            });
                            _nextStep();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryStep() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectSubcategory,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.chooseSubcategoryDescription,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _subcategorySearchController,
            decoration: InputDecoration(
              hintText: l10n.searchSubcategories,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _subcategorySearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _subcategorySearchController.clear();
                        _filterSubcategories('');
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              _filterSubcategories(value);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingSubcategories
                ? Center(
                    child: LoadingAnimationWidget.threeRotatingDots(
                      color: const Color(0xFF37414A),
                      size: 40,
                    ),
                  )
                : _filteredSubcategories.isEmpty
                ? Center(
                    child: Text(
                      _subcategorySearchController.text.isNotEmpty
                          ? l10n.noResultsFound
                          : l10n.noSubcategoriesAvailable,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredSubcategories.length,
                    itemBuilder: (context, index) {
                      final subcategory = _filteredSubcategories[index];
                      final subcategoryName = subcategory['name'] as String;
                      final displayName = subcategory['displayName'] as String;
                      final isSelected =
                          _selectedSubcategory == subcategoryName;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(displayName),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : null,
                          selected: isSelected,
                          selectedTileColor: const Color(0xFFD4F4F1),
                          onTap: () {
                            setState(() {
                              _selectedSubcategory = subcategoryName;
                            });
                            _nextStep();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStep() {
    final l10n = AppLocalizations.of(context);
    final impactSeverityService = getIt<ImpactSeverityRepository>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.impact,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.chooseImpactDescription,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _impactSearchController,
            decoration: InputDecoration(
              hintText: l10n.searchImpacts,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _impactSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _impactSearchController.clear();
                        _filterImpacts('');
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              _filterImpacts(value);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingImpacts
                ? Center(
                    child: LoadingAnimationWidget.threeRotatingDots(
                      color: const Color(0xFF37414A),
                      size: 40,
                    ),
                  )
                : _filteredImpacts.isEmpty
                ? Center(
                    child: Text(
                      l10n.noResultsFound,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredImpacts.length,
                    itemBuilder: (context, index) {
                      final impact = _filteredImpacts[index];
                      final impactName = impact['name'] as String;
                      final displayName = impact['displayName'] as String;
                      final colorString = impact['color'] as String?;
                      final color = impactSeverityService.parseColor(
                        colorString,
                      );
                      final isSelected = _selectedImpact == impactName;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.3),
                              border: Border.all(color: color),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          title: Text(displayName),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : null,
                          selected: isSelected,
                          selectedTileColor: const Color(0xFFD4F4F1),
                          onTap: () {
                            setState(() {
                              _selectedImpact = impactName;
                            });
                            _nextStep();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityStep() {
    final l10n = AppLocalizations.of(context);
    final impactSeverityService = getIt<ImpactSeverityRepository>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.urgency,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.chooseUrgencyDescription,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _severitySearchController,
            decoration: InputDecoration(
              hintText: l10n.searchSeverities,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _severitySearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _severitySearchController.clear();
                        _filterSeverities('');
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              _filterSeverities(value);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingSeverities
                ? Center(
                    child: LoadingAnimationWidget.threeRotatingDots(
                      color: const Color(0xFF37414A),
                      size: 40,
                    ),
                  )
                : _filteredSeverities.isEmpty
                ? Center(
                    child: Text(
                      l10n.noResultsFound,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredSeverities.length,
                    itemBuilder: (context, index) {
                      final severity = _filteredSeverities[index];
                      final severityName = severity['name'] as String;
                      final displayName = severity['displayName'] as String;
                      final colorString = severity['color'] as String?;
                      final color = impactSeverityService.parseColor(
                        colorString,
                      );
                      final isSelected = _selectedSeverity == severityName;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.3),
                              border: Border.all(color: color),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          title: Text(displayName),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : null,
                          selected: isSelected,
                          selectedTileColor: const Color(0xFFD4F4F1),
                          onTap: () {
                            setState(() {
                              _selectedSeverity = severityName;
                            });
                            _nextStep();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: false, // Use paths instead of loading data into memory
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
        debugPrint('${result.files.length} file(s) selected');
        for (final file in result.files) {
          debugPrint(
            'File: ${file.name}, Path: ${file.path}, Size: ${file.size}',
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorSelectingFiles),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _createTicket() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: LoadingAnimationWidget.threeRotatingDots(
            color: const Color(0xFF37414A),
            size: 50,
          ),
        ),
      );

      final authRepository = getIt<AuthRepository>();
      final apiService = ApiService(
        authRepository.accessToken!,
        baseUrl: authRepository.tenantConfig?.baseUrl ?? "",
        authService: authRepository,
      );

      // Get user's default team
      final defaultTeam =
          authRepository.currentUser?.config?.onecarePersonalConfig?.defaultTeam ??
          'Mobile app';

      // Build ticket payload
      Map<String, dynamic> ticketData = {
        'category': _selectedCategory,
        'externalId': _externalReference ?? '',
        'subcategory': _selectedSubcategory,
        'type': _caseType,
        'scope': _scope,
        'description': _ticketDescription.isEmpty ? null : _ticketDescription,
        'impact': _selectedImpact,
        'severity': _selectedSeverity,
        'name': _ticketTitle,
        'createdByTeam': defaultTeam,
      };

      // Add CIS or services based on affected item type
      if (_affectedItemType == 'Equipment') {
        ticketData['cis'] = [_selectedItem];
        ticketData['ciType'] = _selectedItem!['type'];
        ticketData['services'] = null;
        ticketData['serviceTypes'] = null;
      } else {
        ticketData['cis'] = null;
        ticketData['ciType'] = null;
        ticketData['services'] = [_selectedItem!['uniqueId']];
        ticketData['serviceTypes'] = [_selectedItem!['serviceType']];
      }

      // Handle attachments - build metadata array for selected files
      if (_selectedFiles.isNotEmpty) {
        ticketData['attachments'] = _selectedFiles.map((file) {
          // Detect MIME type from file extension
          // Supports: images (jpg, png, gif), documents (pdf, doc, docx, xls, xlsx),
          // text files (txt, json, xml, csv), archives (zip, rar), and more
          final mimeType =
              lookupMimeType(file.name) ?? 'application/octet-stream';

          debugPrint('File: ${file.name} -> MIME type: $mimeType');

          return {
            'name': file.name,
            'description': file.name,
            'attachmentType': mimeType,
            'visibleToTeam': null,
          };
        }).toList();
      } else {
        ticketData['attachments'] = null;
      }

      debugPrint('Creating ticket with payload: ${json.encode(ticketData)}');
      debugPrint('Number of files to upload: ${_selectedFiles.length}');

      // Create ticket via API with files
      final response = await apiService.createTicket(
        ticketData,
        files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
      );

      // Dismiss loading dialog
      if (mounted) Navigator.of(context).pop();

      debugPrint('Ticket created successfully: $response');

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).ticketCreatedSuccessfully,
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home with success result
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Dismiss loading dialog
      if (mounted) Navigator.of(context).pop();

      debugPrint('Error creating ticket: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).failedToCreateTicket),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildReviewStep() {
    final localeCode = context.select(
      (LocaleCubit cubit) => cubit.state.languageCode,
    );
    final catalogService = getIt<CatalogRepository>();
    final l10n = AppLocalizations.of(context);

    // Get display names with translations
    final categoryDisplay =
        catalogService
            .getCategoryByName(_selectedCategory ?? '')
            ?.getTranslation(localeCode) ??
        _selectedCategory ??
        '';
    final subcategoryDisplay =
        catalogService
            .getSubcategoryByName(_selectedSubcategory ?? '')
            ?.getTranslation(localeCode) ??
        _selectedSubcategory ??
        '';
    final typeDisplay = _caseType == 'INCIDENT'
        ? l10n.incident
        : _caseType == 'REQUEST'
        ? l10n.request
        : '';
    final scopeDisplay = _scope == 'PERSONAL'
        ? l10n.scopeIndividual
        : _scope == 'TEAM'
        ? l10n.scopeTeam
        : '';
    final impactDisplay = _selectedImpact == null
        ? ''
        : (_availableImpacts.firstWhere(
                    (impact) => impact['name'] == _selectedImpact,
                    orElse: () => <String, dynamic>{},
                  )['displayName']
                  as String? ??
              _selectedImpact!);
    final severityDisplay = _selectedSeverity == null
        ? ''
        : (_availableSeverities.firstWhere(
                    (severity) => severity['name'] == _selectedSeverity,
                    orElse: () => <String, dynamic>{},
                  )['displayName']
                  as String? ??
              _selectedSeverity!);
    final affectedItemLabel = _affectedItemType == 'Equipment'
        ? l10n.equipment
        : _affectedItemType == 'Service'
        ? l10n.service
        : l10n.affectedItem;
    final affectedItemValue = _affectedItemType == 'Equipment'
        ? '${_selectedItem?['name']} (${_selectedItem?['type']})'
        : '${_selectedItem?['name']} (${_selectedItem?['serviceType']})';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reviewTicket,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reviewAllInformation,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // External Reference (if provided)
            if (_externalReference != null &&
                _externalReference!.isNotEmpty) ...[
              _buildReviewCard(l10n.externalReference, _externalReference!),
              const SizedBox(height: 12),
            ],

            // Type & Scope
            _buildReviewCard(l10n.caseType, typeDisplay),
            const SizedBox(height: 12),
            _buildReviewCard(l10n.scope, scopeDisplay),
            const SizedBox(height: 12),

            // Affected Item
            _buildReviewCard(affectedItemLabel, affectedItemValue),
            const SizedBox(height: 12),

            // Category & Subcategory
            _buildReviewCard(l10n.category, categoryDisplay),
            const SizedBox(height: 12),
            _buildReviewCard(l10n.subcategory, subcategoryDisplay),
            const SizedBox(height: 12),

            // Impact & Urgency
            _buildReviewCard(l10n.impact, impactDisplay),
            const SizedBox(height: 12),
            _buildReviewCard(l10n.urgency, severityDisplay),
            const SizedBox(height: 12),

            // Title & Description
            _buildReviewCard(l10n.title, _ticketTitle),
            const SizedBox(height: 12),
            if (_ticketDescription.isNotEmpty) ...[
              _buildReviewCard(l10n.description, _ticketDescription),
              const SizedBox(height: 12),
            ],

            // Attachments
            if (_selectedFiles.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.attachments,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...(_selectedFiles
                          .map(
                            (file) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.insert_drive_file,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      file.name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    '${(file.size / 1024).toStringAsFixed(2)} KB',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList()),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.ticketDetails,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.provideDetailsAndAttachments,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Title field (required)
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.titleRequired,
                hintText: l10n.enterTicketTitle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
              maxLines: 1,
              onChanged: (value) {
                setState(() {
                  _ticketTitle = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Description field (optional)
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.descriptionOptional,
                hintText: l10n.enterTicketDescription,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              onChanged: (value) {
                setState(() {
                  _ticketDescription = value;
                });
              },
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _externalReferenceController,
              decoration: InputDecoration(
                labelText: l10n.externalReferenceOptional,
                hintText: l10n.externalReferenceHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                prefixIcon: const Icon(Icons.link),
                suffixIcon: _externalReferenceController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _externalReferenceController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _externalReference = value.isNotEmpty ? value : null;
                });
              },
            ),
            const SizedBox(height: 24),

            // File attachments section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.attachments,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.attach_file),
                  label: Text(l10n.addFiles),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selected files list
            if (_selectedFiles.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.noFilesSelectedMessage,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) {
                  final file = _selectedFiles[index];
                  final fileName = file.name;
                  final fileSize = file.size;
                  final fileSizeKB = (fileSize / 1024).toStringAsFixed(2);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(
                        Icons.insert_drive_file,
                        color: AppColors.primary,
                      ),
                      title: Text(fileName),
                      subtitle: Text('$fileSizeKB KB'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeFile(index),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _performSearch(String query) async {
    // If query is empty, use cached data
    if (query.isEmpty) {
      _loadInitialResults();
      return;
    }

    setState(() {
      _isLoadingResults = true;
    });

    try {
      final authRepository = getIt<AuthRepository>();
      final apiService = ApiService(
        authRepository.accessToken!,
        baseUrl: authRepository.tenantConfig?.baseUrl ?? "",
        authService: authRepository,
      );

      debugPrint('Searching for: $query');
      final response = await apiService.searchCIS(
        isEquipment: _affectedItemType == 'Equipment',
        searchQuery: query,
      );

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(
          response['results'] ?? [],
        );
        _isLoadingResults = false;
      });
    } catch (e) {
      debugPrint('Error searching CIS: $e');
      setState(() {
        _searchResults = [];
        _isLoadingResults = false;
      });
    }
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        // Close keyboard when selecting an option
        FocusScope.of(context).unfocus();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFFD4F4F1) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
