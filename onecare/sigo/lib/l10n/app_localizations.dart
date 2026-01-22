import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_de.dart';

abstract class AppLocalizations {
  final String localeName;

  AppLocalizations(this.localeName);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Login Screen
  String get signInToContinue;
  String get username;
  String get password;
  String get pleaseEnterUsername;
  String get pleaseEnterPassword;
  String get signIn;
  String get loginFailed;

  // Home Screen
  String get oneCare;
  String get searchTickets;
  String get noTicketsFound;
  String resultsCount(int count);
  String get pullDownToRefresh;
  String get newTicket;
  String get id;
  String get type;
  String get createdBy;

  // Ticket Status
  String get open;
  String get acknowledged;
  String get inProgress;
  String get resolved;
  String get closed;
  String get cancelled;
  String get pending;
  String get held;

  // Ticket Priority
  String get low;
  String get medium;
  String get high;
  String get urgent;

  // Create/Edit Ticket Screen
  String get createTicket;
  String get editTicket;
  String get caseType;
  String get incident;
  String get request;
  String get problem;
  String get impact;
  String get selectImpact;
  String get severity;
  String get selectSeverity;
  String get summary;
  String get enterTicketSummary;
  String get description;
  String get enterDetailedDescription;
  String get affectedCI;
  String get equipment;
  String get service;
  String get searchCI;
  String get noResultsFound;
  String get confirm;
  String get create;
  String get update;
  String get cancel;
  String get pleaseEnterSummary;
  String get pleaseEnterDescription;
  String get ticketCreatedSuccessfully;
  String get failedToCreateTicket;
  String get ticketUpdatedSuccessfully;
  String get failedToUpdateTicket;

  // Ticket Detail Screen
  String get ticketDetails;
  String get status;
  String get priority;
  String get category;
  String get assignedTo;
  String get requesterInfo;
  String get name;
  String get email;
  String get phone;
  String get sla;
  String get slaProgress;
  String get slaInMinutes;
  String get expectedResolutionDate;
  String get timeRemaining;
  String get overdue;
  String get notes;
  String get addNote;
  String get attachments;
  String get addAttachment;
  String get logs;
  String get noNotesYet;
  String get noAttachmentsYet;
  String get noLogsYet;
  String get enterNoteContent;
  String get save;
  String get edit;
  String get delete;
  String get download;
  String get noteAddedSuccessfully;
  String get failedToAddNote;
  String get attachmentUploadedSuccessfully;
  String get failedToUploadAttachment;
  String get confirmDelete;
  String get areYouSureDeleteNote;
  String get areYouSureDeleteAttachment;
  String get areYouSureCancelTicket;
  String get noteDeletedSuccessfully;
  String get failedToDeleteNote;
  String get attachmentDeletedSuccessfully;
  String get failedToDeleteAttachment;
  String get cancelTicket;
  String get reopenTicket;
  String get validateTicket;
  String get ticketCancelledSuccessfully;
  String get ticketReopenedSuccessfully;
  String get ticketValidatedSuccessfully;
  String get failedToCancelTicket;
  String get cancelTicketBlockedByOpenActivities;
  String get failedToReopenTicket;
  String get failedToValidateTicket;
  String get noInternet;
  String get checkConnectionAndRetry;

  // Filter Screen
  String get filterTickets;
  String get clearFilters;
  String get applyFilters;
  String get savedFilters;
  String get quickFilters;
  String get draftFilter;
  String get noSavedFilters;
  String get currentlyActive;
  String get filterDeletedSuccessfully;
  String get failedToLoadSavedFilters;
  String deleteFilterConfirm(String name);
  String get saveFilter;
  String get filterName;
  String get filterVisibility;
  String get private;
  String get public;
  String get filterSavedSuccessfully;
  String get filterUpdatedSuccessfully;
  String get ifYouKeepCurrentNameFilterWillBeUpdated;
  String get enterFilterName;
  String get filterNameAlreadyExists;
  String get filterWillReplaceExisting;
  String get noFiltersSelected;
  String get addImpactValue;
  String get add;
  String get creationDateFilter;
  String get resolutionDateFilter;
  String get today;
  String get last24Hours;
  String get lastWeek;
  String get lastMonth;
  String get last3Months;
  String get customDateRange;
  String get from;
  String get to;
  String get changeDates;
  String get endDateMustBeAfterStartDate;

