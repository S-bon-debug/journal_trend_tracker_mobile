class UserProfileDto {
  final String userId;
  final String? bio;
  final String? institution;
  final List<String> researchFields;
  final String? websiteUrl;

  UserProfileDto({
    required this.userId,
    this.bio,
    this.institution,
    required this.researchFields,
    this.websiteUrl,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      userId: json['userId'] ?? '',
      bio: json['bio'],
      institution: json['institution'],
      researchFields: (json['researchFields'] as List?)?.map((e) => e.toString()).toList() ?? [],
      websiteUrl: json['websiteUrl'],
    );
  }
}

class BookmarkDto {
  final String id;
  final String entityType;
  final String entityId;
  final String entityTitle;
  final String? note;
  final String createdAt;

  BookmarkDto({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
    this.note,
    required this.createdAt,
  });

  factory BookmarkDto.fromJson(Map<String, dynamic> json) {
    return BookmarkDto(
      id: json['id'] ?? '',
      entityType: json['entityType'] ?? '',
      entityId: json['entityId'] ?? '',
      entityTitle: json['entityTitle'] ?? '',
      note: json['note'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class FollowDto {
  final String id;
  final String followType;
  final String targetId;
  final String targetName;
  final bool notifyEmail;
  final bool notifyInapp;
  final String createdAt;

  FollowDto({
    required this.id,
    required this.followType,
    required this.targetId,
    required this.targetName,
    required this.notifyEmail,
    required this.notifyInapp,
    required this.createdAt,
  });

  factory FollowDto.fromJson(Map<String, dynamic> json) {
    return FollowDto(
      id: json['id'] ?? '',
      followType: json['followType'] ?? '',
      targetId: json['targetId'] ?? '',
      targetName: json['targetName'] ?? '',
      notifyEmail: json['notifyEmail'] ?? false,
      notifyInapp: json['notifyInapp'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class NotificationDto {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? relatedId;
  final String? relatedType;
  final bool isRead;
  final String? readAt;
  final String createdAt;

  NotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    this.relatedType,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      relatedId: json['relatedId'],
      relatedType: json['relatedType'],
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class UserAccountDto {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final int role;

  UserAccountDto({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.role,
  });

  factory UserAccountDto.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'];
    int parsedRole = 0;
    if (rawRole is int) {
      parsedRole = rawRole;
    } else if (rawRole is String) {
      final roleStr = rawRole.toLowerCase();
      if (roleStr == 'admin') {
        parsedRole = 3;
      } else if (roleStr == 'student') {
        parsedRole = 2;
      } else if (roleStr == 'lecturer') {
        parsedRole = 1;
      } else if (roleStr == 'researcher') {
        parsedRole = 0;
      } else {
        parsedRole = int.tryParse(roleStr) ?? 0;
      }
    }
    return UserAccountDto(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      role: parsedRole,
    );
  }
}

