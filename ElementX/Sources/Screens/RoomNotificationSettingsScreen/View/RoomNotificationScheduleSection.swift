// SPDX-License-Identifier: AGPL-3.0-only

import Compound
import SwiftUI

struct RoomNotificationScheduleSection: View {
    @Bindable var context: RoomNotificationSettingsScreenViewModel.Context
    
    var body: some View {
        Section {
            if context.viewState.scheduleLoading {
                ProgressView()
            } else if context.viewState.scheduleSupported {
                Picker(UntranslatedL10n.screenRoomScheduleOverride, selection: $context.schedule.override) {
                    Text(UntranslatedL10n.screenRoomScheduleFollow).tag(RoomNotificationSchedule.Override.schedule)
                    Text(UntranslatedL10n.screenRoomScheduleMute).tag(RoomNotificationSchedule.Override.mute)
                    Text(UntranslatedL10n.screenRoomScheduleNormal).tag(RoomNotificationSchedule.Override.normal)
                }
                ListRow(label: .plain(title: UntranslatedL10n.screenRoomScheduleEnabled),
                        kind: .toggle($context.schedule.enabled))
                if context.schedule.enabled {
                    ForEach(1...7, id: \.self) { day in
                        Toggle(Calendar.current.weekdaySymbols[day % 7], isOn: Binding(get: {
                            context.schedule.days.contains(day)
                        }, set: { selected in
                            if selected {
                                context.schedule.days.append(day)
                                context.schedule.days.sort()
                            } else {
                                context.schedule.days.removeAll { $0 == day }
                            }
                        }))
                        .toggleStyle(.compound)
                    }
                    DatePicker(UntranslatedL10n.screenRoomScheduleStart, selection: timeBinding(start: true), displayedComponents: .hourAndMinute)
                    DatePicker(UntranslatedL10n.screenRoomScheduleEnd, selection: timeBinding(start: false), displayedComponents: .hourAndMinute)
                    Picker(UntranslatedL10n.screenRoomScheduleTimezone, selection: $context.schedule.timezone) {
                        ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { zone in
                            Text(zone).tag(zone)
                        }
                    }
                }
                Button(L10n.actionSave) { context.send(viewAction: .saveSchedule) }
                    .disabled(context.viewState.scheduleSaving || !context.schedule.isValid)
                if context.viewState.scheduleSaving {
                    ProgressView()
                }
                if context.viewState.scheduleError {
                    Text(UntranslatedL10n.screenRoomScheduleSaveError).foregroundStyle(Color.compound.textCriticalPrimary)
                }
                if context.viewState.scheduleConflict {
                    Text(UntranslatedL10n.screenRoomScheduleConflict).foregroundStyle(Color.compound.textCriticalPrimary)
                }
                Button(UntranslatedL10n.screenRoomScheduleReload) { context.send(viewAction: .reloadSchedule) }
            } else {
                Text(UntranslatedL10n.screenRoomScheduleUnavailable)
                Button(L10n.actionRetry) { context.send(viewAction: .reloadSchedule) }
            }
        } header: {
            Text(UntranslatedL10n.screenRoomScheduleTitle).compoundListSectionHeader()
        } footer: {
            Text(UntranslatedL10n.screenRoomScheduleDescription).compoundListSectionFooter()
        }
        .environment(\.timeZone, .gmt)
        .disabled(context.viewState.scheduleSaving)
    }
    
    private func timeBinding(start: Bool) -> Binding<Date> {
        Binding(get: {
            Date(timeIntervalSince1970: Double(start ? context.schedule.startMinute : context.schedule.endMinute) * 60)
        }, set: { date in
            let minute = (Int(date.timeIntervalSince1970) / 60 % 1440 + 1440) % 1440
            if start {
                context.schedule.startMinute = minute
            } else {
                context.schedule.endMinute = minute
            }
        })
    }
}

struct RoomNotificationScheduleSection_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            RoomNotificationScheduleSection(context: RoomNotificationSettingsScreen_Previews.viewModel.context)
        }
    }
}
