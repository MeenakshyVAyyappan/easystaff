import 'package:flutter_test/flutter_test.dart';
import 'package:eazystaff/services/dashboard_service.dart';

void main() {
  group('DashboardData.fromJson', () {
    test('parses Postman response correctly', () {
      // This is the exact response from Postman
      final json = {
        "flag": true,
        "msg": "Success",
        "userdashboard": {
          "collectioncnt": "232",
          "collectionamt": "1542707.40",
          "pendingamt": 0,
          "salesordercnt": "0",
          "salesorderamt": "0.00"
        }
      };

      final data = DashboardData.fromJson(json);

      // Verify collections are parsed correctly
      expect(data.monthCollections, equals(232),
          reason: 'Collections should be 232 from collectioncnt');

      // Verify customers fallback to salesordercnt
      expect(data.monthCustomers, equals(0),
          reason: 'Customers should be 0 from salesordercnt');

      // Verify visits default to 0 (not in API response)
      expect(data.monthVisits, equals(0),
          reason: 'Visits should be 0 (not provided by API)');

      // Verify todays list is empty (no today data in response)
      expect(data.todays, isEmpty,
          reason: 'Today transactions should be empty');
    });

    test('handles nested userdashboard structure', () {
      final json = {
        "flag": true,
        "msg": "Success",
        "userdashboard": {
          "collectioncnt": "100",
          "collectionamt": "500000.00",
        }
      };

      final data = DashboardData.fromJson(json);
      expect(data.monthCollections, equals(100));
    });

    test('handles flat structure without userdashboard wrapper', () {
      final json = {
        "collectioncnt": "50",
        "collectionamt": "250000.00",
      };

      final data = DashboardData.fromJson(json);
      expect(data.monthCollections, equals(50));
    });

    test('parses string numbers correctly', () {
      final json = {
        "userdashboard": {
          "collectioncnt": "232",  // String
          "salesordercnt": "10",   // String
        }
      };

      final data = DashboardData.fromJson(json);
      expect(data.monthCollections, equals(232));
      expect(data.monthCustomers, equals(10));
    });

    test('handles numeric values', () {
      final json = {
        "userdashboard": {
          "collectioncnt": 232,  // Numeric
          "salesordercnt": 10,   // Numeric
        }
      };

      final data = DashboardData.fromJson(json);
      expect(data.monthCollections, equals(232));
      expect(data.monthCustomers, equals(10));
    });

    test('defaults to 0 for missing fields', () {
      final json = {
        "userdashboard": {
          "collectioncnt": "100",
          // No customercnt or salesordercnt
          // No visitcnt
        }
      };

      final data = DashboardData.fromJson(json);
      expect(data.monthCollections, equals(100));
      expect(data.monthCustomers, equals(0));
      expect(data.monthVisits, equals(0));
    });

    test('parses today transactions when present', () {
      final json = {
        "userdashboard": {
          "collectioncnt": "232",
        },
        "today": [
          {
            "party": "ABC Corp",
            "amount": "5000",
            "time": "10:30 AM"
          },
          {
            "party": "XYZ Ltd",
            "amount": "3000",
            "time": "02:15 PM"
          }
        ]
      };

      final data = DashboardData.fromJson(json);
      expect(data.todays.length, equals(2));
      expect(data.todays[0].party, equals("ABC Corp"));
      expect(data.todays[0].amount, equals(5000));
      expect(data.todays[1].party, equals("XYZ Ltd"));
      expect(data.todays[1].amount, equals(3000));
    });

    test('handles empty today array', () {
      final json = {
        "userdashboard": {
          "collectioncnt": "232",
        },
        "today": []
      };

      final data = DashboardData.fromJson(json);
      expect(data.todays, isEmpty);
    });
  });

  group('TodayTxn.fromJson', () {
    test('parses transaction correctly', () {
      final json = {
        "party": "ABC Corporation",
        "amount": "5000",
        "time": "10:30 AM"
      };

      final txn = TodayTxn.fromJson(json);
      expect(txn.party, equals("ABC Corporation"));
      expect(txn.amount, equals(5000));
      expect(txn.time, equals("10:30 AM"));
    });

    test('handles numeric amount', () {
      final json = {
        "party": "Test Party",
        "amount": 5000,
        "time": "10:30 AM"
      };

      final txn = TodayTxn.fromJson(json);
      expect(txn.amount, equals(5000));
    });

    test('defaults to Unknown party if missing', () {
      final json = {
        "amount": "5000",
        "time": "10:30 AM"
      };

      final txn = TodayTxn.fromJson(json);
      expect(txn.party, equals("Unknown"));
    });
  });
}

