import '../../domain/entities/user_entity.dart';

class EmployeeModel extends EmployeeEntity {
  const EmployeeModel({
    required super.id,
    super.employeeCode,
    required super.name,
    super.email,
    super.phone,
    super.jobTitle,
    super.department,
    super.branch,
    super.photoUrl,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      employeeCode: json['employee_code'] != null
          ? (json['employee_code'] is int
              ? json['employee_code']
              : int.tryParse(json['employee_code'].toString()))
          : null,
      name: json['emp_name']?.toString() ?? json['name']?.toString() ?? '',
      email: json['emp_email']?.toString() ?? json['email']?.toString(),
      phone: json['emp_home_tel']?.toString() ?? json['phone']?.toString(),
      jobTitle: json['job_category']?['name']?.toString() ?? json['job_title']?.toString(),
      department: json['department']?['name']?.toString() ?? json['department_name']?.toString(),
      branch: json['branch']?['name']?.toString() ?? json['branch_name']?.toString(),
      photoUrl: json['image_path']?.toString() ?? json['photo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_code': employeeCode,
      'emp_name': name,
      'emp_email': email,
      'emp_home_tel': phone,
      'job_title': jobTitle,
      'department_name': department,
      'branch_name': branch,
      'image_path': photoUrl,
    };
  }
}

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.username,
    super.email,
    required super.role,
    super.companyId,
    super.employeeId,
    super.employee,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    EmployeeModel? employee;
    if (json['employee'] != null && json['employee'] is Map<String, dynamic>) {
      employee = EmployeeModel.fromJson(json['employee'] as Map<String, dynamic>);
    }

    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? 'employee',
      companyId: json['company_id'] != null
          ? (json['company_id'] is int
              ? json['company_id']
              : int.tryParse(json['company_id'].toString()))
          : null,
      employeeId: json['employee_id'] != null
          ? (json['employee_id'] is int
              ? json['employee_id']
              : int.tryParse(json['employee_id'].toString()))
          : null,
      employee: employee,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'company_id': companyId,
      'employee_id': employeeId,
      if (employee != null && employee is EmployeeModel)
        'employee': (employee as EmployeeModel).toJson(),
    };
  }
}
