// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal nonisolated enum UntranslatedL10n {
  /// Search
  internal static var screenHomeTabSearch: String { return UntranslatedL10n.tr("Untranslated", "screen_home_tab_search") }
  /// Separate words or phrases with commas. Rooms set to Mentions and keywords will notify for these matches.
  internal static var screenNotificationSettingsMentionKeywordsDescription: String { return UntranslatedL10n.tr("Untranslated", "screen_notification_settings_mention_keywords_description") }
  /// Name, phrase, keyword
  internal static var screenNotificationSettingsMentionKeywordsPlaceholder: String { return UntranslatedL10n.tr("Untranslated", "screen_notification_settings_mention_keywords_placeholder") }
  /// Save mention words
  internal static var screenNotificationSettingsMentionKeywordsSave: String { return UntranslatedL10n.tr("Untranslated", "screen_notification_settings_mention_keywords_save") }
  /// Mention words
  internal static var screenNotificationSettingsMentionKeywordsTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_notification_settings_mention_keywords_title") }
  /// SYN Default
  internal static var screenNotificationSettingsSoundSynDefault: String { return UntranslatedL10n.tr("Untranslated", "screen_notification_settings_sound_syn_default") }
  /// SYN Fade
  internal static var screenNotificationSettingsSoundSynFade: String { return UntranslatedL10n.tr("Untranslated", "screen_notification_settings_sound_syn_fade") }
  /// Welcome to SYN
  internal static var screenOnboardingSynWelcomeTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_onboarding_syn_welcome_title") }
  /// Unsupported call. Ask the caller to update their Matrix app and try again.
  internal static var screenRoomTimelineSynLegacyCall: String { return UntranslatedL10n.tr("Untranslated", "screen_room_timeline_syn_legacy_call") }
  /// Search for chats and messages
  internal static var screenSearchEmptyStateMessage: String { return UntranslatedL10n.tr("Untranslated", "screen_search_empty_state_message") }
  /// Start searching...
  internal static var screenSearchEmptyStateTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_search_empty_state_title") }
  /// There are no results for “%1$@.” Try a new search term.
  internal static func screenSearchNoResultsMessage(_ p1: Any) -> String {
    return UntranslatedL10n.tr("Untranslated", "screen_search_no_results_message", String(describing: p1))
  }
  /// Chats
  internal static var screenSearchTabChats: String { return UntranslatedL10n.tr("Untranslated", "screen_search_tab_chats") }
  /// Messages
  internal static var screenSearchTabMessages: String { return UntranslatedL10n.tr("Untranslated", "screen_search_tab_messages") }
  /// Automatic
  internal static var screenSettingsPresenceAutomatic: String { return UntranslatedL10n.tr("Untranslated", "screen_settings_presence_automatic") }
  /// Availability
  internal static var screenSettingsPresenceAvailability: String { return UntranslatedL10n.tr("Untranslated", "screen_settings_presence_availability") }
  /// Away
  internal static var screenSettingsPresenceAway: String { return UntranslatedL10n.tr("Untranslated", "screen_settings_presence_away") }
  /// Automatic shows you online while SYN is active and away when it is in the background. Turn sharing off to appear offline.
  internal static var screenSettingsPresenceDescription: String { return UntranslatedL10n.tr("Untranslated", "screen_settings_presence_description") }
  /// Presence message
  internal static var screenSettingsPresenceMessage: String { return UntranslatedL10n.tr("Untranslated", "screen_settings_presence_message") }
  /// Offline
  internal static var screenSettingsPresenceOffline: String { return UntranslatedL10n.tr("Untranslated", "screen_settings_presence_offline") }
  /// Online
  internal static var screenSettingsPresenceOnline: String { return UntranslatedL10n.tr("Untranslated", "screen_settings_presence_online") }
  /// Share presence
  internal static var screenSettingsPresenceShare: String { return UntranslatedL10n.tr("Untranslated", "screen_settings_presence_share") }
  /// Allow people in shared rooms to see your availability.
  internal static var screenSettingsPresenceShareDescription: String { return UntranslatedL10n.tr("Untranslated", "screen_settings_presence_share_description") }
  /// Presence
  internal static var screenSettingsPresenceTitle: String { return UntranslatedL10n.tr("Untranslated", "screen_settings_presence_title") }
  /// Clear all data currently stored on this device?
  /// Sign in again to access your account data and messages.
  internal static var softLogoutClearDataDialogContent: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_dialog_content") }
  /// Clear data
  internal static var softLogoutClearDataDialogTitle: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_dialog_title") }
  /// Warning: Your personal data (including encryption keys) is still stored on this device.
  /// 
  /// Clear it if you’re finished using this device, or want to sign in to another account.
  internal static var softLogoutClearDataNotice: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_notice") }
  /// Clear all data
  internal static var softLogoutClearDataSubmit: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_submit") }
  /// Clear personal data
  internal static var softLogoutClearDataTitle: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_clear_data_title") }
  /// Sign in to recover encryption keys stored exclusively on this device. You need them to read all of your secure messages on any device.
  internal static var softLogoutSigninE2eWarningNotice: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_signin_e2e_warning_notice") }
  /// Your homeserver (%1$s) admin has signed you out of your account %2$s (%3$s).
  internal static func softLogoutSigninNotice(_ p1: UnsafePointer<CChar>, _ p2: UnsafePointer<CChar>, _ p3: UnsafePointer<CChar>) -> String {
    return UntranslatedL10n.tr("Untranslated", "soft_logout_signin_notice", p1, p2, p3)
  }
  /// Sign in
  internal static var softLogoutSigninTitle: String { return UntranslatedL10n.tr("Untranslated", "soft_logout_signin_title") }
  /// Untranslated
  internal static var untranslated: String { return UntranslatedL10n.tr("Untranslated", "untranslated") }
  /// Plural format key: "%#@VARIABLE@"
  internal static func untranslatedPlural(_ p1: Int) -> String {
    return UntranslatedL10n.tr("Untranslated", "untranslated_plural", p1)
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

nonisolated extension UntranslatedL10n {
  static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // No need to check languages, we always default to en for untranslated strings
    guard let bundle = Bundle.lprojBundle(for: "en") else { return key }
    let format = NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
    return String(format: format, locale: Locale(identifier: "en"), arguments: args)
  }
}

// swiftlint:enable all
