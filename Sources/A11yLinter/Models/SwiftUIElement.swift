enum SwiftUIElement: String, CaseIterable {
    case button = "Button"
    case toggle = "Toggle"
    case picker = "Picker"
    case slider = "Slider"
    case stepper = "Stepper"
    case textField = "TextField"
    case secureField = "SecureField"
    case textEditor = "TextEditor"
    case link = "Link"
    case menu = "Menu"
    case navigationLink = "NavigationLink"
    case datepicker = "DatePicker"
    case colorPicker = "ColorPicker"

    var requiresIdentifier: Bool {
        switch self {
        case .button, .toggle, .textField, .secureField, .link, .navigationLink:
            return true
        default:
            return false
        }
    }

    var requiresLabel: Bool {
        return true
    }
}
