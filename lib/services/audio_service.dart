import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  
  bool _bgmEnabled = true;
  bool _sfxEnabled = true;
  double _bgmVolume = 0.5;
  double _sfxVolume = 0.7;

  // BGM 플레이리스트 (무료 CC0 음악)
  final Map<String, String> _bgmTracks = {
    'main': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'gacha': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    'collection': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
  };

  // 효과음 URL (무료 공개 효과음 - 작동 확인됨)
  final Map<String, String> _sfxSounds = {
    'button_click': 'https://cdn.pixabay.com/audio/2021/08/04/audio_0625c1539c.mp3', // ✅ 작동
    'card_pull': 'https://cdn.pixabay.com/audio/2021/08/04/audio_0625c1539c.mp3', // ✅ 작동 (button_click 재사용)
    'card_reveal': 'https://cdn.pixabay.com/audio/2021/08/04/audio_12b0c7443c.mp3', // ✅ 작동
    'success': 'https://cdn.pixabay.com/audio/2021/08/04/audio_12b0c7443c.mp3', // ✅ 작동 (card_reveal 재사용)
    'error': 'https://cdn.pixabay.com/audio/2021/08/04/audio_0625c1539c.mp3', // ✅ 작동 (button_click 재사용)
  };

  bool get bgmEnabled => _bgmEnabled;
  bool get sfxEnabled => _sfxEnabled;
  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> initialize() async {
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_bgmVolume);
      await _sfxPlayer.setVolume(_sfxVolume);
      
      // 웹 플랫폼에서 오디오 컨텍스트 활성화를 위한 준비
      if (kIsWeb) {
        // 빈 소리를 재생하여 오디오 컨텍스트 활성화 준비
        // 실제 재생은 사용자 인터랙션 후에 발생
        if (kDebugMode) {
          print('🌐 Web platform detected - Audio will start on user interaction');
        }
      }
      
      if (kDebugMode) {
        print('✅ AudioService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ AudioService initialization error: $e');
      }
    }
  }

  // BGM 재생
  Future<void> playBGM(String trackName) async {
    if (!_bgmEnabled) {
      if (kDebugMode) {
        print('🔇 BGM disabled, skipping: $trackName');
      }
      return;
    }
    
    try {
      final url = _bgmTracks[trackName];
      if (url == null) {
        if (kDebugMode) {
          print('⚠️ BGM track not found: $trackName');
        }
        return;
      }
      
      if (kDebugMode) {
        print('🎵 Attempting to play BGM: $trackName from $url');
      }
      
      // AudioPlayer 사용 (모든 플랫폼)
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.play(UrlSource(url));
      
      if (kDebugMode) {
        print('✅ BGM playing: $trackName at volume $_bgmVolume');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ BGM play error for $trackName: $e');
      }
    }
  }

  // BGM 중지
  Future<void> stopBGM() async {
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ BGM stop error: $e');
      }
    }
  }

  // BGM 일시정지
  Future<void> pauseBGM() async {
    try {
      await _bgmPlayer.pause();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ BGM pause error: $e');
      }
    }
  }

  // BGM 재개
  Future<void> resumeBGM() async {
    try {
      await _bgmPlayer.resume();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ BGM resume error: $e');
      }
    }
  }

  // 효과음 재생
  Future<void> playSFX(String soundName) async {
    if (!_sfxEnabled) {
      if (kDebugMode) {
        print('🔇 SFX disabled, skipping: $soundName');
      }
      return;
    }
    
    try {
      final url = _sfxSounds[soundName];
      if (url == null) {
        if (kDebugMode) {
          print('⚠️ SFX not found: $soundName');
        }
        return;
      }
      
      if (kDebugMode) {
        print('🔊 Attempting to play SFX: $soundName from $url');
      }
      
      // AudioPlayer 사용 (모든 플랫폼)
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(UrlSource(url));
      
      if (kDebugMode) {
        print('✅ SFX playing: $soundName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SFX play error for $soundName: $e');
      }
    }
  }

  // BGM 활성화/비활성화
  void toggleBGM(bool enabled) {
    _bgmEnabled = enabled;
    if (!enabled) {
      stopBGM();
    }
  }

  // 효과음 활성화/비활성화
  void toggleSFX(bool enabled) {
    _sfxEnabled = enabled;
  }

  // BGM 볼륨 설정
  Future<void> setBGMVolume(double volume) async {
    _bgmVolume = volume.clamp(0.0, 1.0);
    await _bgmPlayer.setVolume(_bgmVolume);
  }

  // 효과음 볼륨 설정
  Future<void> setSFXVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _sfxPlayer.setVolume(_sfxVolume);
  }

  // 정리
  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
