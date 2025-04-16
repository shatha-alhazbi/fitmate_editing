import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart' hide LottieCache;

class LottieCache {
  static final LottieCache instance = LottieCache._internal();
  
  factory LottieCache() => instance;
  
  LottieCache._internal();

  final Map<String, LottieComposition?> _cache = {};
  final Map<String, bool> _isLoading = {};

  bool isLottieLoaded(String asset) {
    return _cache.containsKey(asset) && _cache[asset] != null;
  }

  bool isLottieLoading(String asset) {
    return _isLoading[asset] == true;
  }

  LottieComposition? getComposition(String asset) {
    return _cache[asset];
  }

  Future<void> precacheAssets(BuildContext context) async {
    try {
      await _loadComposition('assets/data/lottie/celebration_mascot.json');
    } catch (e) {
      print('Error precaching Lottie assets: $e');
    }
  }

  Future<LottieComposition?> _loadComposition(String asset) async {
    if (_cache.containsKey(asset) && _cache[asset] != null) {
      return _cache[asset];
    }
    
    _isLoading[asset] = true;
    
    try {
      final composition = await AssetLottie(asset).load();
      _cache[asset] = composition;
      _isLoading[asset] = false;
      print('Successfully loaded Lottie animation: $asset');
      return composition;
    } catch (e) {
      _isLoading[asset] = false;
      print('Error loading Lottie animation $asset: $e');
      _cache[asset] = null;
      return null;
    }
  }


  void preloadAnimation(String asset) {
    if (!_cache.containsKey(asset) && _isLoading[asset] != true) {
      _loadComposition(asset);
    }
  }
}