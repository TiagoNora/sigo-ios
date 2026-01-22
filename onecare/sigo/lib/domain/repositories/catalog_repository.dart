import '../../models/category.dart';
import '../../models/subcategory.dart';

/// Abstract repository for catalog operations (categories and subcategories).
/// Defines the contract for loading and querying catalog data.
abstract class CatalogRepository {
  /// Load categories and subcategories from the API.
  ///
  /// This method caches the results and skips loading if already loaded.
  /// Uses injected AuthRepository for authentication.
  Future<void> loadCatalogs();

  /// Get a category by its name.
  ///
  /// [name] - The category name (case-insensitive)
  ///
  /// Returns the category if found, null otherwise.
  Category? getCategoryByName(String name);

  /// Get a subcategory by its name.
  ///
  /// [name] - The subcategory name (case-insensitive)
  ///
  /// Returns the subcategory if found, null otherwise.
  Subcategory? getSubcategoryByName(String name);

  /// Get all loaded categories.
  List<Category> get categories;

  /// Get all loaded subcategories.
  List<Subcategory> get subcategories;

  /// Check if catalogs are currently being loaded.
  bool get isLoading;

  /// Get the last error that occurred during loading.
  String? get error;
}
