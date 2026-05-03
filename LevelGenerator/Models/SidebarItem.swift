import Foundation

enum SidebarItem: Hashable {
    case levels
    case script(UUID)
    case trigger(UUID)
    case npc(UUID)
}
