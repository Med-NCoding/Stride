import SwiftUI

// MARK: - Stride Design System (SD)
//
// All UI primitives live here. Every view file must source its colours,
// spacing, radius, type, animation and shadow values from this file so
// the visual language stays consistent across the entire app.
// Never hard-code a hex string, CGFloat point size or duration elsewhere.

struct SD {

    // ── MARK: Backgrounds ────────────────────────────────────────────────
    // Raw layer colours, ordered from darkest (outermost canvas) to
    // lightest (interactive surface on top of a card).

    /// App-wide canvas. Used on ZStack/ScrollView backgrounds.
    static let bgPrimary     = Color(hex: "#0D0D0D")

    /// Default card background (lists, stat tiles, step ring card).
    static let bgCard        = Color(hex: "#1A1A1A")

    /// Elevated card – sits visually above bgCard (e.g. sheet headers).
    static let bgCardRaised  = Color(hex: "#222222")

    /// Interactive surface inside a card (text fields, toggle tracks).
    static let bgSurface     = Color(hex: "#2A2A2A")

    /// Subtle overlay for modals / bottom sheets (black at 60 % opacity).
    static let bgOverlay     = Color.black.opacity(0.6)


    // ── MARK: Brand Accent ────────────────────────────────────────────────
    // Violet is the single brand accent. Use the dim/glow variants for
    // backgrounds and halos — never solid purple on a solid-purple bg.

    /// Primary brand violet – buttons, active icons, progress arcs.
    static let purple        = Color(hex: "#8B5CF6")

    /// Lighter violet – gradient end stops, secondary accent text.
    static let purpleLight   = Color(hex: "#A78BFA")

    /// 15 % opacity violet – pill backgrounds, selected tab fill.
    static let purpleDim     = Color(hex: "#8B5CF6").opacity(0.15)

    /// 35 % opacity violet – glow rings, shadow tints.
    static let purpleGlow    = Color(hex: "#8B5CF6").opacity(0.35)


    // ── MARK: Semantic Text ───────────────────────────────────────────────
    // Semantic names mean you never have to remember which grey maps to
    // which role. Always pick by role, not by shade.

    /// Headings, values, primary body copy.
    static let textPrimary   = Color.white

    /// Secondary labels, subtitles, supporting values.
    static let textSecondary = Color(hex: "#AAAAAA")

    /// Placeholders, timestamps, de-emphasised captions.
    static let textMuted     = Color(hex: "#555555")

    /// Text placed on the brand violet (buttons, active tabs).
    static let textOnAccent  = Color.white

    /// Inverse text for light-mode future compatibility.
    static let textInverse   = Color(hex: "#0D0D0D")


    // ── MARK: Semantic Status Colours ─────────────────────────────────────
    // Keep one colour per semantic intent so status feedback is instant
    // and globally consistent.

    /// Positive outcomes: goals met, wins, positive trends.
    static let success       = Color(hex: "#34D399")   // emerald-400
    static let successDim    = Color(hex: "#34D399").opacity(0.15)

    /// Warnings: near-limit wagers, expiring challenges.
    static let warning       = Color(hex: "#FBBF24")   // amber-400
    static let warningDim    = Color(hex: "#FBBF24").opacity(0.15)

    /// Errors / destructive: failed actions, losing state.
    static let danger        = Color(hex: "#F87171")   // red-400
    static let dangerDim     = Color(hex: "#F87171").opacity(0.15)


    /// Informational: neutral highlights, health data.
    static let info          = Color(hex: "#60A5FA")   // blue-400
    static let infoDim       = Color(hex: "#60A5FA").opacity(0.15)

    /// Apple Health tint (matches system Health app).
    static let health        = Color(hex: "#F43F5E")   // rose-500


    // ── MARK: Structural ──────────────────────────────────────────────────

    /// Horizontal rules and list separators.
    static let divider       = Color(hex: "#2A2A2A")

    /// Border on focused/active interactive elements.
    static let borderActive  = SD.purple.opacity(0.4)

    /// Default (unfocused) border for text fields and cards.
    static let borderDefault = Color(hex: "#2A2A2A")


    // ── MARK: Spacing Scale ───────────────────────────────────────────────
    // Based on a 6-pt base unit. Use named tokens, not raw numbers.
    // xs=6  sm=12  md=18  lg=24  xl=32  xxl=48  xxxl=64

    static let spacing2: CGFloat  = 2    // hairline gap (icon badge offsets)
    static let spacing4: CGFloat  = 4    // tight internal padding
    static let xs: CGFloat        = 6    // icon-to-label gap, badge padding
    static let sm: CGFloat        = 12   // section internal padding
    static let md: CGFloat        = 18   // card padding, row gaps
    static let lg: CGFloat        = 24   // between-section gaps
    static let xl: CGFloat        = 32   // page-level vertical rhythm
    static let xxl: CGFloat       = 48   // hero sections, large gaps
    static let xxxl: CGFloat      = 64   // splash/onboarding breathing room

