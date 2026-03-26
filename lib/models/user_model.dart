class UserModel {
  final int userId;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? phone;
  final String? address;
  final String? avatar;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.phone,
    this.address,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: json['user_id'] ?? 0,
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'customer',
        status: json['status'] ?? 'active',
        phone: json['phone'],
        address: json['address'],
        avatar: json['avatar'],
      );

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'shop manager';
  bool get isStaff => role == 'staff';
  bool get isCustomer => role == 'customer';
}
