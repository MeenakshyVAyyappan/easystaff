import 'package:flutter_test/flutter_test.dart';
import 'package:eazystaff/services/auth_service.dart';

void main() {
  group('AppUser.fromJson', () {
    test('extracts employee_id from login response', () {
      final json = {
        'name': 'Admin User',
        'username': 'admin',
        'employee_id': '2',
        'department': 'IT',
        'designation': 'Manager',
        'office_code': 'HQ',
        'office_id': '1',
        'financial_year_id': '2025',
        'location': 'Mumbai',
      };

      final user = AppUser.fromJson(json);

      expect(user.employeeId, equals('2'),
          reason: 'Should extract employee_id as numeric string');
      expect(user.name, equals('Admin User'));
      expect(user.username, equals('admin'));
    });

    test('extracts emp_id as fallback', () {
      final json = {
        'name': 'Test User',
        'username': 'testuser',
        'emp_id': '5',
        'department': 'Sales',
      };

      final user = AppUser.fromJson(json);

      expect(user.employeeId, equals('5'),
          reason: 'Should extract emp_id when employee_id is missing');
    });

    test('extracts empid as fallback', () {
      final json = {
        'name': 'Test User',
        'username': 'testuser',
        'empid': '10',
      };

      final user = AppUser.fromJson(json);

      expect(user.employeeId, equals('10'),
          reason: 'Should extract empid when employee_id and emp_id are missing');
    });

    test('extracts id as fallback', () {
      final json = {
        'name': 'Test User',
        'username': 'testuser',
        'id': '15',
      };

      final user = AppUser.fromJson(json);

      expect(user.employeeId, equals('15'),
          reason: 'Should extract id when other employee ID fields are missing');
    });

    test('extracts userid as fallback', () {
      final json = {
        'name': 'Test User',
        'username': 'testuser',
        'userid': '20',
      };

      final user = AppUser.fromJson(json);

      expect(user.employeeId, equals('20'),
          reason: 'Should extract userid when other employee ID fields are missing');
    });

    test('extracts user_id as fallback', () {
      final json = {
        'name': 'Test User',
        'username': 'testuser',
        'user_id': '25',
      };

      final user = AppUser.fromJson(json);

      expect(user.employeeId, equals('25'),
          reason: 'Should extract user_id when other employee ID fields are missing');
    });

    test('extracts eid as fallback', () {
      final json = {
        'name': 'Test User',
        'username': 'testuser',
        'eid': '30',
      };

      final user = AppUser.fromJson(json);

      expect(user.employeeId, equals('30'),
          reason: 'Should extract eid when other employee ID fields are missing');
    });

    test('defaults to empty string when no employee ID field found', () {
      final json = {
        'name': 'Test User',
        'username': 'testuser',
        'department': 'Sales',
      };

      final user = AppUser.fromJson(json);

      expect(user.employeeId, equals(''),
          reason: 'Should default to empty string when no employee ID field is found');
    });

    test('ignores empty employee_id and tries fallbacks', () {
      final json = {
        'name': 'Test User',
        'username': 'testuser',
        'employee_id': '',
        'emp_id': '7',
      };

      final user = AppUser.fromJson(json);

      expect(user.employeeId, equals('7'),
          reason: 'Should skip empty employee_id and use emp_id');
    });

    test('handles numeric employee_id values', () {
      final json = {
        'name': 'Test User',
        'username': 'testuser',
        'employee_id': 42,  // Numeric instead of string
      };

      final user = AppUser.fromJson(json);

      expect(user.employeeId, equals('42'),
          reason: 'Should convert numeric employee_id to string');
    });

    test('extracts all user fields correctly', () {
      final json = {
        'name': 'John Doe',
        'username': 'johndoe',
        'employee_id': '100',
        'department': 'Engineering',
        'designation': 'Senior Developer',
        'office_code': 'NYC',
        'office_id': '5',
        'financial_year_id': '2025-26',
        'location': 'New York',
      };

      final user = AppUser.fromJson(json);

      expect(user.name, equals('John Doe'));
      expect(user.username, equals('johndoe'));
      expect(user.employeeId, equals('100'));
      expect(user.department, equals('Engineering'));
      expect(user.designation, equals('Senior Developer'));
      expect(user.officeCode, equals('NYC'));
      expect(user.officeId, equals('5'));
      expect(user.financialYearId, equals('2025-26'));
      expect(user.location, equals('New York'));
    });

    test('handles alternative field names for all fields', () {
      final json = {
        'full_name': 'Jane Smith',
        'user': 'janesmith',
        'emp_id': '50',
        'dept': 'Marketing',
        'role': 'Manager',
        'officecode': 'LA',
        'officeid': '3',
        'financialyearid': '2024-25',
        'branch': 'Los Angeles',
      };

      final user = AppUser.fromJson(json);

      expect(user.name, equals('Jane Smith'));
      expect(user.username, equals('janesmith'));
      expect(user.employeeId, equals('50'));
      expect(user.department, equals('Marketing'));
      expect(user.designation, equals('Manager'));
      expect(user.officeCode, equals('LA'));
      expect(user.officeId, equals('3'));
      expect(user.financialYearId, equals('2024-25'));
      expect(user.location, equals('Los Angeles'));
    });

    test('toJson preserves employee_id', () {
      final user = AppUser(
        name: 'Test User',
        username: 'testuser',
        employeeId: '123',
        department: 'IT',
        designation: 'Developer',
        officeCode: 'HQ',
        officeId: '1',
        financialYearId: '2025',
        location: 'Mumbai',
      );

      final json = user.toJson();

      expect(json['employee_id'], equals('123'),
          reason: 'toJson should preserve employee_id');
      expect(json['name'], equals('Test User'));
      expect(json['username'], equals('testuser'));
    });
  });
}

