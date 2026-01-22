/// Abstract repository for user-specific operations.
/// Defines the contract for user data access including user info, teams, and workbenches.
abstract class UserRepository {
  /// Get current user information.
  ///
  /// Returns a map containing user details and configuration.
  Future<Map<String, dynamic>> getUserInfo();

  /// Get a workbench (view or filter) by its ID.
  ///
  /// [workbenchId] - The workbench ID to retrieve
  ///
  /// Returns the workbench configuration.
  Future<Map<String, dynamic>> getWorkbenchById(int workbenchId);

  /// Get the default filter for the current user.
  ///
  /// This retrieves the user's configured default filter from their OneCare view.
  /// Returns null if no default filter is configured.
  ///
  /// Returns a map with:
  /// - 'filterQuery': The filter configuration
  /// - 'filterName': The name of the filter
  /// - 'filterId': The ID of the filter
  Future<Map<String, dynamic>?> getDefaultFilter();

  /// Get the list of teams the current user belongs to.
  ///
  /// Returns a list of team objects.
  Future<List<dynamic>> getUserTeams();

  /// Update the user's default team.
  ///
  /// [teamName] - The name of the team to set as default
  Future<void> updateDefaultTeam(String teamName);
}
