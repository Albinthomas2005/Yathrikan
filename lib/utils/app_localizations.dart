import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'YATHRIKAN',
      'live_buses': 'Live buses near you',
      'search_hint': 'Enter Bus Number (e.g. KL-07...)',
      'coming_soon': 'Coming Soon',

      // Home
      'home': 'Home',
      'route': 'Route',
      'profile': 'Profile',
      'arriving_in': 'Arriving in',
      'current_speed': 'Current Speed',
      'quick_actions': 'Quick Actions',
      'shortest_route': 'Shortest Route',
      'my_ticket': 'My Ticket',
      'complaint': 'Complaint',
      'safety': 'Safety',

      // Route Screen
      'routes': 'Routes',
      'route_planning': 'Route Planning',
      'find_best_routes': 'Find the best routes for your journey.',
      'coming_soon_desc':
          'Find the best routes for your journey.\nComing soon!',

      // Shortest Route
      'your_location': 'Your Location',
      'search_destination': 'Search destination',
      'preview': 'Preview',
      'full_map': 'Full Map ↗',
      'recent_places': 'Recent Places',
      'find_route': 'Find Route',
      'central_station': 'Central Station',
      'office_hq': 'Office HQ',

      // Ticket Validation
      'ticket_validation': 'Ticket Validation',
      'validate_ride': 'Validate your ride',
      'choose_verify_method':
          'Choose how you want to verify your ticket today.',
      'manual_entry': 'Manual Entry',
      'enter_pin_hint':
          'Enter the 6-digit PIN code from your purchase receipt.',
      'verify_ticket': 'Verify Ticket',
      'ticket_verified': 'Ticket Verified Successfully!',
      'scan_qr': 'Scan QR Code',
      'scan_qr_desc':
          'Use your camera to instantly validate your digital ticket.',
      'scan_now': 'Scan Now',
      'scan_ticket': 'Scan Ticket',
      'contact_support': 'Having trouble? Contact Support',

      // Profile
      'edit_profile': 'Edit Profile',
      'notifications': 'Notifications',
      'settings': 'Settings',
      'help_support': 'Help & Support',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',

      // Settings
      'dark_mode': 'Dark Mode',
      'enable_dark_theme': 'Enable dark theme',
      'language': 'Language',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'about_app': 'About App',
      'receive_updates': 'Receive updates about your bus',
      'location_access': 'Location Access',
      'allow_location': 'Allow app to access location',

      // Edit Profile
      'full_name': 'Full Name',
      'email': 'Email',
      'save': 'Save',
      'profile_updated': 'Profile Updated!',

      // General
      'submit': 'Submit',
      'cancel': 'Cancel',

      // Admin Finance
      'admin_finance_title': 'Admin Finance Reports',
      'total_system_revenue': 'Total System Revenue',
      'growth': 'Growth',
      'current_month': 'Current Month',
      'last_month': 'Last Month',
      'daily_comparison': 'Daily Comparison',
      'transaction_history': 'Transaction History',
      'see_all': 'See All',
      'all_transactions': 'All Transactions',
      'success': 'Success',
      'export_report': 'Export Report',
      'report_exported': 'Report exported successfully!',
      'filter_by_date': 'Filter by date',

      // Admin Support
      'user_support': 'User Support',
      'quick_actions_title': 'QUICK ACTIONS',
      'manage_routes': 'Manage\nRoutes',
      'fleet_track': 'Fleet\nTrack',
      'finance': 'Finance',
      'pending': 'Pending',
      'in_progress': 'In Progress',
      'resolved': 'Resolved',
      'no_tickets_in_progress': 'No tickets in progress',
      'resolved_tickets_count': 'resolved tickets',
      'ticket_id': 'Ticket ID',
      'priority': 'Priority',
      'description': 'Description:',
      'reported_by': 'Reported By',
      'close': 'Close',
      'resolve': 'Resolve',
      'ticket_status_updated': 'Ticket status updated',
      'search_coming_soon': 'Search functionality coming soon',
      'already_on_support': 'You are already on User Support',
      'open_ticket': 'Open Ticket',

      // Days
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
      'ksrtc': 'KSRTC',
      'private': 'Private',
    },
    'ml': {
      'app_title': 'യാത്രികൻ',
      'live_buses': 'നിങ്ങളുടെ അടുത്തുള്ള തത്സമയ ബസുകൾ',
      'search_hint': 'ബസ് നമ്പർ നൽകുക (ഉദാഹരണത്തിന് KL-07...)',
      'coming_soon': 'ഉടൻ വരുന്നു',

      // Home
      'home': 'ഹോം',
      'route': 'റൂട്ട്',
      'profile': 'പ്രൊഫൈൽ',
      'arriving_in': 'എത്താൻ സമയം',
      'current_speed': 'നിലവിലെ വേഗത',
      'quick_actions': 'സേവനങ്ങൾ',
      'shortest_route': 'റൂട്ട് കണ്ടെത്തുക',
      'my_ticket': 'ടിക്കറ്റ്',
      'complaint': 'പരാതി',
      'safety': 'സുരക്ഷ',

      // Route Screen
      'routes': 'റൂട്ടുകൾ',
      'route_planning': 'റൂട്ട് പ്ലാനിംഗ്',
      'find_best_routes':
          'നിങ്ങളുടെ യാത്രയ്ക്കുള്ള മികച്ച റൂട്ടുകൾ കണ്ടെത്തുക.',
      'coming_soon_desc':
          'നിങ്ങളുടെ യാത്രയ്ക്കുള്ള മികച്ച റൂട്ടുകൾ കണ്ടെത്തുക.\nഉടൻ വരുന്നു!',

      // Shortest Route
      'your_location': 'നിങ്ങളുടെ സ്ഥലം',
      'search_destination': 'ലക്ഷ്യസ്ഥാനം തിരയുക',
      'preview': 'പ്രിവ്യൂ',
      'full_map': 'പൂർണ്ണ മാപ്പ് ↗',
      'recent_places': 'അടുത്തിടെ സന്ദർശിച്ച സ്ഥലങ്ങൾ',
      'find_route': 'റൂട്ട് കണ്ടെത്തുക',
      'central_station': 'സെൻട്രൽ സ്റ്റേഷൻ',
      'office_hq': 'ഓഫീസ് ആസ്ഥാനം',

      // Ticket Validation
      'ticket_validation': 'ടിക്കറ്റ് പരിശോധന',
      'validate_ride': 'നിങ്ങളുടെ യാത്ര സാധൂകരിക്കുക',
      'choose_verify_method':
          'ടിക്കറ്റ് പരിശോധിക്കാൻ ഒരു മാർഗ്ഗം തിരഞ്ഞെടുക്കുക.',
      'manual_entry': 'മാന്വൽ എൻട്രി',
      'enter_pin_hint': 'രസീതിലെ 6 അക്ക PIN കോഡ് നൽകുക.',
      'verify_ticket': 'ടിക്കറ്റ് പരിശോധിക്കുക',
      'ticket_verified': 'ടിക്കറ്റ് വിജയകരമായി പരിശോധിച്ചു!',
      'scan_qr': 'QR കോഡ് സ്കാൻ ചെയ്യുക',
      'scan_qr_desc': 'ക്യാമറ ഉപയോഗിച്ച് ടിക്കറ്റ് പരിശോധിക്കുക.',
      'scan_now': 'ഇപ്പോൾ സ്കാൻ ചെയ്യുക',
      'scan_ticket': 'ടിക്കറ്റ് സ്കാൻ',
      'contact_support': 'സഹായം ആവശ്യമുണ്ടോ? സപ്പോർട്ടുമായി ബന്ധപ്പെടുക',

      // Profile
      'edit_profile': 'പ്രൊഫൈൽ എഡിറ്റ് ചെയ്യുക',
      'notifications': 'അറിയിപ്പുകൾ',
      'settings': 'സജ്ജീകരണങ്ങൾ',
      'help_support': 'സഹായം',
      'logout': 'ലോഗ് ഔട്ട്',
      'logout_confirm': 'ലോഗ് ഔട്ട് ചെയ്യണോ?',

      // Settings
      'dark_mode': 'ഡാർക്ക് മോഡ്',
      'enable_dark_theme': 'ഡാർക്ക് തീം പ്രവർത്തനക്ഷമമാക്കുക',
      'language': 'ഭാഷ',
      'privacy_policy': 'സ്വകാര്യതാ നയം',
      'terms_of_service': 'സേവന വ്യവസ്ഥകൾ',
      'about_app': 'ആപ്പിനെക്കുറിച്ച്',
      'receive_updates': 'ബസ് അറിയിപ്പുകൾ ലഭിക്കുക',
      'location_access': 'ലൊക്കേഷൻ',
      'allow_location': 'ലൊക്കേഷൻ അനുവദിക്കുക',

      // Edit Profile
      'full_name': 'പേര്',
      'email': 'ഇമെയിൽ',
      'save': 'സേവ് ചെയ്യുക',
      'profile_updated': 'പ്രൊഫൈൽ അപ്‌ഡേറ്റ് ചെയ്തു!',

      // General
      'submit': 'സമർപ്പിക്കുക',
      'cancel': 'റദ്ദാക്കുക',

      // Admin Finance
      'admin_finance_title': 'അഡ്മിൻ ഫിനാൻസ് റിപ്പോർട്ടുകൾ',
      'total_system_revenue': 'മൊത്തം വരുമാനം',
      'growth': 'വളർച്ച',
      'current_month': 'ഈ മാസം',
      'last_month': 'കഴിഞ്ഞ മാസം',
      'daily_comparison': 'ദിവസേനയുള്ള താരതമ്യം',
      'transaction_history': 'ഇടപാട് ചരിത്രം',
      'see_all': 'എല്ലാം കാണുക',
      'all_transactions': 'എല്ലാ ഇടപാടുകളും',
      'success': 'വിജയിച്ചു',
      'export_report': 'റിപ്പോർട്ട് എക്സ്പോർട്ട് ചെയ്യുക',
      'report_exported': 'റിപ്പോർട്ട് വിജയകരമായി എക്സ്പോർട്ട് ചെയ്തു!',
      'filter_by_date': 'തീയതി പ്രകാരം ഫിൽട്ടർ ചെയ്യുക',

      // Admin Support
      'user_support': 'ഉപഭോക്തൃ സഹായം',
      'quick_actions_title': 'സേവനങ്ങൾ',
      'manage_routes': 'റൂട്ടുകൾ\nനിയന്ത്രിക്കുക',
      'fleet_track': 'ഫ്ലീറ്റ്\nട്രാക്ക്',
      'finance': 'ഫിനാൻസ്',
      'pending': 'തീർപ്പുകൽപ്പിക്കാത്തവ',
      'in_progress': 'പുരോഗമിക്കുന്നു',
      'resolved': 'പരിഹരിച്ചവ',
      'no_tickets_in_progress': 'പുരോഗതിയിലുള്ള ടിക്കറ്റുകളില്ല',
      'resolved_tickets_count': 'പരിഹരിച്ച ടിക്കറ്റുകൾ',
      'ticket_id': 'ടിക്കറ്റ് ഐഡി',
      'priority': 'മുൻഗണന',
      'description': 'വിവരണം:',
      'reported_by': 'റിപ്പോർട്ട് ചെയ്തത്',
      'close': 'അടയ്ക്കുക',
      'resolve': 'പരിഹരിക്കുക',
      'ticket_status_updated': 'ടിക്കറ്റ് നില അപ്‌ഡേറ്റുചെയ്‌തു',
      'search_coming_soon': 'തിരയൽ ഉടൻ വരുന്നു',
      'already_on_support': 'നിങ്ങൾ ഇതിനകം തന്നെ ഉപഭോക്തൃ സഹായത്തിലാണ്',
      'open_ticket': 'ടിക്കറ്റ് തുറക്കുക',

      // Days
      'mon': 'തിങ്കൾ',
      'tue': 'ചൊവ്വ',
      'wed': 'ബുധൻ',
      'thu': 'വ്യാഴം',
      'fri': 'വെള്ളി',
      'sat': 'ശനി',
      'sun': 'ഞായർ',
      'ksrtc': 'കെഎസ്ആർടിസി',
      'private': 'സ്വകാര്യം',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String operator [](String key) => translate(key);
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ml'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
