import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../models/category.dart';
import '../../models/subcategory.dart';
import '../../services/api_service.dart';
import '../../services/network_exception.dart';
import '../../services/connectivity_service.dart';

/// Implementation of CatalogRepository.
///
/// Handles loading and caching of categories and subcategories.
@Singleton(as: CatalogRepository)
class CatalogRepositoryImpl implements CatalogRepository {
  final AuthRepository _authRepository;

  List<Category> _categories = [];
  List<Subcategory> _subcategories = [];
  bool _isLoading = false;
  String? _error;

  CatalogRepositoryImpl(this._authRepository);

  @override
  Future<void> loadCatalogs() async {
    if (_categories.isNotEmpty && _subcategories.isNotEmpty) return; // Already loaded

    // Check authentication before making API calls
    if (!_authRepository.isAuthenticated) {
      debugPrint(
          'Cannot load catalogs: user not authenticated - triggering logout');
      await _authRepository.logout();
      return;
    }

    _isLoading = true;
    _error = null;

    try {
      final baseUrl = _authRepository.tenantConfig?.baseUrl;
      final accessToken = _authRepository.accessToken;

      if (baseUrl == null || accessToken == null) {
        throw Exception('Missing baseUrl or accessToken');
      }

      final apiService = ApiService(
        accessToken,
        baseUrl: baseUrl,
        authService: _authRepository,
      );

      // Load categories and subcategories in parallel
      final results = await Future.wait<List<dynamic>>([
        apiService.getCategories(),
        apiService.getSubcategories(),
      ]);

      _categories = (results[0] as List<dynamic>)
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .where((category) => category.enabled)
          .toList();

      _subcategories = (results[1] as List<dynamic>)
          .map((json) => Subcategory.fromJson(json as Map<String, dynamic>))
          .where((subcategory) => subcategory.enabled)
          .toList();

      debugPrint(
          'Loaded ${_categories.length} categories and ${_subcategories.length} subcategories');

      _isLoading = false;
    } on NetworkException {
      ConnectivityService.instance?.markOffline();
      _error = null;
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('Error loading catalogs: $e');
    }
  }

  @override
  Category? getCategoryByName(String name) {
    try {
      return _categories.firstWhere(
        (category) => category.name.toUpperCase() == name.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Subcategory? getSubcategoryByName(String name) {
    try {
      return _subcategories.firstWhere(
        (subcategory) => subcategory.name.toUpperCase() == name.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  List<Category> get categories => _categories;

  @override
  List<Subcategory> get subcategories => _subcategories;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;
}
