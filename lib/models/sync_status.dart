enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete }

extension SyncStatusExtension on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.synced:
        return 'Sincronizado';
      case SyncStatus.pendingCreate:
        return 'Aguardando criação';
      case SyncStatus.pendingUpdate:
        return 'Aguardando atualização';
      case SyncStatus.pendingDelete:
        return 'Aguardando exclusão';
    }
  }

  bool get hasPendingChanges {
    return this != SyncStatus.synced;
  }
}

SyncStatus parseSyncStatus(String? value) {
  return SyncStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => SyncStatus.pendingCreate,
  );
}
