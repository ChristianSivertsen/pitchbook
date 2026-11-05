import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:sva_ui/sva_ui.dart';

Future<void> main() async {
  Widget card(ThemeData theme) => Theme(
    data: theme,
    child: Material(
      color: theme.scaffoldBackgroundColor,
      child: const Padding(
        padding: EdgeInsets.all(SvaSpace.md),
        child: SizedBox(
          width: 380,
          child: SvaSessionCard(
            place: 'Kolsås',
            when: '17 Oct 2026 · with Kari',
            note: '10 °C · 3 m/s wind',
            title: 'After-work laps',
            description: 'Dry rock after a week of rain.',
            climbs: [
              SvaCardClimb(
                name: 'Hjemmebane',
                detail: 'Sport',
                style: 'flash',
                styleLabel: 'Flash',
                grade: '6',
              ),
              SvaCardClimb(
                name: 'Kveldsløftet',
                detail: 'Sport · 3 pitches',
                style: 'attempt',
                styleLabel: 'Attempt',
                grade: '7-',
              ),
              SvaCardClimb(
                name: 'Skiferdiederet',
                detail: 'Trad',
                style: 'onsight',
                styleLabel: 'Onsight',
                grade: '5+',
              ),
            ],
            more: '+2 more climbs',
            tags: ['Face', 'Crimps', 'Pumpy'],
            stats: [
              SvaCardStat(value: '5', label: 'Pitches'),
              SvaCardStat(value: '135', unit: 'm', label: 'Climbed'),
              SvaCardStat(value: '240', unit: 'm', label: 'Elevation gain'),
            ],
            openLabel: 'Open session',
          ),
        ),
      ),
    ),
  );

  await goldenTest(
    'M2-7: session card in both themes',
    fileName: 'session_card',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        GoldenTestScenario(
          name: 'Midnight sun',
          child: card(SvaTheme.midnight()),
        ),
        GoldenTestScenario(name: 'Daylight', child: card(SvaTheme.daylight())),
      ],
    ),
  );
}