    /// Standard bottom safe-area clearance so content clears the tab bar.
    static let tabBarClearance: CGFloat = 100


    // ── MARK: Corner Radius ───────────────────────────────────────────────
    // Consistent rounding across all surfaces.

    static let radiusXs: CGFloat   = 6    // badges, tags, tiny pills
    static let radiusSm: CGFloat   = 10   // text fields, inner cards
    static let radiusMd: CGFloat   = 16   // standard cards, sheets
    static let radiusLg: CGFloat   = 22   // large cards, modals
    static let radiusXl: CGFloat   = 30   // floating tab bar
    static let radiusFull: CGFloat = 999  // pills, avatars, circular buttons


    // ── MARK: Animation Durations ─────────────────────────────────────────
    // Name durations so speed decisions are intentional and searchable.

    /// Near-instant micro-feedback (icon scale taps).
    static let animFast: Double    = 0.15

    /// Standard transition between states.
    static let animNormal: Double  = 0.25

    /// Root-state cross-fade/slide transitions.
    static let animSlow: Double    = 0.45

    /// Loading ring / pulse repeat loops.
    static let animPulse: Double   = 0.8


    // ── MARK: Icon Sizes ──────────────────────────────────────────────────
    // Keeps icon-to-label hierarchy consistent.

    static let iconSm: CGFloat  = 14   // inline with caption text
    static let iconMd: CGFloat  = 18   // standard list/row icons
    static let iconLg: CGFloat  = 24   // section headers
    static let iconXl: CGFloat  = 36   // hero / empty-state icons
}


// ── MARK: Typography ─────────────────────────────────────────────────────
//
// A dedicated `SFont` (Stride Font) namespace for every text role.
// Call like: Text("Hello").font(SFont.h1)
// This means changing the entire app's heading size means editing one line.

enum SFont {

    // Headlines
    /// Large display heading – screen titles, splash.
    static let h1   = Font.system(size: 34, weight: .bold,      design: .rounded)
    /// Section heading – card titles, modal headers.
    static let h2   = Font.system(size: 26, weight: .bold,      design: .rounded)
    /// Sub-section heading – widget headers, list group labels.
    static let h3   = Font.system(size: 20, weight: .semibold,  design: .rounded)
    /// Compact heading – stat labels, row titles.
    static let h4   = Font.system(size: 17, weight: .semibold,  design: .default)

    // Body
    /// Standard readable body text.
    static let body    = Font.system(size: 15, weight: .regular, design: .default)
    /// Slightly emphasised body – subtitles, form labels.
    static let bodyMed = Font.system(size: 15, weight: .medium,  design: .default)
    /// Strong body – primary values, usernames.
    static let bodySB  = Font.system(size: 15, weight: .semibold, design: .default)

    // Supporting
    /// Standard caption – timestamps, help text.
    static let caption  = Font.system(size: 13, weight: .regular, design: .default)
    /// Emphasised caption – section labels, pills.
    static let captionMed = Font.system(size: 13, weight: .medium, design: .default)
    /// Smallest label – legal, metadata, micro-badges.
    static let micro    = Font.system(size: 11, weight: .regular, design: .default)

    // Mono
    /// Monospaced numbers – step counts, currency balances (prevents layout jitter).
    static let numericMd = Font.system(size: 15, weight: .semibold, design: .monospaced)
    static let numericLg = Font.system(size: 26, weight: .bold,     design: .monospaced)
    static let numericXl = Font.system(size: 34, weight: .bold,     design: .rounded)

    // Tab bar
    /// Compact label under tab icons.
    static let tabLabel = Font.system(size: 10, weight: .medium, design: .default)
}


// ── MARK: Shadow Styles ───────────────────────────────────────────────────
//
// `SShadow` (Stride Shadow) centralises all shadow definitions.
// Apply with the `.shadow(SShadow.card)` convenience extension below.

struct SShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    /// Default card drop-shadow.
    static let card = SShadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)

    /// Heavier shadow for floating elements (tab bar, sheets).
    static let float = SShadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 8)

    /// Subtle accent glow for highlighted cards.
    static let accentGlow = SShadow(color: SD.purple.opacity(0.3), radius: 15, x: 0, y: 0)

    /// No shadow – use explicitly to override inherited shadows.
    static let none = SShadow(color: .clear, radius: 0, x: 0, y: 0)
}

extension View {
    /// Applies a pre-defined `SShadow` token to any view.
    func shadow(_ style: SShadow) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}


// ── MARK: Hex Color Initialiser ───────────────────────────────────────────

extension Color {
    /// Initialise a `Color` from a 6-digit hex string (with or without `#`).
    init(hex: String) {
        let scanner = Scanner(string: hex.replacingOccurrences(of: "#", with: ""))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8)  & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

