import 'package:equatable/equatable.dart';

class EmployeeEntity extends Equatable {
  final int id;
  final int? employeeCode;
  final String name;
  final String? email;
  final String? phone;
  final String? jobTitle;
  final String? department;
  final String? branch;
  final String? photoUrl;

  const EmployeeEntity({
    required this.id,
    this.employeeCode,
    required this.name,
    this.email,
    this.phone,
    this.jobTitle,
    this.department,
    this.branch,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [
        id,
        employeeCode,
        name,
        email,
        phone,
        jobTitle,
        department,
        branch,
        photoUrl,
      ];
}

class UserEntity extends Equatable {
  final int id;
  final String name;
  final String username;
  final String? email;
  final String role;
  final int? companyId;
  final int? employeeId;
  final EmployeeEntity? employee;

  const UserEntity({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    required this.role,
    this.companyId,
    this.employeeId,
    this.employee,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        username,
        email,
        role,
        companyId,
        employeeId,
        employee,
      ];
}
