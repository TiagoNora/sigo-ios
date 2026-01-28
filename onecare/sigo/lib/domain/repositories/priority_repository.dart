import 'package:flutter/material.dart';
import '../../models/priority.dart';

/// Abstract repository for priority operations.
/// Defines the contract for loading and querying priority data.
abstract class PriorityRepository {
  /// Load priorities from the API.
  ///
  /// This method caches the results and skips loading if already loaded.
  /// Uses injected AuthRepository for authentication.
  Future<void> loadPriorities();

  /// Get a priority by its name.
  ///
  /// [name] - The priority name (case-insensitive)
  ///
  /// Returns the priority if found, null otherwise.
  Priority? getPriorityByName(String name);

  /// Parse a color string (hex or rgba format) into a Color object.
  ///
  /// [colorString] - The color string to parse (e.g., "#14da1c" or "rgba(246,64,25,0.92)")
  ///
  /// Returns the parsed Color or Colors.grey if parsing fails.
  Color parseColor(String? colorString);

  /// Get all loaded priorities.
  List<Priority> get priorities;

  /// Check if priorities are currently being loaded.
  bool get isLoading;

  /// Get the last error that occurred during loading.
  String? get error;
}
