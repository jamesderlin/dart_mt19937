@TestOn('vm')

import 'dart:convert';
import 'dart:io' as io;

import 'package:mt19937/src/mt19937.dart';
import 'package:mt19937/src/mt19937_64.dart';
import 'package:mt19937/src/mt19937_general.dart';
import 'package:test/test.dart';

/// Returns the absolute path to this `.dart` file.
///
/// Returns `null` if the path could not be determined.
///
/// Note that [io.Platform.script] does not work in tests and also will not
/// work for `import`ed files.
String? _getScriptPath() {
  var filePathRegExp = RegExp(r'(file://.+\.dart)');
  var stackLineIterator = LineSplitter.split(StackTrace.current.toString());
  var match = filePathRegExp.firstMatch(stackLineIterator.first);
  if (match == null) {
    return null;
  }
  return Uri.parse(match.group(1)!).toFilePath();
}

Future<void> main() async {
  var scriptPath = _getScriptPath();
  if (scriptPath != null) {
    io.Directory.current = io.File(scriptPath).parent.parent;
  }

  group('VM implementations:', () {
    group('mt19937:', () {
      test('default seed', () async {
        var mt = MersenneTwister();
        await _compareReferenceOutput(
          mt.call,
          'reference/expected_mt19937_default.txt',
          int.parse,
        );
      });

      test('max seed', () async {
        var seed = (1 << 32) - 1;
        var mt = MersenneTwister(seed: seed);
        await _compareReferenceOutput(
          mt.call,
          'reference/expected_mt19937_max_seed.txt',
          int.parse,
        );
      });
    });

    group('mt19937-64:', () {
      test('default seed', () async {
        var mt = MersenneTwister64();
        await _compareReferenceOutput(
          mt.call,
          'reference/expected_mt19937_64_default.txt',
          BigInt.parse,
        );
      });

      test('max seed', () async {
        var seed = (BigInt.one << 64) - BigInt.one;
        var mt = MersenneTwister64(seed: seed);
        await _compareReferenceOutput(
          mt.call,
          'reference/expected_mt19937_64_max_seed.txt',
          BigInt.parse,
        );
      });
    });
  });

  group('BigInt implementation:', () {
    group('mt19937:', () {
      test('default seed', () async {
        var mt = MersenneTwisterEngine.w32();
        await _compareReferenceOutput(
          mt.call,
          'reference/expected_mt19937_default.txt',
          BigInt.parse,
        );
      });

      test('max seed', () async {
        var seed = (BigInt.one << 32) - BigInt.one;
        var mt = MersenneTwisterEngine.w32()..init(seed);
        await _compareReferenceOutput(
          mt.call,
          'reference/expected_mt19937_max_seed.txt',
          BigInt.parse,
        );
      });
    });

    group('mt19937-64:', () {
      test('default seed', () async {
        var mt = MersenneTwisterEngine.w64();
        await _compareReferenceOutput(
          mt.call,
          'reference/expected_mt19937_64_default.txt',
          BigInt.parse,
        );
      });

      test('max seed', () async {
        var seed = (BigInt.one << 64) - BigInt.one;
        var mt = MersenneTwisterEngine.w64()..init(seed);
        await _compareReferenceOutput(
          mt.call,
          'reference/expected_mt19937_64_max_seed.txt',
          BigInt.parse,
        );
      });
    });
  });
}

Future<void> _compareReferenceOutput<T>(
  T Function() generator,
  String path,
  T Function(String) parser,
) async {
  var expectedValues = io.File(path)
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .map(parser);

  var i = 0;
  await for (var expectedValue in expectedValues) {
    var actualValue = generator();
    expect(actualValue, expectedValue, reason: 'iteration: $i');
    i += 1;
  }
}