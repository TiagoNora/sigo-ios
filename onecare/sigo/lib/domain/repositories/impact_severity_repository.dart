import 'package:flutter/material.dart';
import '../../models/impact.dart';
import '../../models/severity.dart';

/// Abstract repository for impact and severity operations.
/// Defines the contract for loading and querying impact and severity data.
abstract class ImpactSeverityRepository {
  /// Load impacts and severities from the API.
  ///
  /// This method caches the results and skips loading if already loaded.
  /// Uses injected AuthRepository for authentication.
  Future<void> loadImpactsAndSeverities();

  /// Get an impact by its name.
  ///
  /// [name] - The impact name (case-insensitive)
  ///
  /// Returns the impact if found, null otherwise.
  Impact? getImpactByName(String name);

  /// Get a severity by its name.
  ///
  /// [name] - The severity name (case-insensitive)
  ///
  /// Returns the severity if found, null otherwise.
  Severity? getSeverityByName(String name);

  /// Parse a color string (hex or rgba format) into a Color object.
  ///
  /// [colorString] - The color string to parse (e.g., "#14da1c" or "rgba(246,64,25,0.92)")
  ///
  /// Returns the parsed Color or Colors.grey if parsing fails.
  Color parseColor(String? colorString);

  /// Get all loaded impacts.
  List<Impact> get impacts;

  /// Get all loaded severities.
  List<Severity> get severities;

  /// Check if impacts and severities are currently being loaded.
  bool get isLoading;

  /// Get the last error that occurred during loading.
  String? get error;
}
