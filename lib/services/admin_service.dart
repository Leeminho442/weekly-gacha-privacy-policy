import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  static const String _adminPasswordKey = 'admin_password';
  static const String _isAdminKey = 'is_admin';
  
  // 기본 관리자 비밀번호 (실제 배포 시 변경 필요)
  static const String defaultPassword = 'admin1234';

  /// 관리자 로그인
  Future<bool> login(String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 저장된 비밀번호가 있으면 그것 사용, 없으면 기본 비밀번호 사용
    final savedPassword = prefs.getString(_adminPasswordKey) ?? defaultPassword;
    
    if (password == savedPassword) {
      await prefs.setBool(_isAdminKey, true);
      return true;
    }
    
    return false;
  }

  /// 관리자 로그아웃
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAdminKey, false);
  }

  /// 관리자 로그인 상태 확인
  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAdminKey) ?? false;
  }

  /// 관리자 비밀번호 변경
  Future<void> changePassword(String oldPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString(_adminPasswordKey) ?? defaultPassword;
    
    if (oldPassword == savedPassword) {
      await prefs.setString(_adminPasswordKey, newPassword);
    } else {
      throw Exception('기존 비밀번호가 일치하지 않습니다.');
    }
  }
}
