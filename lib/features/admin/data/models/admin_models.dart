class AdminUserDto {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final int provider; // enum AuthProvider (0: email, 1: google, 2: github)
  final int role;     // enum UserRole (0: researcher, 1: lecturer, 2: student, 3: admin)
  final int status;   // enum UserStatus (0: active, 1: locked, 2: pending)
  final String? lastLoginAt;
  final String createdAt;
  final String updatedAt;

  AdminUserDto({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.provider,
    required this.role,
    required this.status,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminUserDto.fromJson(Map<String, dynamic> json) {
    return AdminUserDto(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      provider: json['provider'] ?? 0,
      role: json['role'] ?? 2,
      status: json['status'] ?? 0,
      lastLoginAt: json['lastLoginAt'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'avatarUrl': avatarUrl,
      'provider': provider,
      'role': role,
      'status': status,
      'lastLoginAt': lastLoginAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String get roleString {
    switch (role) {
      case 0:
        return 'Researcher';
      case 1:
        return 'Lecturer';
      case 2:
        return 'Student';
      case 3:
        return 'Admin';
      default:
        return 'Student';
    }
  }

  String get statusString {
    switch (status) {
      case 0:
        return 'Active';
      case 1:
        return 'Locked';
      case 2:
        return 'Pending';
      default:
        return 'Active';
    }
  }
}

class ApiSourceDto {
  final String id;
  final String name;
  final String baseUrl;
  final String? apiKeyEncrypted;
  final int rateLimitPerSec;
  final bool isActive;
  final int syncIntervalHours;
  final List<String> supportedFields;
  final String? lastSyncedAt;
  final String createdAt;
  final String updatedAt;

  ApiSourceDto({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.apiKeyEncrypted,
    required this.rateLimitPerSec,
    required this.isActive,
    required this.syncIntervalHours,
    required this.supportedFields,
    this.lastSyncedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiSourceDto.fromJson(Map<String, dynamic> json) {
    return ApiSourceDto(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      baseUrl: json['baseUrl'] ?? '',
      apiKeyEncrypted: json['apiKeyEncrypted'],
      rateLimitPerSec: json['rateLimitPerSec'] ?? 10,
      isActive: json['isActive'] ?? false,
      syncIntervalHours: json['syncIntervalHours'] ?? 24,
      supportedFields: (json['supportedFields'] as List?)?.map((e) => e.toString()).toList() ?? [],
      lastSyncedAt: json['lastSyncedAt'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'apiKeyEncrypted': apiKeyEncrypted,
      'rateLimitPerSec': rateLimitPerSec,
      'isActive': isActive,
      'syncIntervalHours': syncIntervalHours,
      'supportedFields': supportedFields,
      'lastSyncedAt': lastSyncedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class ApiSyncJobDto {
  final String id;
  final String sourceName;
  final String sourceBaseUrl;
  final String? queryParams;
  final String? scheduledAt;
  final String? startedAt;
  final String? finishedAt;
  final String status;
  final int papersFetched;
  final int papersInserted;
  final int papersUpdated;
  final String? errorMessage;
  final String createdAt;

  ApiSyncJobDto({
    required this.id,
    required this.sourceName,
    required this.sourceBaseUrl,
    this.queryParams,
    this.scheduledAt,
    this.startedAt,
    this.finishedAt,
    required this.status,
    required this.papersFetched,
    required this.papersInserted,
    required this.papersUpdated,
    this.errorMessage,
    required this.createdAt,
  });

  factory ApiSyncJobDto.fromJson(Map<String, dynamic> json) {
    return ApiSyncJobDto(
      id: json['id'] ?? '',
      sourceName: json['sourceName'] ?? '',
      sourceBaseUrl: json['sourceBaseUrl'] ?? '',
      queryParams: json['queryParams'],
      scheduledAt: json['scheduledAt'],
      startedAt: json['startedAt'],
      finishedAt: json['finishedAt'],
      status: json['status'] ?? '',
      papersFetched: json['papersFetched'] ?? 0,
      papersInserted: json['papersInserted'] ?? 0,
      papersUpdated: json['papersUpdated'] ?? 0,
      errorMessage: json['errorMessage'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class SystemSettingDto {
  final String key;
  final String value;
  final String? description;
  final String? updatedBy;
  final String updatedAt;

  SystemSettingDto({
    required this.key,
    required this.value,
    this.description,
    this.updatedBy,
    required this.updatedAt,
  });

  factory SystemSettingDto.fromJson(Map<String, dynamic> json) {
    return SystemSettingDto(
      key: json['key'] ?? '',
      value: json['value'] ?? '',
      description: json['description'],
      updatedBy: json['updatedBy'],
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'description': description,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt,
    };
  }
}

class AuditLogDto {
  final String id;
  final String adminUserId;
  final String action;
  final String? entityType;
  final String? entityId;
  final dynamic oldValue;
  final dynamic newValue;
  final String? ipAddress;
  final String createdAt;

  AuditLogDto({
    required this.id,
    required this.adminUserId,
    required this.action,
    this.entityType,
    this.entityId,
    this.oldValue,
    this.newValue,
    this.ipAddress,
    required this.createdAt,
  });

  factory AuditLogDto.fromJson(Map<String, dynamic> json) {
    return AuditLogDto(
      id: json['id'] ?? '',
      adminUserId: json['adminUserId'] ?? '',
      action: json['action'] ?? '',
      entityType: json['entityType'],
      entityId: json['entityId'],
      oldValue: json['oldValue'],
      newValue: json['newValue'],
      ipAddress: json['ipAddress'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}
