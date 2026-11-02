/// Climbing seasons, by stable key (`season.spring` and so on).
enum Season {
  spring,
  summer,
  autumn,
  winter;

  String get key => 'season.$name';
}

/// The meteorological season of [day] at [latitude]: in the northern
/// hemisphere, spring is March to May, summer June to August, autumn
/// September to November and winter December to February. South of the
/// equator they are the other way round. The equator itself counts as
/// north, so every place gets a season.
Season seasonOf(DateTime day, {required double latitude}) {
  const north = [
    Season.winter, Season.winter, Season.spring, // Jan–Mar
    Season.spring, Season.spring, Season.summer, // Apr–Jun
    Season.summer, Season.summer, Season.autumn, // Jul–Sep
    Season.autumn, Season.autumn, Season.winter, // Oct–Dec
  ];
  final season = north[day.month - 1];
  if (latitude >= 0) return season;
  return switch (season) {
    Season.spring => Season.autumn,
    Season.summer => Season.winter,
    Season.autumn => Season.spring,
    Season.winter => Season.summer,
  };
}
