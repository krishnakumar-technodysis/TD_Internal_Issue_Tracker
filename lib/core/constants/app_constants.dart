// lib/core/constants/app_constants.dart
class AppConstants {
  static const String superAdminEmail = 'admin@technodysis.com';

  static const String issuesCollection = 'issues';
  static const String usersCollection  = 'users';

  // Roles
  static const String roleSuperAdmin = 'super_admin';
  static const String roleAdmin      = 'admin';
  static const String roleManager    = 'manager';
  static const String roleUser       = 'user';

  // All selectable roles (excluding super_admin — it's set directly on DB)
  static const List<String> roles = [roleUser, roleManager, roleAdmin];

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

  // Task statuses with display labels
  static const List<String> taskStatuses = [
    'todo','in_progress','review','done','cancelled'
  ];
  static String taskStatusLabel(String s) => switch (s) {
    'todo'        => 'To Do',
    'in_progress' => 'In Progress',
    'review'      => 'Review',
    'done'        => 'Done',
    'cancelled'   => 'Cancelled',
    _             => s,
  };

  // Project statuses
  static const List<String> projectStatuses = [
    'active','on_hold','completed','cancelled'
  ];
  static String projectStatusLabel(String s) => switch (s) {
    'active'    => 'Active',
    'on_hold'   => 'On Hold',
    'completed' => 'Completed',
    _           => 'Cancelled',
  };
}