  // Profile Screen
  String get profile;
  String get userInformation;
  String get defaultTeam;
  String get tenant;
  String get language;
  String get appLanguage;
  String get logout;
  String get areYouSureLogout;
  String get loadingProfile;
  String get retry;
  String get languageChanged;
  String get appVersion;
  String get copyrightNotice;
  String get settings;
  String get signOutDescription;
  String get preferencesAndOptions;
  String get biometricAuth;
  String get enableBiometric;
  String get biometricLoginReason;
  String get biometricSetupReason;
  String get biometricEnabled;
  String get biometricDisabled;
  String get resetConfiguration;
  String get resetConfigurationDescription;
  String get resetConfigurationTitle;
  String get resetConfigurationMessage;
  String get reset;

  // Notifications
  String get notifications;
  String get noNotifications;
  String get notificationsWillAppearHere;
  String get markAllAsRead;
  String get clearNotifications;
  String get notificationData;
  String get notification;
  String get alert;
  String get maintenanceWindowTitle;
  String maintenanceWindowBody(String startAt, String endAt);
  String get generalInformationTitle;
  String ticketUpdatedTitle(String ticketId);
  String ticketCreatedTitle(String ticketId);
  String get ticketUpdated;
  String get changes;
  String get noChangesToDisplay;
  String get viewTicketDetails;
  String get created;
  String get newTicketActivityCreated;
  String get newTicketCreated;
  String get fieldChanged;
  String get noteAdded;
  String get noteEdited;
  String get noteRemoved;
  String get attachmentAdded;
  String get attachmentRemoved;
  String get extraAttributeAdded;
  String get extraAttributeEdited;
  String get extraAttributeRemoved;
  String get ciAdded;
  String get ciRemoved;
  String get relationAdded;
  String get relationRemoved;
  String get serviceAdded;
  String get serviceRemoved;
  String get watcherAdded;
  String get watcherRemoved;
  String get externalTicketAdded;
  String get externalTicketRemoved;
  String get pendencyAdded;
  String get pendencyRemoved;
  String get unknownChange;
  String get unknownField;
  String get none;
  String get unknownForm;
  String get unknownAttribute;
  String get unknownUser;
  String get unknownId;
  String get unknownType;
  String get addedColon;
  String get removedColon;
  String changedFromTo(String oldValue, String newValue);
  String get updatedBy;

  // Common
  String get yes;
  String get no;
  String get ok;
  String get error;
  String get success;
  String get loading;
  String get na;
  String get days;
  String get hours;
  String get minutes;
  String get remaining;
  String get yesterday;
  String daysAgo(int count);

  // Network Errors
  String get noInternetConnection;
  String get serviceNotReachable;
  String get checkYourConnection;

  // Additional Ticket Detail strings
  String get copyId;
  String get copyUrl;
  String get ticketIdCopied;
  String get ticketUrlCopied;
  String get ticketNotFound;
  String get enterJustification;
  String get justificationRequired;
  String get cancellingTicket;
  String get reopeningTicket;
  String get validatingTicket;
  String get cancelTicketJustification;
  String get reopenTicketJustification;
  String get validateTicketJustification;
  String get globalInformation;
  String get dates;
  String get otherInformation;
  String get affectedItem;
  String get scope;
  String get scopeTeam;
  String get scopeIndividual;
  String get title;
  String get subcategory;
  String get equipmentType;
  String get serviceType;
  String get urgency;
  String get reportedDate;
  String get modifiedDate;
  String get limitDate;
  String get resolvedDate;
  String get closedDate;
  String get files;
  String get uploadFile;
  String get noFilesAttached;
  String get unknownFile;
  String get size;
  String get downloadingFile;
  String get saveFile;
  String get downloadCancelled;
  String get fileSavedSuccessfully;
  String get failedToDownloadFile;
  String get uploadingFile;
  String get fileUploadedSuccessfully;
  String get failedToUploadFile;
  String get deleteAttachment;
  String get deleteAttachmentConfirmation;
  String get fileDeletedSuccessfully;
  String get failedToDeleteFile;
  String get noNotesAvailable;
  String get editNote;
  String get editNoteContent;
  String get noteUpdatedSuccessfully;
  String get failedToUpdateNote;
  String get noLogsAvailable;
  String get collapseLogs;
  String get expandLogs;
  String get collapseFiles;
  String get expandFiles;
  String get collapseNotes;
  String get expandNotes;
  String get ticketCreated;
  String get unknown;
  String get added;
  String get removed;
  String get updated;
  String get modified;
  String get selectUrgency;
  String get noImpactOptionsAvailable;
  String get impactUpdatedSuccessfully;
  String get failedToUpdateImpact;
  String get noUrgencyOptionsAvailable;
  String get urgencyUpdatedSuccessfully;
  String get failedToUpdateUrgency;

