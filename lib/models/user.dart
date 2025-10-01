class User {
  final String name;
  final String employeeId;
  final String department;
  final String designation;
  final String officeCode;
  final String location;
  final String username;

  User({
    required this.name,
    required this.employeeId,
    required this.department,
    required this.designation,
    required this.officeCode,
    required this.location,
    required this.username,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      employeeId: json['employeeId'] ?? '',
      department: json['department'] ?? '',
      designation: json['designation'] ?? '',
      officeCode: json['officeCode'] ?? '',
      location: json['location'] ?? '',
      username: json['username'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'employeeId': employeeId,
      'department': department,
      'designation': designation,
      'officeCode': officeCode,
      'location': location,
      'username': username,
    };
  }
}
