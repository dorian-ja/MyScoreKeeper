import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_score_keeper/l10n/app_localizations.dart';
import 'package:my_score_keeper/utils/player_names.dart';
import 'package:my_score_keeper/widgets/number_stepper.dart';

void main() {
  testWidgets('NumberStepper incrémente et respecte les bornes', (
    tester,
  ) async {
    var value = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => NumberStepper(
              value: value,
              min: 1,
              max: 2,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );

    // + une fois : passe à 2 (max).
    await tester.tap(find.bySemanticsLabel('Augmenter'));
    await tester.pump();
    expect(value, 2);

    // Au max, le bouton + est désactivé : la valeur ne bouge plus.
    await tester.tap(find.bySemanticsLabel('Augmenter'));
    await tester.pump();
    expect(value, 2);

    // - une fois : revient à 1.
    await tester.tap(find.bySemanticsLabel('Diminuer'));
    await tester.pump();
    expect(value, 1);
  });

  testWidgets('ensureUniqueNames signale un doublon via SnackBar', (
    tester,
  ) async {
    late BuildContext ctx;
    bool? lastResult;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    // Noms distincts : valide, aucun SnackBar.
    lastResult = ensureUniqueNames(ctx, ['Alice', 'Bob']);
    await tester.pump();
    expect(lastResult, isTrue);
    expect(find.textContaining('utilisé plusieurs fois'), findsNothing);

    // Doublon (casse différente) : invalide, SnackBar affiché.
    lastResult = ensureUniqueNames(ctx, ['Marie', 'marie']);
    await tester.pump();
    expect(lastResult, isFalse);
    expect(find.textContaining('utilisé plusieurs fois'), findsOneWidget);
  });
}
