import 'package:encore/data/event.dart';
import 'package:encore/ui/widgets/star_rating.dart';
import 'package:encore/ui/widgets/ticket_stub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping a star reports the rating, tapping it again clears it', (tester) async {
    var rating = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (_, setState) => StarRating(value: rating, onChanged: (r) => setState(() => rating = r)),
        ),
      ),
    ));
    await tester.tap(find.byTooltip('4 stars'));
    await tester.pump();
    expect(rating, 4);
    await tester.tap(find.byTooltip('4 stars'));
    await tester.pump();
    expect(rating, 0);
  });

  testWidgets('ticket stub shows the date and title', (tester) async {
    final e = EventItem(id: '1', title: 'Jazz Night', venue: 'Nelum Pokuna', date: DateTime(2026, 12, 12), updatedAt: DateTime.now());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TicketStub(event: e))));
    expect(find.text('Jazz Night'), findsOneWidget);
    expect(find.text('DEC'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });
}
