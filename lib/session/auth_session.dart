class AuthSession {
  static String? name;
  static String? token;
  static String? role;
  static int? userId;
  static int? siteId;
  static int? departmentId;
  static String? email;
  static String? employeeId;
  static String? siteName;
  static String? departmentName;

  static bool isManualLogout = false;

  static bool isReady = false;

  static bool get isLoggedIn => token != null && userId != null;

  static bool get isSuperAdmin =>
      role != null && role!.toLowerCase() == "superadmin";

  static bool get isAdmin =>
      role != null && ["admin", "superadmin"].contains(role!.toLowerCase());

  static bool get isMember => role != null && role!.toLowerCase() == "member";

  static void markReady() {
    isReady = true;
  }

  static void clear() {
    name = null;
    token = null;
    role = null;
    userId = null;
    siteId = null;
    departmentId = null;
    email = null;
    employeeId = null;
    siteName = null;
    departmentName = null;
    isReady = false;
  }
}
