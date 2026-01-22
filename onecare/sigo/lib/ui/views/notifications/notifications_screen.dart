import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/app_notification.dart';
import '../../../services/notification_service.dart';
import '../../../utils/date_formatter.dart';
import '../tickets/ticket_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String? openNotificationId;

  const NotificationsScreen({super.key, this.openNotificationId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = context.read<NotificationService>();
    _notificationService.reloadFromStorage();

    // Listen for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // If a notification ID was provided, open its modal after the frame is built
    if (widget.openNotificationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openNotificationById(widget.openNotificationId!);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload notifications when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _notificationService.reloadFromStorage();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload notifications every time this screen becomes visible
    _notificationService.reloadFromStorage();
  }

  void _openNotificationById(String notificationId) {
    final notification = _notificationService.notifications
        .firstWhere(
          (n) => n.id == notificationId,
          orElse: () => _notificationService.notifications.first,
        );
    if (notification == null) return;
    if (notification.isTopicNotification) {
      _notificationService.markAsRead(notification.id);
      return;
    }
    _openNotification(notification);
  }

  Future<void> _refresh() async {
    await _notificationService.reloadFromStorage();
  }

  void _openNotification(AppNotification notification) {
    _notificationService.markAsRead(notification.id);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final changeWidgets = notification.data.isNotEmpty
        ? _buildChangeDetails(notification.data, l10n)
        : <Widget>[];
    final isGeneralTopic = _isGeneralTopic(notification);
    final topicAccent = isGeneralTopic ? Colors.blue : Colors.orange;
    final topicSurface = isGeneralTopic ? Colors.blue.shade50 : Colors.orange.shade50;

    // Get user info for display
    final actionUsername = notification.data['actionUsername']?.toString() ?? '';
    final createdBy = notification.data['createdBy']?.toString() ?? '';
    final isCreateNotification = _hasCreateChange(notification);
    final displayUser = isCreateNotification ? createdBy : actionUsername;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: notification.isTopicNotification
                        ? topicSurface
                        : Colors.grey[50],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (notification.isTopicNotification)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: topicAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.campaign,
                                color: Colors.white,
                                size: 24,
                              ),
                            )
                          else
                            Icon(
                              Icons.notifications_active,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (notification.isTopicNotification)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: topicAccent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      l10n.alert,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Text(
                                  _buildLocalizedTitle(notification, l10n),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      ...[
                        const SizedBox(height: 8),
                        Text(
                          _buildLocalizedBody(notification, l10n, locale),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      if (displayUser.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCreateNotification
                                  ? '${l10n.createdBy}: $displayUser'
                                  : '${l10n.updatedBy}: $displayUser',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Changes list
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                      if (changeWidgets.isNotEmpty) ...[
                        Text(
                          l10n.changes,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...changeWidgets,
                      ] else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              l10n.noChangesToDisplay,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                    ),
                  ),

                // Bottom action button
                if (notification.ticketId != null &&
                    notification.ticketId!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TicketDetailScreen(
                                  ticketId: notification.ticketId!,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.confirmation_number),
                          label: Text(l10n.viewTicketDetails),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _buildChangeDetails(Map<String, dynamic> data, AppLocalizations l10n) {
    final widgets = <Widget>[];

    // Debug: Show what keys are in the data
    debugPrint('Notification data keys: ${data.keys.toList()}');
    debugPrint('Notification data: $data');

    List<dynamic>? changesData;

    // Try to get changes from the data directly (new format)
    final changesRaw = data['changes'];
    if (changesRaw != null) {
      if (changesRaw is String && changesRaw.isNotEmpty) {
        try {
          final parsed = json.decode(changesRaw);
          changesData = parsed is List ? parsed : null;
          debugPrint('Parsed changes from string: $changesData');
        } catch (e) {
          debugPrint('Error parsing changes JSON: $e');
        }
      } else if (changesRaw is List) {
        changesData = changesRaw;
        debugPrint('Changes already a list: $changesData');
      }
    }

    // If not found, try the old payload structure
    if (changesData == null) {
      final payloadRaw = data['payload'];
      if (payloadRaw is String && payloadRaw.isNotEmpty) {
        try {
          final payload = json.decode(payloadRaw) as Map<String, dynamic>;
          final payloadData = payload['data'] as Map<String, dynamic>?;
          if (payloadData != null) {
            changesData = payloadData['changes'] as List<dynamic>?;
            debugPrint('Parsed changes from payload: $changesData');
          }
        } catch (e) {
          debugPrint('Error parsing payload JSON: $e');
        }
      }
    }

    if (changesData == null || changesData.isEmpty) {
      debugPrint('No changes data found or empty');
      return widgets;
    }

    // Process each change
    for (final changeItem in changesData) {
      if (changeItem is! Map<String, dynamic>) continue;

      final changeType = changeItem['type'] as String?;
      if (changeType == null) continue;

      switch (changeType) {
        case 'Create':
        case 'Created':
          widgets.add(_buildChangeItem(
            icon: Icons.add_circle_outline,
            iconColor: Colors.green,
            title: l10n.created,
            description: l10n.newTicketCreated,
          ));
          break;

        case 'FieldChange':
          final fieldName = changeItem['fieldName'] as String? ?? l10n.unknownField;
          final fieldNameLower = fieldName.toLowerCase();
          // Only show status, impact, and severity field changes
          if (fieldNameLower != 'status' && fieldNameLower != 'impact' && fieldNameLower != 'severity') {
            continue;
          }
          final translatedFieldName = _translateFieldName(fieldName, l10n);
          final oldValueRaw = changeItem['oldValue']?.toString() ?? '';
          final newValueRaw = changeItem['newValue']?.toString() ?? '';
          // Translate values based on field type
          final oldValue = oldValueRaw.isEmpty
              ? l10n.none
              : _translateFieldValue(fieldNameLower, oldValueRaw, l10n);
          final newValue = newValueRaw.isEmpty
              ? l10n.none
              : _translateFieldValue(fieldNameLower, newValueRaw, l10n);
          widgets.add(_buildChangeItem(
            icon: Icons.edit_outlined,
            iconColor: Colors.blue,
            title: '${l10n.fieldChanged}: $translatedFieldName',
            description: l10n.changedFromTo(oldValue, newValue),
          ));
          break;

        case 'Note':
          final action = changeItem['action'] as String? ?? 'UNKNOWN';
          final oldContent = changeItem['oldContent']?.toString() ?? '';
          final newContent = changeItem['newContent']?.toString() ?? '';
          String title;
          String description;
          if (action == 'ADD') {
            title = l10n.noteAdded;
            description = '${l10n.addedColon}: $newContent';
          } else if (action == 'EDIT') {
            title = l10n.noteEdited;
            description = l10n.changedFromTo(oldContent, newContent);
          } else {
            title = l10n.noteRemoved;
            description = '${l10n.removedColon}: $oldContent';
          }
          widgets.add(_buildChangeItem(
            icon: Icons.note_outlined,
            iconColor: Colors.orange,
            title: title,
            description: description,
          ));
          break;

        case 'Attachment':
          final action = changeItem['action'] as String? ?? 'UNKNOWN';
          final fileName = changeItem['fileName'] as String? ?? l10n.unknownFile;
          final title = action == 'ADD' ? l10n.attachmentAdded : l10n.attachmentRemoved;
          widgets.add(_buildChangeItem(
            icon: Icons.attach_file,
            iconColor: Colors.purple,
            title: title,
            description: fileName,
          ));
          break;

        case 'ExtraAttribute':
          final action = changeItem['action'] as String? ?? 'UNKNOWN';
          final form = changeItem['form'] as String? ?? l10n.unknownForm;
          final attribute = changeItem['attribute'] as String? ?? l10n.unknownAttribute;
          final oldValue = changeItem['oldValue']?.toString() ?? l10n.none;
          final newValue = changeItem['newValue']?.toString() ?? l10n.none;
          String title;
          if (action == 'ADD') {
            title = l10n.extraAttributeAdded;
          } else if (action == 'EDIT') {
            title = l10n.extraAttributeEdited;
          } else {
            title = l10n.extraAttributeRemoved;
          }
          String description = '$form - $attribute';
          if (action != 'REMOVE') {
            description += ': $oldValue → $newValue';
          }
          widgets.add(_buildChangeItem(
            icon: Icons.settings_outlined,
            iconColor: Colors.teal,
            title: title,
            description: description,
          ));
          break;

        case 'CI':
          final action = changeItem['action'] as String? ?? 'UNKNOWN';
          final ciNames = changeItem['ciNames'] as List<dynamic>? ?? [];
          final title = action == 'ADD' ? l10n.ciAdded : l10n.ciRemoved;
          widgets.add(_buildChangeItem(
            icon: Icons.device_hub,
            iconColor: Colors.indigo,
            title: title,
            description: ciNames.join(', '),
          ));
          break;

        case 'Relation':
          final action = changeItem['action'] as String? ?? 'UNKNOWN';
          final relationType = changeItem['relationType'] as String? ?? 'UNKNOWN';
          final relatedTTKId = changeItem['relatedTTKId'] as String? ?? '';
          final title = action == 'ADD' ? l10n.relationAdded : l10n.relationRemoved;
          widgets.add(_buildChangeItem(
            icon: Icons.link,
            iconColor: Colors.cyan,
            title: title,
            description: '$relationType: $relatedTTKId',
          ));
          break;

        case 'Service':
          final action = changeItem['action'] as String? ?? 'UNKNOWN';
          final services = changeItem['services'] as List<dynamic>? ?? [];
          final title = action == 'ADD' ? l10n.serviceAdded : l10n.serviceRemoved;
          widgets.add(_buildChangeItem(
            icon: Icons.business_outlined,
            iconColor: Colors.brown,
            title: title,
            description: services.join(', '),
          ));
          break;

        case 'Watcher':
          final action = changeItem['action'] as String? ?? 'UNKNOWN';
          final username = changeItem['username'] as String? ?? l10n.unknownUser;
          final title = action == 'ADD' ? l10n.watcherAdded : l10n.watcherRemoved;
          widgets.add(_buildChangeItem(
            icon: Icons.visibility_outlined,
            iconColor: Colors.deepOrange,
            title: title,
            description: username,
          ));
          break;

        case 'ExternalTicket':
        case 'Pendency':
          // Skip these change types
          break;

        default:
          widgets.add(_buildChangeItem(
            icon: Icons.info_outline,
            iconColor: Colors.grey,
            title: l10n.unknownChange,
            description: changeType,
          ));
      }
    }

    return widgets;
  }

  Widget _buildChangeItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isGeneralTopic(AppNotification notification) {
    final type = notification.data['type']?.toString().toLowerCase();
    return type == 'general';
  }

  /// Builds a localized title for the notification based on its data.
  String _buildLocalizedTitle(AppNotification notification, AppLocalizations l10n) {
    // For topic notifications, always use localized titles
    if (_isMaintenanceTopic(notification)) {
      return l10n.maintenanceWindowTitle;
    }
    if (_isGeneralTopic(notification)) {
      return l10n.generalInformationTitle;
    }

    // Build title from ticketId - check if it's a Create notification
    final ticketId = notification.ticketId;
    if (ticketId != null && ticketId.isNotEmpty) {
      if (_hasCreateChange(notification)) {
        return l10n.ticketCreatedTitle(ticketId);
      }
      return l10n.ticketUpdatedTitle(ticketId);
    }

    // If title is already set, use it
    if (notification.title != null && notification.title!.isNotEmpty) {
      return notification.title!;
    }

    return l10n.notification;
  }

  /// Checks if the notification contains a Create type change.
  bool _hasCreateChange(AppNotification notification) {
    final changesRaw = notification.data['changes'];
    if (changesRaw == null) return false;

    List<dynamic>? changesData;
    if (changesRaw is String && changesRaw.isNotEmpty) {
      try {
        final parsed = json.decode(changesRaw);
        changesData = parsed is List ? parsed : null;
      } catch (_) {
        return false;
      }
    } else if (changesRaw is List) {
      changesData = changesRaw;
    }

    if (changesData == null) return false;

    for (final change in changesData) {
      if (change is Map<String, dynamic>) {
        final type = change['type']?.toString();
        if (type == 'Create' || type == 'Created') {
          return true;
        }
      }
    }
    return false;
  }

  /// Builds a localized body for the notification based on its data.
  String _buildLocalizedBody(
    AppNotification notification,
    AppLocalizations l10n,
    String locale,
  ) {
    if (notification.isTopicNotification) {
      if (_isMaintenanceTopic(notification)) {
        final startRaw = notification.data['startAt']?.toString() ?? '';
        final endRaw = notification.data['endAt']?.toString() ?? '';
        if (startRaw.isNotEmpty && endRaw.isNotEmpty) {
          final startFormatted = _formatDateForDisplay(startRaw, locale);
          final endFormatted = _formatDateForDisplay(endRaw, locale);
          return l10n.maintenanceWindowBody(startFormatted, endFormatted);
        }
        if (notification.body != null && notification.body!.isNotEmpty) {
          return notification.body!;
        }
      }
      if (_isGeneralTopic(notification)) {
        final body = notification.data['body']?.toString() ?? '';
        if (body.isNotEmpty) {
          return body;
        }
        if (notification.body != null && notification.body!.isNotEmpty) {
          return notification.body!;
        }
      }
    }

    // If body is already set, use it
    if (notification.body != null && notification.body!.isNotEmpty) {
      return notification.body!;
    }

    // Build body from changes
    final parts = <String>[];

    List<dynamic>? changesData;
    final changesRaw = notification.data['changes'];
    if (changesRaw != null) {
      if (changesRaw is String && changesRaw.isNotEmpty) {
        try {
          final parsed = json.decode(changesRaw);
          changesData = parsed is List ? parsed : null;
        } catch (_) {}
      } else if (changesRaw is List) {
        changesData = changesRaw;
      }
    }

    if (changesData != null) {
      for (final change in changesData) {
        if (change is! Map<String, dynamic>) continue;
        final type = change['type'] as String?;
        if (type == 'Create' || type == 'Created') {
          parts.add(l10n.newTicketCreated);
        } else if (type == 'Note') {
          parts.add(l10n.noteAdded);
        } else if (type == 'FieldChange') {
          final fieldName = change['fieldName'] as String? ?? '';
          final fieldNameLower = fieldName.toLowerCase();
          if (fieldNameLower != 'status' && fieldNameLower != 'impact' && fieldNameLower != 'severity') {
            continue;
          }
          final translatedField = _translateFieldName(fieldName, l10n);
          parts.add('${l10n.fieldChanged}: $translatedField');
        } else if (type == 'Attachment') {
          final action = change['action'] as String?;
          parts.add(action == 'ADD' ? l10n.attachmentAdded : l10n.attachmentRemoved);
        } else if (type == 'Pendency' || type == 'ExternalTicket') {
          continue;
        }
      }
    }

    return parts.isEmpty ? l10n.ticketUpdated : parts.join(' | ');
  }

  String _formatDateForDisplay(String raw, String locale) {
    try {
      return formatDate(
        DateTime.parse(raw),
        locale,
        includeTime: true,
        formatPattern: 'dd MMM, HH:mm',
      );
    } catch (_) {
      return raw;
    }
  }

  String _translateFieldName(String fieldName, AppLocalizations l10n) {
    final fieldNameMap = {
      'id': l10n.id,
      'name': l10n.title,
      'type': l10n.type,
      'priority': l10n.priority,
      'severity': l10n.severity,
      'impact': l10n.impact,
      'status': l10n.status,
      'category': l10n.category,
      'subcategory': l10n.subcategory,
      'description': l10n.description,
      'createdBy': l10n.createdBy,
      'assignedTo': l10n.assignedTo,
      'scope': l10n.scope,
      'resolutionDate': l10n.resolvedDate,
      'statusChangeDate': l10n.modifiedDate,
    };

    return fieldNameMap[fieldName] ?? fieldName;
  }

  String _translateStatusValue(String value, AppLocalizations l10n) {
    switch (value.trim().toUpperCase()) {
      case 'OPEN':
        return l10n.open;
      case 'ACKNOWLEDGED':
        return l10n.acknowledged;
      case 'IN_PROGRESS':
        return l10n.inProgress;
      case 'RESOLVED':
        return l10n.resolved;
      case 'CLOSED':
        return l10n.closed;
      case 'CANCELLED':
      case 'CANCELED':
        return l10n.cancelled;
      case 'PENDING':
        return l10n.pending;
      case 'HELD':
        return l10n.held;
      default:
        return value;
    }
  }

  String _translateImpactOrSeverityValue(String value, AppLocalizations l10n) {
    switch (value.trim().toUpperCase()) {
      case 'LOW':
        return l10n.low;
      case 'MEDIUM':
        return l10n.medium;
      case 'HIGH':
        return l10n.high;
      case 'URGENT':
        return l10n.urgent;
      default:
        return value;
    }
  }

  String _translateFieldValue(String fieldName, String value, AppLocalizations l10n) {
    switch (fieldName) {
      case 'status':
        return _translateStatusValue(value, l10n);
      case 'impact':
      case 'severity':
        return _translateImpactOrSeverityValue(value, l10n);
      default:
        return value;
    }
  }

  bool _isMaintenanceTopic(AppNotification notification) {
    final type = notification.data['type']?.toString().toLowerCase();
    return type == 'maintenance';
  }

  /// Checks if a notification has any meaningful changes to display.
  /// Returns false if the notification only contains non-displayable changes
  /// like lastUpdate or Pendency.
  bool _hasMeaningfulChanges(AppNotification notification) {
    List<dynamic>? changesData;
    final changesRaw = notification.data['changes'];
    if (changesRaw != null) {
      if (changesRaw is String && changesRaw.isNotEmpty) {
        try {
          final parsed = json.decode(changesRaw);
          changesData = parsed is List ? parsed : null;
        } catch (_) {
          return true; // If we can't parse, show the notification
        }
      } else if (changesRaw is List) {
        changesData = changesRaw;
      }
    }

    if (changesData == null || changesData.isEmpty) {
      return true; // No changes data, show the notification
    }

    // Check if there's at least one meaningful change
    for (final change in changesData) {
      if (change is! Map<String, dynamic>) continue;
      final type = change['type'] as String?;
      if (type == null) continue;

      // Skip Pendency and ExternalTicket changes
      if (type == 'Pendency' || type == 'ExternalTicket') continue;

      // For FieldChange, only status, impact, and severity are meaningful
      if (type == 'FieldChange') {
        final fieldName = (change['fieldName'] as String? ?? '').toLowerCase();
        if (fieldName == 'status' || fieldName == 'impact' || fieldName == 'severity') {
          return true;
        }
        continue; // Skip other field changes like lastUpdate
      }

      // All other change types (Create, Note, Attachment, etc.) are meaningful
      return true;
    }

    return false; // No meaningful changes found
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.notifications,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF37414A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          StreamBuilder<List<AppNotification>>(
            stream: _notificationService.notificationsStream,
            initialData: _notificationService.notifications,
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? const <AppNotification>[];
              final hasUnread =
                  notifications.any((notification) => !notification.read);

              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.done_all),
                    tooltip: l10n.markAllAsRead,
                    onPressed: notifications.isEmpty
                        ? null
                        : () => _notificationService.markAllAsRead(),
                    color: hasUnread ? Colors.white : Colors.white70,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.clearNotifications,
                    onPressed: notifications.isEmpty
                        ? null
                        : () => _notificationService.clearAll(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notificationService.notificationsStream,
        initialData: _notificationService.notifications,
        builder: (context, snapshot) {
          final allNotifications = snapshot.data ?? const <AppNotification>[];
          // Filter out notifications that only have lastUpdate or other non-meaningful changes
          final notifications = allNotifications
              .where((n) => _hasMeaningfulChanges(n))
              .toList();

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noNotifications,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.notificationsWillAppearHere,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final locale = Localizations.localeOf(context).toString();
                final localizedBody = _buildLocalizedBody(notification, l10n, locale);
                final subtitle = <String>[
                  localizedBody,
                  formatDate(notification.receivedAt, locale),
                ].where((text) => text.isNotEmpty).join('\n');

                // Topic notifications (alerts) have a different style
                if (notification.isTopicNotification) {
                  final isGeneralTopic = _isGeneralTopic(notification);
                  final topicAccent = isGeneralTopic ? Colors.blue : Colors.orange;
                  final topicSurface =
                      isGeneralTopic ? Colors.blue.shade50 : Colors.orange.shade50;
                  final topicSurfaceActive =
                      isGeneralTopic ? Colors.blue.shade100 : Colors.orange.shade100;
                  final topicBorder =
                      isGeneralTopic ? Colors.blue.shade300 : Colors.orange.shade300;
                  final topicIconBg = notification.read
                      ? (isGeneralTopic ? Colors.blue.shade200 : Colors.orange.shade200)
                      : topicAccent;
                  final topicIconColor = notification.read
                      ? (isGeneralTopic ? Colors.blue.shade700 : Colors.orange.shade700)
                      : Colors.white;
                  return Card(
                    color: notification.read
                        ? topicSurface
                        : topicSurfaceActive,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: topicBorder,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => _notificationService.markAsRead(notification.id),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: topicIconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.campaign,
                          color: topicIconColor,
                          size: 24,
                        ),
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: topicAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.alert,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _buildLocalizedTitle(notification, l10n),
                              style: TextStyle(
                                fontWeight: notification.read
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(subtitle),
                      ),
                      trailing: notification.read
                          ? null
                          : Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: topicAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  );
                }

                // Regular ticket notifications
                return Card(
                  child: ListTile(
                    onTap: () => _openNotification(notification),
                    leading: Icon(
                      notification.read
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: notification.read
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      _buildLocalizedTitle(notification, l10n),
                      style: TextStyle(
                        fontWeight:
                            notification.read ? FontWeight.w500 : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(subtitle),
                    trailing: notification.read
                        ? null
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