  // Create Ticket Multi-Step Form
  String get externalReference;
  String get externalReferenceOptional;
  String get next;
  String get previous;
  String get selectType;
  String get selectScope;
  String get selectAffectedItem;
  String get selectEquipmentOrService;
  String get searchEquipment;
  String get searchService;
  String get selectCategory;
  String get searchCategories;
  String get noCategoriesAvailable;
  String get selectSubcategory;
  String get searchSubcategories;
  String get noSubcategoriesAvailable;
  String get searchImpacts;
  String get searchSeverities;
  String get titleRequired;
  String get descriptionOptional;
  String get addFiles;
  String get removeFile;
  String get reviewTicket;
  String get reviewAllInformation;
  String get pleaseEnterTitle;
  String get errorLoadingCategories;
  String get errorLoadingSubcategories;
  String get errorLoadingImpactsAndSeverities;
  String get creating;
  String get affectedItemType;
  String get stepReference;
  String get stepType;
  String get stepScope;
  String get stepItem;
  String get stepSelect;
  String get stepCategory;
  String get stepSubcategoryShort;
  String get stepImpact;
  String get stepUrgency;
  String get stepDetails;
  String get stepReview;
  String get externalReferenceDescription;
  String get externalReferenceHint;
  String get externalReferenceInfo;
  String get chooseCaseTypeDescription;
  String get incidentOptionDescription;
  String get requestOptionDescription;
  String get chooseScopeDescription;
  String get scopeIndividualDescription;
  String get scopeTeamDescription;
  String get affectedItemDescription;
  String get serviceOptionDescription;
  String get equipmentOptionDescription;
  String get selectEquipmentTitle;
  String get selectServiceTitle;
  String get selectItemTitleGeneric;
  String get selectEquipmentSubtitle;
  String get selectServiceSubtitle;
  String get selectItemSubtitleGeneric;
  String get chooseCategoryDescription;
  String get chooseSubcategoryDescription;
  String get chooseImpactDescription;
  String get chooseUrgencyDescription;
  String get provideDetailsAndAttachments;
  String get enterTicketTitle;
  String get enterTicketDescription;
  String get noFilesSelectedMessage;
  String get errorSelectingFiles;

  // Log attribute translations
  String get logAttrCis;
  String get logAttrStatus;
  String get logAttrNotes;
  String get logAttrAttachments;
  String get logAttrPriority;
  String get logAttrSeverity;
  String get logAttrImpact;
  String get logAttrCategory;
  String get logAttrSubcategory;
  String get logAttrDescription;
  String get logAttrName;
  String get logAttrServices;
  String get logAttrAssignedTo;
  String get logAttrTeam;

  // QR Scanner / Search
  String get welcomeToSigoOneCare;
  String get scanConfigurationQrDescription;
  String get scanQrCodeButton;
  String get search;
  String get scanQrCodeTitle;
  String get pointCameraAtQr;
  String get configurationScannedAutomatically;
  String get processingConfiguration;
  String get invalidQrCodeFormat;
  String get failedToProcessQrCode;

  // Auth/session
  String get sessionExpired;

  // Form Validation
  String fieldRequired(String fieldName);
  String fieldTooShort(String fieldName, int minLength);
  String fieldTooLong(String fieldName, int maxLength);
  String get invalidEmailFormat;
  String get invalidPhoneFormat;
  String fieldMustBeNumeric(String fieldName);
  String fieldOutOfRange(String fieldName, double min, double max);

  // Team Selection
  String get selectTeam;
  String get selectTeamDescription;
  String get noTeamsAvailable;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'pt', 'fr', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'pt':
        return AppLocalizationsPt();
      case 'fr':
        return AppLocalizationsFr();
      case 'de':
        return AppLocalizationsDe();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
