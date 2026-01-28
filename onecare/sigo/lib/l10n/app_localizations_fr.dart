import 'app_localizations.dart';

class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr() : super('fr');

  @override
  String get signInToContinue => 'Connectez-vous pour continuer';
  @override
  String get username => "Nom d'utilisateur";
  @override
  String get password => 'Mot de passe';
  @override
  String get pleaseEnterUsername => "Veuillez saisir votre nom d'utilisateur";
  @override
  String get pleaseEnterPassword => 'Veuillez saisir votre mot de passe';
  @override
  String get signIn => 'Se connecter';
  @override
  String get loginFailed => 'Échec de la connexion. Veuillez consulter la console pour plus de détails.';

  @override
  String get oneCare => 'OneCare';
  @override
  String get searchTickets => 'Rechercher des tickets...';
  @override
  String get noTicketsFound => 'Aucun ticket trouvé';
  @override
  String resultsCount(int count) => '$count resultats';
  @override
  String get pullDownToRefresh => 'Tirez pour actualiser';
  @override
  String get newTicket => 'Nouveau ticket';
  @override
  String get id => 'ID';
  @override
  String get type => 'Type';
  @override
  String get createdBy => 'Créé par';

  @override
  String get open => 'Ouvert';
  @override
  String get acknowledged => 'Confirmé';
  @override
  String get inProgress => 'En cours';
  @override
  String get resolved => 'Résolue';
  @override
  String get closed => 'Fermé';
  @override
  String get cancelled => 'Annulé';
  @override
  String get pending => 'En attente';
  @override
  String get held => 'En pause';

  @override
  String get low => 'Faible';
  @override
  String get medium => 'Moyenne';
  @override
  String get high => 'Élevée';
  @override
  String get urgent => 'Urgent';

  @override
  String get createTicket => 'Créer un ticket';
  @override
  String get editTicket => 'Modifier le ticket';
  @override
  String get caseType => 'Type de dossier';
  @override
  String get incident => 'Incident';
  @override
  String get problem => 'Problème';
  @override
  String get request => 'Demande';
  @override
  String get impact => 'Impact';
  @override
  String get selectImpact => "Sélectionner l'impact";
  @override
  String get severity => 'Gravité';
  @override
  String get selectSeverity => 'Sélectionner la gravité';
  @override
  String get summary => 'Résumé';
  @override
  String get enterTicketSummary => 'Saisir le résumé du ticket';
  @override
  String get description => 'Description';
  @override
  String get enterDetailedDescription => 'Saisir la description détaillée';
  @override
  String get affectedCI => 'CI affecté';
  @override
  String get equipment => 'Équipement';
  @override
  String get service => 'Service';
  @override
  String get searchCI => 'Rechercher un CI...';
  @override
  String get noResultsFound => 'Aucun résultat';
  @override
  String get confirm => 'Confirmer';
  @override
  String get create => 'Créer';
  @override
  String get update => 'Mettre à jour';
  @override
  String get cancel => 'Annuler';
  @override
  String get pleaseEnterSummary => 'Veuillez saisir un résumé';
  @override
  String get pleaseEnterDescription => 'Veuillez saisir une description';
  @override
  String get ticketCreatedSuccessfully => 'Ticket créé avec succès !';
  @override
  String get failedToCreateTicket => 'Échec de la création du ticket';
  @override
  String get ticketUpdatedSuccessfully => 'Ticket mis à jour avec succès !';
  @override
  String get failedToUpdateTicket => 'Échec de la mise à jour du ticket';

  @override
  String get ticketDetails => 'Détails du ticket';
  @override
  String get status => 'Statut';
  @override
  String get priority => 'Priorité';
  @override
  String get category => 'Catégorie';
  @override
  String get assignedTo => 'Attribué à';
  @override
  String get requesterInfo => 'Infos du demandeur';
  @override
  String get name => 'Nom';
  @override
  String get email => 'E-mail';
  @override
  String get phone => 'Téléphone';
  @override
  String get sla => 'SLA';
  @override
  String get slaProgress => 'Progression SLA';
  @override
  String get slaInMinutes => 'SLA';
  @override
  String get expectedResolutionDate => 'Date de résolution prévue';
  @override
  String get timeRemaining => 'Temps restant';
  @override
  String get overdue => 'En retard';
  @override
  String get notes => 'Notes';
  @override
  String get addNote => 'Ajouter une note';
  @override
  String get attachments => 'Pièces jointes';
  @override
  String get addAttachment => 'Ajouter une pièce jointe';
  @override
  String get logs => 'Journaux';
  @override
  String get noNotesYet => 'Pas encore de notes';
  @override
  String get noAttachmentsYet => 'Pas encore de pièces jointes';
  @override
  String get noLogsYet => 'Pas encore de journaux';
  @override
  String get enterNoteContent => 'Saisir le contenu de la note...';
  @override
  String get save => 'Enregistrer';
  @override
  String get edit => 'Modifier';
  @override
  String get delete => 'Supprimer';
  @override
  String get download => 'Télécharger';
  @override
  String get noteAddedSuccessfully => 'Note ajoutée avec succès !';
  @override
  String get failedToAddNote => "Échec de l'ajout de la note";
  @override
  String get attachmentUploadedSuccessfully => 'Pièce jointe envoyée avec succès !';
  @override
  String get failedToUploadAttachment => "Échec de l'envoi de la pièce jointe";
  @override
  String get confirmDelete => 'Confirmer la suppression';
  @override
  String get areYouSureDeleteNote => 'Voulez-vous supprimer cette note ?';
  @override
  String get areYouSureDeleteAttachment => 'Voulez-vous supprimer cette pièce jointe ?';
  @override
  String get areYouSureCancelTicket => 'Voulez-vous annuler ce ticket ?';
  @override
  String get noteDeletedSuccessfully => 'Note supprimée avec succès !';
  @override
  String get failedToDeleteNote => 'Échec de la suppression de la note';
  @override
  String get attachmentDeletedSuccessfully => 'Pièce jointe supprimée avec succès !';
  @override
  String get failedToDeleteAttachment => 'Échec de la suppression de la pièce jointe';
  @override
  String get cancelTicket => 'Annuler le ticket';
  @override
  String get reopenTicket => 'Rouvrir le ticket';
  @override
  String get validateTicket => 'Valider le ticket';
  @override
  String get ticketCancelledSuccessfully => 'Ticket annulé avec succès !';
  @override
  String get ticketReopenedSuccessfully => 'Ticket rouvert avec succès !';
  @override
  String get ticketValidatedSuccessfully => 'Ticket validé avec succès !';
  @override
  String get failedToCancelTicket => "Échec de l'annulation du ticket";
  @override
  String get cancelTicketBlockedByOpenActivities =>
      "Impossible d'annuler le ticket tant que des activités ne sont pas terminées";
  @override
  String get failedToReopenTicket => "Échec de la réouverture du ticket";
  @override
  String get failedToValidateTicket => 'Échec de la validation du ticket';
  @override
  String get noInternet => 'Pas de connexion Internet';
  @override
  String get checkConnectionAndRetry => 'Vérifiez votre connexion et réessayez';

  @override
  String get filterTickets => 'Filtrer les tickets';
  @override
  String get clearFilters => 'Effacer les filtres';
  @override
  String get applyFilters => 'Appliquer les filtres';
  @override
  String get savedFilters => 'Filtres';
  @override
  String get quickFilters => 'Modifier les filtres';
  @override
  String get draftFilter => 'Filtre brouillon';
  @override
  String get noSavedFilters => 'Aucun filtre enregistré';
  @override
  String get currentlyActive => 'Actuellement actifs';
  @override
  String get filterDeletedSuccessfully => 'Filtre supprimé avec succès';
  @override
  String get failedToLoadSavedFilters => 'Échec du chargement des filtres enregistrés';
  @override
  String deleteFilterConfirm(String name) => 'Voulez-vous supprimer le filtre "' + name + '" ?';
  @override
  String get saveFilter => 'Enregistrer le filtre';
  @override
  String get filterName => 'Nom du filtre';
  @override
  String get filterVisibility => 'Visibilité';
  @override
  String get private => 'Privé';
  @override
  String get public => 'Public';
  @override
  String get filterSavedSuccessfully => 'Filtre enregistré avec succès';
  @override
  String get filterUpdatedSuccessfully => 'Filtre mis à jour avec succès';
  @override
  String get ifYouKeepCurrentNameFilterWillBeUpdated => 'Si vous conservez le nom actuel, le filtre existant sera mis à jour.';
  @override
  String get enterFilterName => 'Saisir le nom du filtre';
  @override
  String get filterNameAlreadyExists =>
      'Un filtre public avec ce nom existe deja.';
  @override
  String get filterWillReplaceExisting =>
      'Ce nom correspond a un filtre prive et le remplacera.';
  @override
  String get noFiltersSelected => 'Aucun filtre sélectionné';
  @override
  String get addImpactValue => "Ajouter une valeur d'impact";
  @override
  String get add => 'Ajouter';
  @override
  String get creationDateFilter => 'Filtre date de création';
  @override
  String get resolutionDateFilter => 'Filtre date de résolution';
  @override
  String get today => 'Aujourd\'hui';
  @override
  String get last24Hours => 'Dernières 24 heures';
  @override
  String get lastWeek => 'Dernière semaine';
  @override
  String get lastMonth => 'Dernier mois';
  @override
  String get last3Months => '3 derniers mois';
  @override
  String get customDateRange => 'Plage de dates personnalisée';
  @override
  String get from => 'De';
  @override
  String get to => 'À';
  @override
  String get changeDates => 'Changer les dates';
  @override
  String get endDateMustBeAfterStartDate => 'La date de fin doit être postérieure à la date de début';

  @override
  String get profile => 'Profil';
  @override
  String get userInformation => 'Informations utilisateur';
  @override
  String get defaultTeam => 'Équipe par défaut';
  @override
  String get tenant => 'Tenant';
  @override
  String get language => 'Langue';
  @override
  String get appLanguage => "Langue de l'application";
  @override
  String get logout => 'Déconnexion';
  @override
  String get areYouSureLogout => 'Voulez-vous vous déconnecter ?';
  @override
  String get loadingProfile => 'Chargement du profil';
  @override
  String get retry => 'Réessayer';
  @override
  String get languageChanged => 'Langue modifiée vers';
  @override
  String get appVersion => "Version de l'application";
  @override
  String get copyrightNotice => 'Copyright (c) {year} OneCare. Tous droits réservés.';
  @override
  String get settings => 'Paramètres';
  @override
  String get signOutDescription => 'Se déconnecter de votre compte';
  @override
  String get preferencesAndOptions => 'Préférences et options';
  @override
  String get biometricAuth => 'Authentification biométrique';
  @override
  String get enableBiometric => 'Activer la biométrie';
  @override
  String get biometricLoginReason => 'Veuillez confirmer via biométrie';
  @override
  String get biometricSetupReason => "Configurer l'authentification biométrique";
  @override
  String get biometricEnabled => 'Biométrie activée';
  @override
  String get biometricDisabled => 'Biométrie désactivée';
  @override
  String get resetConfiguration => 'Réinitialiser la Configuration';
  @override
  String get resetConfigurationDescription => 'Effacer la configuration du tenant et retourner au scanner QR';
  @override
  String get resetConfigurationTitle => 'Réinitialiser la Configuration?';
  @override
  String get resetConfigurationMessage => 'Cela effacera la configuration du tenant et vous déconnectera. Vous devrez scanner le code QR à nouveau pour continuer.';
  @override
  String get reset => 'Réinitialiser';

  @override
  String get notifications => 'Notifications';
  @override
  String get noNotifications => 'Aucune notification';
  @override
  String get notificationsWillAppearHere => 'Les notifications apparaitront ici';
  @override
  String get markAllAsRead => 'Tout marquer comme lu';
  @override
  String get clearNotifications => 'Effacer les notifications';
  @override
  String get notificationData => 'Données';
  @override
  String get notification => 'Notification';
  @override
  String get alert => 'Alerte';
  @override
  String get maintenanceWindowTitle => 'Fenêtre de maintenance';
  @override
  String maintenanceWindowBody(String startAt, String endAt) =>
      'Maintenance planifiée de $startAt à $endAt';
  @override
  String get generalInformationTitle => 'Information générale';
  @override
  String ticketUpdatedTitle(String ticketId) => 'Ticket $ticketId mis à jour';
  @override
  String ticketCreatedTitle(String ticketId) => 'Ticket $ticketId créé';
  @override
  String get ticketUpdated => 'Ticket mis à jour';
  @override
  String get changes => 'Changements';
  @override
  String get noChangesToDisplay => 'Aucun changement à afficher';
  @override
  String get viewTicketDetails => 'Voir les Détails du Ticket';
  @override
  String get created => 'Créé';
  @override
  String get newTicketActivityCreated => 'Nouveau ticket/activité créé';
  @override
  String get newTicketCreated => 'Nouveau ticket créé';
  @override
  String get fieldChanged => 'Champ Modifié';
  @override
  String get noteAdded => 'Note ajoutée';
  @override
  String get noteEdited => 'Note modifiée';
  @override
  String get noteRemoved => 'Note supprimée';
  @override
  String get attachmentAdded => 'Pièce jointe ajoutée';
  @override
  String get attachmentRemoved => 'Pièce jointe supprimée';
  @override
  String get extraAttributeAdded => 'Attribut Extra ajouté';
  @override
  String get extraAttributeEdited => 'Attribut Extra modifié';
  @override
  String get extraAttributeRemoved => 'Attribut Extra supprimé';
  @override
  String get ciAdded => 'CI ajouté';
  @override
  String get ciRemoved => 'CI supprimé';
  @override
  String get relationAdded => 'Relation ajoutée';
  @override
  String get relationRemoved => 'Relation supprimée';
  @override
  String get serviceAdded => 'Service ajouté';
  @override
  String get serviceRemoved => 'Service supprimé';
  @override
  String get watcherAdded => 'Observateur ajouté';
  @override
  String get watcherRemoved => 'Observateur supprimé';
  @override
  String get externalTicketAdded => 'Ticket Externe ajouté';
  @override
  String get externalTicketRemoved => 'Ticket Externe supprimé';
  @override
  String get pendencyAdded => 'Dépendance ajoutée';
  @override
  String get pendencyRemoved => 'Dépendance supprimée';
  @override
  String get unknownChange => 'Changement Inconnu';
  @override
  String get unknownField => 'Champ inconnu';
  @override
  String get none => 'Aucun';
  @override
  String get unknownForm => 'Formulaire inconnu';
  @override
  String get unknownAttribute => 'Attribut inconnu';
  @override
  String get unknownUser => 'Utilisateur inconnu';
  @override
  String get unknownId => 'ID Inconnu';
  @override
  String get unknownType => 'Type inconnu';
  @override
  String get addedColon => 'Ajouté';
  @override
  String get removedColon => 'Supprimé';
  @override
  String changedFromTo(String oldValue, String newValue) => 'Modifié de "$oldValue" à "$newValue"';
  @override
  String get updatedBy => 'Mis à jour par';

  @override
  String get yes => 'Oui';
  @override
  String get no => 'Non';
  @override
  String get ok => 'OK';
  @override
  String get error => 'Erreur';
  @override
  String get success => 'Succès';
  @override
  String get loading => 'Chargement';
  @override
  String get na => 'N/A';
  @override
  String get days => 'Jours';
  @override
  String get hours => 'Heures';
  @override
  String get minutes => 'Minutes';
  @override
  String get remaining => 'restant';
  @override
  String get yesterday => 'Hier';
  @override
  String daysAgo(int count) => 'Il y a $count jours';

  // Network Errors
  @override
  String get noInternetConnection => 'Pas de connexion Internet';
  @override
  String get serviceNotReachable => 'Service indisponible, réessayez plus tard';
  @override
  String get checkYourConnection => 'Veuillez vérifier votre connexion et réessayer';

  @override
  String get copyId => "Copier l'ID";
  @override
  String get copyUrl => "Copier l'URL";
  @override
  String get copyToClipboard => 'Copier dans le presse-papiers';
  @override
  String get fcmTokenCopied => 'Jeton FCM copié dans le presse-papiers!';
  @override
  String get fcmTokenNotAvailable => 'Jeton FCM non disponible';
  @override
  String get ticketIdCopied => 'ID copié';
  @override
  String get ticketUrlCopied => 'URL du ticket copiée';
  @override
  String get ticketNotFound => 'Ticket introuvable';
  @override
  String get enterJustification => 'Saisir la justification';
  @override
  String get justificationRequired => 'Justification requise';
  @override
  String get cancellingTicket => 'Annulation du ticket...';
  @override
  String get reopeningTicket => 'Réouverture du ticket...';
  @override
  String get validatingTicket => 'Validation du ticket...';
  @override
  String get cancelTicketJustification => "Justification de l'annulation";
  @override
  String get reopenTicketJustification => "Motif de la réouverture du ticket";
  @override
  String get validateTicketJustification => 'Facultatif : motif de validation du ticket';
  @override
  String get globalInformation => 'Informations générales';
  @override
  String get dates => 'Dates';
  @override
  String get otherInformation => 'Autres informations';
  @override
  String get affectedItem => 'Élément affecté';
  @override
  String get scope => 'Portée';
  @override
  String get scopeTeam => 'Équipe';
  @override
  String get scopeIndividual => 'Individu';
  @override
  String get title => 'Titre';
  @override
  String get subcategory => 'Sous-catégorie';
  @override
  String get equipmentType => "Type d'équipement";
  @override
  String get serviceType => 'Type de service';
  @override
  String get urgency => 'Urgence';
  @override
  String get reportedDate => 'Date signalée';
  @override
  String get modifiedDate => 'Date de modification';
  @override
  String get limitDate => 'Date limite';
  @override
  String get resolvedDate => 'Date de résolution';
  @override
  String get closedDate => 'Date de fermeture';
  @override
  String get files => 'Fichiers';
  @override
  String get uploadFile => 'Téléverser le fichier';
  @override
  String get noFilesAttached => 'Aucun fichier joint';
  @override
  String get unknownFile => 'Fichier inconnu';
  @override
  String get size => 'Taille';
  @override
  String get downloadingFile => 'Téléchargement du fichier...';
  @override
  String get saveFile => 'Enregistrer le fichier';
  @override
  String get downloadCancelled => 'Téléchargement annulé';
  @override
  String get fileSavedSuccessfully => 'Fichier enregistré avec succès';
  @override
  String get failedToDownloadFile => 'Échec du téléchargement du fichier';
  @override
  String get uploadingFile => 'Téléversement du fichier...';
  @override
  String get fileUploadedSuccessfully => 'Fichier téléversé avec succès';
  @override
  String get failedToUploadFile => 'Échec du téléversement du fichier';
  @override
  String get deleteAttachment => 'Supprimer la pièce jointe';
  @override
  String get deleteAttachmentConfirmation => 'Voulez-vous supprimer';
  @override
  String get fileDeletedSuccessfully => 'Fichier supprimé avec succès';
  @override
  String get failedToDeleteFile => 'Échec de la suppression du fichier';
  @override
  String get noNotesAvailable => 'Aucune note disponible';
  @override
  String get editNote => 'Modifier la note';
  @override
  String get editNoteContent => 'Modifier le contenu de la note';
  @override
  String get noteUpdatedSuccessfully => 'Note mise à jour avec succès';
  @override
  String get failedToUpdateNote => 'Échec de la mise à jour de la note';
  @override
  String get noLogsAvailable => 'Aucun journal disponible';
  @override
  String get collapseLogs => 'Réduire les journaux';
  @override
  String get expandLogs => 'Développer les journaux';
  @override
  String get collapseFiles => 'Réduire les fichiers';
  @override
  String get expandFiles => 'Développer les fichiers';
  @override
  String get collapseNotes => 'Réduire les notes';
  @override
  String get expandNotes => 'Développer les notes';
  @override
  String get ticketCreated => 'Ticket créé';
  @override
  String get unknown => 'Inconnu';
  @override
  String get added => 'Ajouté';
  @override
  String get removed => 'Supprimé';
  @override
  String get updated => 'Mis à jour';
  @override
  String get modified => 'Modifié';
  @override
  String get selectUrgency => "Sélectionner l'urgence";
  @override
  String get noImpactOptionsAvailable => "Aucune option d'impact disponible";
  @override
  String get impactUpdatedSuccessfully => 'Impact mis à jour avec succès';
  @override
  String get failedToUpdateImpact => "Échec de la mise à jour de l'impact";
  @override
  String get noUrgencyOptionsAvailable => "Aucune option d'urgence disponible";
  @override
  String get urgencyUpdatedSuccessfully => 'Urgence mise à jour avec succès';
  @override
  String get failedToUpdateUrgency => "Échec de la mise à jour de l'urgence";
  @override
  String get cannotEditImpactAndUrgency => "L'impact et l'urgence ne peuvent pas être modifiés pour ce ticket.";

  @override
  String get externalReference => 'Référence externe';
  @override
  String get externalReferenceOptional => 'Référence externe (optionnel)';
  @override
  String get next => 'Suivant';
  @override
  String get previous => 'Précédent';
  @override
  String get selectType => 'Sélectionner le type';
  @override
  String get selectScope => 'Sélectionner la portée';
  @override
  String get selectAffectedItem => "Sélectionner l'élément affecté";
  @override
  String get selectEquipmentOrService => "Sélectionner l'équipement ou le service";
  @override
  String get searchEquipment => 'Rechercher un équipement...';
  @override
  String get searchService => 'Rechercher un service...';
  @override
  String get selectCategory => 'Sélectionner la catégorie';
  @override
  String get searchCategories => 'Rechercher des catégories...';
  @override
  String get noCategoriesAvailable => 'Aucune catégorie disponible';
  @override
  String get selectSubcategory => 'Sélectionner la sous-catégorie';
  @override
  String get searchSubcategories => 'Rechercher des sous-catégories...';
  @override
  String get noSubcategoriesAvailable => 'Aucune sous-catégorie disponible';
  @override
  String get searchImpacts => 'Rechercher des impacts...';
  @override
  String get searchSeverities => 'Rechercher des gravités...';
  @override
  String get titleRequired => 'Titre *';
  @override
  String get descriptionOptional => 'Description (optionnel)';
  @override
  String get addFiles => 'Ajouter des fichiers';
  @override
  String get removeFile => 'Retirer';
  @override
  String get reviewTicket => 'Examiner le ticket';
  @override
  String get reviewAllInformation => 'Veuillez vérifier toutes les informations avant de créer le ticket';
  String get submittingTicket => 'Envoi de votre ticket...';
  @override
  String get pleaseEnterTitle => 'Veuillez saisir un titre';
  @override
  String get errorLoadingCategories => 'Erreur lors du chargement des catégories';
  @override
  String get errorLoadingSubcategories => 'Erreur lors du chargement des sous-catégories';
  @override
  String get errorLoadingImpactsAndSeverities => 'Erreur lors du chargement des impacts et gravités';
  @override
  String get creating => 'Création...';
  @override
  String get affectedItemType => "Type d'élément affecté";
  @override
  String get stepReference => 'Référence';
  @override
  String get stepType => 'Type';
  @override
  String get stepScope => 'Portée';
  @override
  String get stepItem => 'Élément';
  @override
  String get stepSelect => 'Sélection';
  @override
  String get stepCategory => 'Catégorie';
  @override
  String get stepSubcategoryShort => 'Sous-catégorie';
  @override
  String get stepImpact => 'Impact';
  @override
  String get stepUrgency => 'Urgence';
  @override
  String get stepDetails => 'Détails';
  @override
  String get stepReview => 'Revue';
  @override
  String get externalReferenceDescription => 'Facultatif : saisissez une référence externe pour ce ticket';
  @override
  String get externalReferenceHint => 'ex.: JIRA-1234, INC0001234';
  @override
  String get externalReferenceInfo => "Ce champ est facultatif. Vous pouvez le laisser vide si vous n'avez pas de référence externe.";
  @override
  String get chooseCaseTypeDescription => 'Choisissez le type de ticket que vous souhaitez créer';
  @override
  String get incidentOptionDescription => 'Signaler un problème ou un incident à résoudre';
  @override
  String get requestOptionDescription => 'Demander un service ou faire une demande générale';
  @override
  String get chooseScopeDescription => 'Pour qui est ce ticket ?';
  @override
  String get scopeIndividualDescription => 'Ce ticket est uniquement pour moi';
  @override
  String get scopeTeamDescription => 'Ce ticket concerne mon équipe';
  @override
  String get affectedItemDescription => 'Quel type d\'élément est affecté ?';
  @override
  String get serviceOptionDescription => 'Un service ou une application est affecté';
  @override
  String get equipmentOptionDescription => 'Un équipement ou matériel est affecté';
  @override
  String get selectEquipmentTitle => "Sélectionner l'équipement";
  @override
  String get selectServiceTitle => 'Sélectionner le service';
  @override
  String get selectItemTitleGeneric => "Sélectionner l'élément";
  @override
  String get selectEquipmentSubtitle => "Recherchez et sélectionnez l'équipement";
  @override
  String get selectServiceSubtitle => "Recherchez et sélectionnez le service";
  @override
  String get selectItemSubtitleGeneric => "Recherchez et sélectionnez l'élément";
  @override
  String get chooseCategoryDescription => 'Choisissez la catégorie pour ce ticket';
  @override
  String get chooseSubcategoryDescription => 'Choisissez la sous-catégorie pour ce ticket';
  @override
  String get chooseImpactDescription => "Choisissez le niveau d'impact pour ce ticket";
  @override
  String get chooseUrgencyDescription => "Choisissez le niveau d'urgence pour ce ticket";
  @override
  String get provideDetailsAndAttachments => 'Fournissez les détails du ticket et les pièces jointes';
  @override
  String get enterTicketTitle => 'Saisir le titre du ticket';
  @override
  String get enterTicketDescription => 'Saisir la description du ticket';
  @override
  String get noFilesSelectedMessage => 'Aucun fichier sélectionné. Vous pouvez joindre des fichiers à ce ticket.';
  @override
  String get errorSelectingFiles => 'Erreur lors de la sélection des fichiers';

  // Log attribute translations
  @override
  String get logAttrCis => 'Équipement';
  @override
  String get logAttrStatus => 'Statut';
  @override
  String get logAttrNotes => 'Notes';
  @override
  String get logAttrAttachments => 'Pièces jointes';
  @override
  String get logAttrPriority => 'Priorité';
  @override
  String get logAttrSeverity => 'Gravité';
  @override
  String get logAttrImpact => 'Impact';
  @override
  String get logAttrCategory => 'Catégorie';
  @override
  String get logAttrSubcategory => 'Sous-catégorie';
  @override
  String get logAttrDescription => 'Description';
  @override
  String get logAttrName => 'Titre';
  @override
  String get logAttrServices => 'Services';
  @override
  String get logAttrAssignedTo => 'Attribué à';
  @override
  String get logAttrTeam => 'Équipe';
  @override
  String get welcomeToSigoOneCare => 'Bienvenue sur SIGO OneCare';
  @override
  String get scanConfigurationQrDescription =>
      'Scannez le code QR de configuration pour commencer';
  @override
  String get scanQrCodeButton => 'Scanner le code QR';
  @override
  String get search => 'Rechercher';
  @override
  String get scanQrCodeTitle => 'Scanner le code QR de configuration';
  @override
  String get pointCameraAtQr => 'Pointez votre caméra vers le code QR';
  @override
  String get configurationScannedAutomatically => 'La configuration sera scannée automatiquement';
  @override
  String get processingConfiguration => 'Traitement de la configuration...';
  @override
  String get invalidQrCodeFormat => 'Format de code QR invalide';
  @override
  String get failedToProcessQrCode => 'Echec du traitement du code QR';
  @override
  String get sessionExpired => 'Session invalide. Veuillez vous reconnecter.';

  @override
  String fieldRequired(String fieldName) => '$fieldName est requis';
  @override
  String fieldTooShort(String fieldName, int minLength) =>
      '$fieldName doit contenir au moins $minLength caractères';
  @override
  String fieldTooLong(String fieldName, int maxLength) =>
      '$fieldName ne doit pas dépasser $maxLength caractères';
  @override
  String get invalidEmailFormat => 'Format d\'e-mail invalide';
  @override
  String get invalidPhoneFormat => 'Format de téléphone invalide';
  @override
  String fieldMustBeNumeric(String fieldName) =>
      '$fieldName doit être un nombre';
  @override
  String fieldOutOfRange(String fieldName, double min, double max) =>
      '$fieldName doit être entre $min et $max';

  // Team Selection
  @override
  String get selectTeam => 'Sélectionner l\'équipe';
  @override
  String get selectTeamDescription => 'Choisissez l\'équipe pour ce ticket';
  @override
  String get noTeamsAvailable => 'Aucune équipe disponible';
}
