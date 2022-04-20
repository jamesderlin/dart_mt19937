// ignore_for_file: public_member_api_docs

// Original implementation copyright (C) 2004, Makoto Matsumoto and Takuji
// Nishimura.  All rights reserved.
//
// Port to Dart copyright (C) 2022 James D. Lin.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//
//   1. Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//
//   2. Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in the
//      documentation and/or other materials provided with the distribution.
//
//   3. The names of its contributors may not be used to endorse or promote
//      products derived from this software without specific prior written
//      permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER
// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/// An implementation of Mersenne Twister 19937-64.
class MersenneTwisterEngine {
  /// Word size.
  final int w;

  /// Mask for [w] bits.
  late final _wordMask = (BigInt.one << w) - BigInt.one;

  /// The maximum value that returnable by [call()].
  late final max = _wordMask;

  /// Separation point of a word (the "twist value").
  final int r;

  /// Least-significant `r` bits.
  late final _lowerMask = (BigInt.one << r) - BigInt.one;

  /// Most significant `w - r` bits.
  late final _upperMask = _wordMask & ~_lowerMask;

  /// Degree of recurrence.
  final int n;

  /// Recurrence offset.
  final int m;

  /// Coefficients of the rational normal form twist matrix.
  final BigInt a;

  /// Tempering right shift amount.
  final int u;

  /// Tempering mask.
  final BigInt d;

  /// Tempering left shift amount.
  final int s;

  /// Tempering mask.
  final BigInt b;

  /// Tempering left shift amount.
  final int t;

  /// Tempering mask.
  final BigInt c;

  /// Tempering right shift amount.
  final int l;

  /// Initialization multiplier.
  final BigInt f;

  /// Initialization multiplier when seeding from a sequence.
  final BigInt f1;

  /// Initialization multiplier when seeding from a sequence.
  final BigInt f2;

  static const defaultSeed = 5489;

  static const _sequenceInitialSeed = 19650218;

  /// The state vector.
  late final _state = List<BigInt>.filled(n, BigInt.zero);

  // `n + 1` is a sentinel value to indicate that `_state` is not initialized.
  late int _stateIndex = n + 1;

  // Constructs a Mersenne Twister generator.
  MersenneTwisterEngine.custom({
    required this.w,
    required this.r,
    required this.n,
    required this.m,
    required this.a,
    required this.u,
    required this.d,
    required this.s,
    required this.b,
    required this.t,
    required this.c,
    required this.l,
    required this.f,
    required this.f1,
    required this.f2,
  });

  // Constructs an MT19937 generator.
  MersenneTwisterEngine.w32()
      : this.custom(
          w: 32,
          r: 31,
          n: 624,
          m: 397,
          a: BigInt.from(0x9908B0DF),
          u: 11,
          d: BigInt.from(0xFFFFFFFF),
          s: 7,
          b: BigInt.from(0x9D2C5680),
          t: 15,
          c: BigInt.from(0xEFC60000),
          l: 18,
          f: BigInt.from(1812433253),
          f1: BigInt.from(1664525),
          f2: BigInt.from(1566083941),
        );

  // Constructs an MT19937-64 generator.
  MersenneTwisterEngine.w64()
      : this.custom(
          w: 64,
          r: 31,
          n: 312,
          m: 156,
          a: BigInt.parse('0xB5026F5AA96619E9'),
          u: 29,
          d: BigInt.parse('0x5555555555555555'),
          s: 17,
          b: BigInt.parse('0x71D67FFFEDA60000'),
          t: 37,
          c: BigInt.parse('0xFFF7EEE000000000'),
          l: 43,
          f: BigInt.parse('6364136223846793005'),
          f1: BigInt.parse('3935559000370003845'),
          f2: BigInt.parse('2862933555777941757'),
        );

  /// Initializes the [MersenneTwisterEngine] from a seed.
  void init(BigInt seed) {
    _state[0] = seed;
    for (_stateIndex = 1; _stateIndex < n; _stateIndex += 1) {
      // See Knuth TAOCP Vol2. 3rd Ed. P.106 for multiplier.
      // In the previous versions, MSBs of the seed affect
      // only MSBs of the array mt[].
      _state[_stateIndex] =
          f * (_state[_stateIndex - 1] ^ (_state[_stateIndex - 1] >> (w - 2))) +
              BigInt.from(_stateIndex);
      _state[_stateIndex] &= _wordMask;
    }
  }

  /// Initializes the [MersenneTwisterEngine] from a sequence.
  void initFromSequence(List<BigInt> key) {
    init(BigInt.from(_sequenceInitialSeed));

    var i = 1;
    var j = 0;
    for (var k = n > key.length ? n : key.length; k != 0; k -= 1) {
      _state[i] =
          (_state[i] ^ ((_state[i - 1] ^ (_state[i - 1] >> (w - 2))) * f1)) +
              key[j] +
              BigInt.from(j); // Non-linear.
      _state[i] &= _wordMask;
      i += 1;
      j += 1;
      if (i >= n) {
        _state[0] = _state[n - 1];
        i = 1;
      }
      if (j >= key.length) {
        j = 0;
      }
    }
    for (var k = n - 1; k != 0; k -= 1) {
      _state[i] =
          (_state[i] ^ ((_state[i - 1] ^ (_state[i - 1] >> (w - 2))) * f2)) -
              BigInt.from(i); // Non-linear.
      _state[i] &= _wordMask;
      i += 1;
      if (i >= n) {
        _state[0] = _state[n - 1];
        i = 1;
      }
    }

    // MSB is 1; assuring non-zero initial array.
    _state[0] = BigInt.one << (w - 1);
  }

  /// Returns the next random number.
  BigInt call() {
    // Generate [n] words at one time.
    if (_stateIndex >= n) {
      if (_stateIndex == n + 1) {
        init(BigInt.from(defaultSeed));
      }

      int i;
      for (i = 0; i < n - m; i += 1) {
        var x = (_state[i] & _upperMask) | (_state[i + 1] & _lowerMask);
        _state[i] = _state[i + m] ^ (x >> 1) ^ ((x & BigInt.one) * a);
      }
      for (; i < n - 1; i += 1) {
        var x = (_state[i] & _upperMask) | (_state[i + 1] & _lowerMask);
        _state[i] = _state[i + m - n] ^ (x >> 1) ^ ((x & BigInt.one) * a);
      }
      var x = (_state[n - 1] & _upperMask) | (_state[0] & _lowerMask);
      _state[n - 1] = _state[m - 1] ^ (x >> 1) ^ ((x & BigInt.one) * a);

      _stateIndex = 0;
    }

    var x = _state[_stateIndex];
    _stateIndex += 1;

    // Tempering.
    x ^= (x >> u) & d;
    x ^= (x << s) & b;
    x ^= (x << t) & c;
    x ^= x >> l;
    return x;
  }
}
