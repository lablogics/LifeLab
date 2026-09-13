import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'models/totp_model.dart';

class TotpState {
  final List<TotpModel> entries;
  final Map<String, String> currentCodes;
  final bool isLoading;
  final String? error;

  const TotpState({this.entries = const [], this.currentCodes = const {}, this.isLoading = false, this.error});

  TotpState copyWith({List<TotpModel>? entries, Map<String, String>? currentCodes, bool? isLoading, String? error}) {
    return TotpState(entries: entries ?? this.entries, currentCodes: currentCodes ?? this.currentCodes, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class TotpNotifier extends StateNotifier<TotpState> {
  final ApiClient _api;
  TotpNotifier(this._api) : super(const TotpState()) { loadEntries(); }

  Future<void> loadEntries() async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get(Endpoints.totp);
      final list = (r.data as List).map((e) => TotpModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(entries: list, isLoading: false);
      generateAllCodes();
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }

  void generateAllCodes() {
    final codes = <String, String>{};
    for (final entry in state.entries) {
      codes[entry.id] = generateTotp(entry.secret, entry.period, entry.digits);
    }
    state = state.copyWith(currentCodes: codes);
  }

  Future<void> createEntry(TotpModel entry) async {
    try {
      await _api.dio.dio.post(Endpoints.totp, data: entry.toJson());
      await loadEntries();
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _api.dio.dio.delete('${Endpoints.totp}/$id');
      await loadEntries();
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  static String generateTotp(String base32Secret, int period, int digits) {
    final secret = _base32Decode(base32Secret.toUpperCase().replaceAll(' ', ''));
    final counter = (DateTime.now().millisecondsSinceEpoch ~/ 1000) ~/ period;
    final bytes = ByteData(8);
    bytes.setUint64(0, counter, Endian.big);
    final hash = Hmac(sha1, secret).convert(bytes.buffer.asUint8List()).bytes;
    final offset = hash[hash.length - 1] & 0xf;
    final code = ((hash[offset] & 0x7f) << 24) | ((hash[offset + 1] & 0xff) << 16) | ((hash[offset + 2] & 0xff) << 8) | (hash[offset + 3] & 0xff);
    final otp = code % _pow10(digits);
    return otp.toString().padLeft(digits, '0');
  }

  static int _pow10(int n) { int r = 1; for (int i = 0; i < n; i++) { r *= 10; } return r; }

  static Uint8List _base32Decode(String input) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final output = <int>[];
    var buffer = 0;
    var bitsLeft = 0;
    for (final c in input.codeUnits) {
      final val = alphabet.indexOf(String.fromCharCode(c));
      if (val < 0) continue;
      buffer = (buffer << 5) | val;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        output.add((buffer >> (bitsLeft - 8)) & 0xff);
        bitsLeft -= 8;
      }
    }
    return Uint8List.fromList(output);
  }
}

final totpProvider = StateNotifierProvider<TotpNotifier, TotpState>((ref) {
  return TotpNotifier(ref.watch(apiClientProvider));
});
