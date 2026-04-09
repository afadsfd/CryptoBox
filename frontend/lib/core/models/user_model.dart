/// 用户模型
class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? avatar;
  final String subscriptionTier;
  final String authProvider;
  final bool isVerified;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
    this.subscriptionTier = 'free',
    this.authProvider = 'email',
    this.isVerified = false,
    this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    String? subscriptionTier,
    String? authProvider,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      authProvider: authProvider ?? this.authProvider,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'subscription_tier': subscriptionTier,
      'auth_provider': authProvider,
      'is_verified': isVerified,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      avatar: json['avatar'],
      subscriptionTier: json['subscription_tier'] ?? 'free',
      authProvider: json['auth_provider'] ?? 'email',
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}
