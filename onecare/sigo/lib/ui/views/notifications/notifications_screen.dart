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
    if (notification != null) {
      _openNotification(notification);
    }
  }

  Future<void> _refresh() async {
    await _notificationService.reloadFromStorage();
  }

  void _openNotification(AppNotification notification) {
    _notificationService.markAsRead(notification.id);
    final l10n = AppLocalizations.of(context);
    final changeWidgets = notification.data.isNotEmpty
        ? _buildChangeDetails(notification.data, l10n)
        : <Widget>[];

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
                    color: Colors.grey[50],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              notification.title ?? l10n.notification,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      if ((notification.body ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          notification.body!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
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
          widgets.add(_buildChangeItem(
            icon: Icons.add_circle_outline,
            iconColor: Colors.green,
            title: l10n.created,
            description: l10n.newTicketActivityCreated,
          ));
          break;

        case 'FieldChange':
          final fieldName = changeItem['fieldName'] as String? ?? l10n.unknownField;
          final translatedFieldName = _translateFieldName(fieldName, l10n);
          final oldValue = changeItem['oldValue']?.toString() ?? l10n.none;
          final newValue = changeItem['newValue']?.toString() ?? l10n.none;
          widgets.add(_buildChangeItem(
            icon: Icons.edit_outlined,
            iconColor: Colors.blue,
            title: '${l10n.fieldChanged}: $translatedFieldName',
            description: '$oldValue → $newValue',
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
          final action = changeItem['action'] as String? ?? 'UNKNOWN';
          final id = changeItem['id'] as String? ?? l10n.unknownId;
          final title = action == 'ADD' ? l10n.externalTicketAdded : l10n.externalTicketRemoved;
          widgets.add(_buildChangeItem(
            icon: Icons.open_in_new,
            iconColor: Colors.pink,
            title: title,
            description: id,
          ));
          break;

        case 'Pendency':
          final action = changeItem['action'] as String? ?? 'UNKNOWN';
          final pendencyType = changeItem['pendencyType'] as String? ?? l10n.unknownType;
          final title = action == 'ADD' ? l10n.pendencyAdded : l10n.pendencyRemoved;
          widgets.add(_buildChangeItem(
            icon: Icons.pending_outlined,
            iconColor: Colors.amber,
            title: title,
            description: pendencyType,
          ));
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
      'createdBy': l10n.createdBy,
      'assignedTo': l10n.assignedTo,
      'creationDate': l10n.reportedDate,
      'lastUpdate': l10n.modifiedDate,
      'expectedResolutionDate': l10n.limitDate,
      'statusChangeDate': l10n.modifiedDate,
      'notes': l10n.notes,
      'attachments': l10n.attachments,
      'services': l10n.logAttrServices,
      'scope': l10n.scope,
      'tenant': l10n.tenant,
    };

    return fieldNameMap[fieldName] ?? fieldName;
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
          final notifications = snapshot.data ?? const <AppNotification>[];

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
                final subtitle = <String>[
                  if ((notification.body ?? '').isNotEmpty) notification.body!,
                  formatDate(notification.receivedAt, locale),
                ].where((text) => text.isNotEmpty).join('\n');

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
                      notification.title ?? l10n.notifications,
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
