// lib/core/constants/app_constants.dart
class AppConstants {
  // Super admin — hidden from all user management screens
  static const String superAdminEmail = 'admin@technodysis.com';

  static const String issuesCollection = 'issues';
  static const String usersCollection  = 'users';
  static const String roleAdmin = 'admin';
  static const String roleUser  = 'user';

  static const List<String> customers = [
    'Ecocash','Econet','CWS','EMM','EthioTelecom',
  ];
  static const List<String> technologies = [
    'Power Automate Cloud','PAD','UiPath','SQL','SharePoint','Other',
  ];
  static const List<String> priorities = ['Low','Medium','High','Critical'];
  static const List<String> statuses = [
    'New','In Progress','Waiting for Client','Resolved','Closed',
  ];
  static const List<String> rootCauses = [
    'Infra','Code Bug','Data Issue','Credentials',
    'Business Change','Access','Unknown',
  ];
  static const List<String> openStatuses   = ['New','In Progress','Waiting for Client'];
  static const List<String> closedStatuses = ['Resolved','Closed'];
}
