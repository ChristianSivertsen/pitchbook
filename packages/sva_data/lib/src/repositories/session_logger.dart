import 'package:drift/drift.dart';
import 'package:sva_core/sva_core.dart';
import 'package:sva_data/src/attributes/attribute_repository.dart';
import 'package:sva_data/src/database/sva_database.dart';
import 'package:sva_data/src/ids.dart';
import 'package:sva_data/src/repositories/repository.dart';
import 'package:sva_data/src/repositories/session_repositories.dart';

/// One climb as the log sheet fills it in. Details are value keys from
/// the attribute definitions (`feel.hard`, `tag.pumpy`).
final class ClimbDraft {
  const new({
    required this.routeId,
    required this.style,
    required this.tries,
    required this.ascentType,
    this.feel,
    this.personalGradeId,
    this.tags = const [],
    this.qualityStars,
  });

  final String routeId;
  final AscentStyle style;
  final int tries;

  /// `lead`, `follow`, `toprope`, `boulder` and the other ascent types.
  final String ascentType;
  final String? feel;
  final String? personalGradeId;
  final List<String> tags;

  /// 0 to 3.
  final int? qualityStars;
}

/// A session as the log sheet fills it in.
final class SessionDraft {
  const new({
    required this.localDate,
    required this.tz,
    required this.visibility,
    required this.climbs,
    this.title,
    this.description,
    this.conditions,
    this.partners = const [],
  });

  /// `YYYY-MM-DD` in the session's own time zone.
  final String localDate;

  /// IANA time zone, such as `Europe/Oslo`.
  final String tz;
  final String visibility;

  /// In the order they were climbed.
  final List<ClimbDraft> climbs;
  final String? title;
  final String? description;

  /// A `condition.*` value key.
  final String? conditions;

  /// Partners' names, stored on this device only until tagging (M13).
  final List<String> partners;
}

/// Thrown when a climb breaks the style and tries rules (M1-4).
class ClimbRejected implements Exception {
  new(this.index, this.issues);

  /// Which climb in [SessionDraft.climbs], from 0.
  final int index;
  final List<AscentIssue> issues;

  @override
  String toString() => 'ClimbRejected: climb $index $issues';
}

/// Ascent types the log sheet offers outdoors.
const outdoorAscentTypes = {'lead', 'follow', 'toprope', 'solo', 'boulder'};

/// Most partners on one session, and longest texts, in characters.
const maxPartners = 20;
const maxTitleLength = 120;
const maxDescriptionLength = 2000;
const maxPartnerNameLength = 80;

/// Saves an outdoor session with all its climbs in one transaction, so a
/// half-logged session never reaches sync. Everything is checked here, at
/// the boundary: bad values throw [ArgumentError] naming the field, a climb
/// that breaks the style and tries rules throws [ClimbRejected], and in
/// both cases nothing is written.
class SessionLogger {
  new(SvaDatabase db, {DateTime Function()? clock})
    : this._(db, clock ?? (() => DateTime.now().toUtc()));

  new _(this.db, this.clock)
    : _sessions = SessionRepository(db, clock: clock),
      _ascents = AscentRepository(db, clock: clock),
      _attributes = AttributeRepository(db, clock: clock);

  final SvaDatabase db;
  final DateTime Function() clock;
  final SessionRepository _sessions;
  final AscentRepository _ascents;
  final AttributeRepository _attributes;

