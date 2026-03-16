import 'dart:io';

import 'package:hive/hive.dart';
import 'package:run_check/services/weather_cache_service.dart';
import 'package:run_check/services/weather_service.dart';
import 'package:run_check/tools/phase1_smoke_test.dart';

Future<void> main() async {
  final hiveDirectory = await Directory.systemTemp.createTemp(
    'run_check_phase1_',
  );

  try {
    Hive.init(hiveDirectory.path);
    final out = stdout;

    final cacheService = WeatherCacheService();
    final hadFreshCache =
        await cacheService.getFreshForecast(
          Phase1SmokeTestRunner.northamptonLat,
          Phase1SmokeTestRunner.northamptonLng,
        ) !=
        null;

    final weatherService = WeatherService(cacheService: cacheService);
    final runner = Phase1SmokeTestRunner(
      fetchForecast: weatherService.fetchHourlyForecast,
      hadFreshCache: hadFreshCache,
      output: out.writeln,
      errorOutput: stderr.writeln,
    );
    exitCode = await runner.run();
  } finally {
    if (Hive.isBoxOpen(WeatherCacheService.boxName)) {
      await Hive.box<dynamic>(WeatherCacheService.boxName).close();
    }
    await hiveDirectory.delete(recursive: true);
  }
}
