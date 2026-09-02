import 'package:flutter_test/flutter_test.dart';
import 'package:kiwi_inventory/core/models/lot.dart';

void main() {
  group('SizeGrade', () {
    test('DB値からのラベル変換', () {
      expect(SizeGrade.s.label, 'S');
      expect(SizeGrade.m.label, 'M');
      expect(SizeGrade.l.label, 'L');
      expect(SizeGrade.twoL.label, '2L');
    });

    test('fromDbが既知の値を正しく変換する', () {
      expect(SizeGradeX.fromDb('S'), SizeGrade.s);
      expect(SizeGradeX.fromDb('2L'), SizeGrade.twoL);
    });

    test('fromDbが未知/null値に対してnullを返す', () {
      expect(SizeGradeX.fromDb(null), isNull);
      expect(SizeGradeX.fromDb('XL'), isNull);
    });

    test('dbValueが往復変換できる', () {
      for (final grade in SizeGrade.values) {
        expect(SizeGradeX.fromDb(grade.dbValue), grade);
      }
    });
  });
}