  /// Logs [draft] for [userId]. Returns the session's id.
  ///
  /// The climbs are checked against everything already logged on each
  /// route, as if this session came last. Logging a session before others
  /// on the same route is part of editing past sessions (M2-6).
  Future<String> logOutdoor(
    SessionDraft draft, {
    required String userId,
  }) async {
    if (draft.climbs.isEmpty) {
      throw ArgumentError.value(draft.climbs, 'climbs', 'none');
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(draft.localDate) ||
        DateTime.tryParse(draft.localDate) == null) {
      throw ArgumentError.value(draft.localDate, 'localDate');
    }
    if (!RegExp(r'^[A-Za-z_+\-]+(/[A-Za-z0-9_+\-]+)*$').hasMatch(draft.tz)) {
      throw ArgumentError.value(draft.tz, 'tz');
    }
    checkVisibility(draft.visibility);
    final title = _text(draft.title, maxTitleLength, 'title');
    final description = _text(
      draft.description,
      maxDescriptionLength,
      'description',
    );
    if (draft.partners.length > maxPartners) {
      throw ArgumentError.value(draft.partners.length, 'partners');
    }
    final partners = [
      for (final name in draft.partners)
        ?_text(name, maxPartnerNameLength, 'partners'),
    ];
    final sessionDefs = await _attributes.definitions(
      level: AttributeLevel.session,
    );
    _checkValue(sessionDefs, 'conditions', draft.conditions);
    final ascentDefs = await _attributes.definitions(
      level: AttributeLevel.ascent,
    );
    for (final climb in draft.climbs) {
      if (!outdoorAscentTypes.contains(climb.ascentType)) {
        throw ArgumentError.value(climb.ascentType, 'ascentType');
      }
      if (climb.qualityStars case final stars? when stars < 0 || stars > 3) {
        throw ArgumentError.value(stars, 'qualityStars');
      }
      _checkValue(ascentDefs, 'feel', climb.feel);
      for (final tag in climb.tags) {
        _checkValue(ascentDefs, 'tag', tag);
      }
    }

    return await db.transaction(() async {
      await _checkRules(draft.climbs, userId);
      final sessionId = await _sessions.create(
        SessionsCompanion(
          setting: const Value('outdoor'),
          localDate: Value(draft.localDate),
          tz: Value(draft.tz),
          visibility: Value(draft.visibility),
          title: Value(title),
          description: Value(description),
          conditions: Value(draft.conditions),
        ),
        userId: userId,
      );
      for (final (i, climb) in draft.climbs.indexed) {
        if (climb.personalGradeId case final grade?) {
          await _checkGrade(grade, climb.routeId);
        }
        final ascentId = await _ascents.create(
          AscentsCompanion(
            sessionId: Value(sessionId),
            routeId: Value(climb.routeId),
            ordinal: Value(i + 1),
            ascentType: Value(climb.ascentType),
            style: Value(climb.style.name),
            tries: Value(climb.tries),
            feel: Value(climb.feel),
            personalGradeId: Value(climb.personalGradeId),
            qualityStars: Value(climb.qualityStars),
          ),
          userId: userId,
        );
        if (climb.tags.isNotEmpty) {
          await _attributes.setAscentAttribute(
            ascentId,
            'tag',
            climb.tags,
            userId: userId,
          );
        }
      }
      final now = clock();
      for (final name in partners) {
        await db
            .into(db.sessionMembers)
            .insert(
              SessionMembersCompanion.insert(
                id: newId(),
                createdAt: now,
                updatedAt: now,
                ownerId: userId,
                visibility: draft.visibility,
                sessionId: sessionId,
                guestName: Value(name),
                status: 'guest',
                invitedBy: Value(userId),
              ),
            );
      }
      return sessionId;
    });
  }

  /// Checks each climb against the route's logged history and the climbs
  /// before it in this session.
  Future<void> _checkRules(List<ClimbDraft> climbs, String userId) async {
    final logs = <String, List<LoggedAscent>>{};
    for (final (i, climb) in climbs.indexed) {
      final route = await (db.select(
        db.routes,
      )..where((r) => r.id.equals(climb.routeId))).getSingleOrNull();
      if (route == null || route.kind != 'outdoor') {
        throw ArgumentError.value(climb.routeId, 'routeId');
      }
      final log = logs[climb.routeId] ??= await _ascents.routeLog(
        climb.routeId,
        userId: userId,
      );
      final issues = RouteHistory.from(
        log,
        boulder: route.discipline == 'boulder',
      ).check((style: climb.style, tries: climb.tries));
      if (issues.isNotEmpty) throw ClimbRejected(i, issues);
      log.add((style: climb.style, tries: climb.tries));
    }
  }

  /// A personal grade must be a grade of the route's kind (route or
  /// boulder).
  Future<void> _checkGrade(String gradeId, String routeId) async {
    final row = await db
        .customSelect(
          'SELECT s.grade_type, r.discipline FROM grades g '
          'JOIN grade_systems s ON s.key = g.system_key '
          'AND s.deleted_at IS NULL '
          'JOIN routes r ON r.id = ?2 '
          'WHERE g.id = ?1 AND g.deleted_at IS NULL',
          variables: [
            Variable.withString(gradeId),
            Variable.withString(routeId),
          ],
          readsFrom: {db.grades, db.gradeSystems, db.routes},
        )
        .getSingleOrNull();
    final wanted = row?.read<String>('discipline') == 'boulder'
        ? 'boulder'
        : 'free_route';
    if (row?.read<String>('grade_type') != wanted) {
      throw ArgumentError.value(gradeId, 'personalGradeId');
    }
  }

  /// [raw] trimmed, `null` when empty, or [ArgumentError] when too long.
  static String? _text(String? raw, int max, String field) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    if (text.length > max) throw ArgumentError.value(raw, field, 'too long');
    return text;
  }

  static void _checkValue(List<AttributeDef> defs, String key, String? value) {
    if (value == null) return;
    final def = defs.where((d) => d.key == key).firstOrNull;
    if (def == null || !def.accepts([value])) {
      throw ArgumentError.value(value, key);
    }
  }
}
