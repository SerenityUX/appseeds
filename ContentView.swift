import SwiftUI
import UIKit  // Import UIKit for haptic feedback



// HapticManager to handle haptic feedback
struct HapticManager {
    
    static let impactGenerator = UIImpactFeedbackGenerator()
    static let notificationGenerator = UINotificationFeedbackGenerator()
    
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(type)
    }
    
    // New function to simulate continuous vibration
    static func startContinuousHaptic() -> Timer {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
        RunLoop.current.add(timer, forMode: .common)
        return timer
    }

    static func stopContinuousHaptic(timer: Timer?) {
        timer?.invalidate()
    }

}


// CodableColor struct to handle Color encoding and decoding
struct CodableColor: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init(color: Color) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0; var green: CGFloat = 0; var blue: CGFloat = 0; var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.alpha = Double(alpha)
    }

    func toColor() -> Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

// Updated AppSeedData struct with foregroundColor and backgroundColor
struct AppSeedData: Identifiable, Codable, Equatable {
    let id: UUID
    var systemIconName: String
    var appName: String
    var content: String
    var foregroundColor: CodableColor
    var backgroundColor: CodableColor

    init(systemIconName: String, appName: String = "", content: String = "", foregroundColor: Color = .white, backgroundColor: Color = .black) {
        self.id = UUID()
        self.systemIconName = systemIconName
        self.appName = appName
        self.content = content
        self.foregroundColor = CodableColor(color: foregroundColor)
        self.backgroundColor = CodableColor(color: backgroundColor)
    }

    enum CodingKeys: String, CodingKey {
        case id, systemIconName, appName, content, foregroundColor, backgroundColor
    }
}

// Updated AppSeed view to accept foregroundColor and backgroundColor
struct AppSeed: View {
    var systemIconName: String
    var isEditing: Bool
    var appName: String
    var foregroundColor: Color
    var backgroundColor: Color

    @State private var wobbleAnimation: Bool = false

    var body: some View {
        VStack{
            ZStack(alignment: .topLeading) {
                Image(systemName: systemIconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .padding(12)
                    .foregroundColor(foregroundColor)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                    .rotationEffect(wobbleAnimation ? .degrees(-1) : .degrees(1))
                    .animation(isEditing ? Animation.easeInOut(duration: 0.1).repeatForever(autoreverses: true) : .default, value: wobbleAnimation)
                    .onAppear {
                        if isEditing {
                            wobbleAnimation = true
                        }
                    }
                    .onChange(of: isEditing) { newValue in
                        wobbleAnimation = newValue
                    }
            }

            if !appName.isEmpty {
                Text(appName.count > 12 ? String(appName.prefix(12)) + "..." : appName)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.8), radius: 2, x: 0, y: 0)

            } else {
                Text("Untitled App")
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.8), radius: 2, x: 0, y: 0)
            }
        }
    }
}



struct ContentView: View {


    @State private var appSeeds: [AppSeedData] = []
    @State private var newSeedID: UUID? = nil
    @State private var isEditing: Bool = false
    @State private var selectedSeedID: UUID? = nil
    @State private var seedToDelete: AppSeedData? = nil
    @State private var wallpaperName: String = "" // Default wallpaper name
    @State private var hapticTimer: Timer? = nil

    var body: some View {
        NavigationStack {
            ZStack{
                GeometryReader { geometry in
                    Image(wallpaperName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                        .ignoresSafeArea()
                }
                VStack{
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 20) {
                        ForEach(appSeeds) { seed in
                            ZStack {
                                if !isEditing {
                                    NavigationLink(destination: NewPageView(seedID: seed.id, appSeeds: $appSeeds, saveAppSeeds: saveAppSeeds), tag: seed.id, selection: $selectedSeedID) {
                                        AppSeed(
                                            systemIconName: seed.systemIconName,
                                            isEditing: isEditing,
                                            appName: seed.appName,
                                            foregroundColor: seed.foregroundColor.toColor(),
                                            backgroundColor: seed.backgroundColor.toColor()
                                        )
                                        .onTapGesture {
                                            selectedSeedID = seed.id
                                        }
                                        .onLongPressGesture {
                                            HapticManager.impact(style: .medium)  // Haptic feedback on long press

                                            
                                            withAnimation {
                                                isEditing.toggle()
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    AppSeed(
                                        systemIconName: seed.systemIconName,
                                        isEditing: isEditing,
                                        appName: seed.appName,
                                        foregroundColor: seed.foregroundColor.toColor(),
                                        backgroundColor: seed.backgroundColor.toColor()
                                    )
                                    .onLongPressGesture {
                                        withAnimation {
                                            isEditing.toggle()
                                        }
                                    }
                                    .onTapGesture {
                                        // Do nothing or handle editing
                                    }
                                }
                                
                                if isEditing {
                                    Button(action: {
                                        seedToDelete = seed
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.red)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                    }
                                    .offset(x: -32, y: -40)
                                }
                            }
                            .transition(.scaleAndFade)
                            .id(seed.id)
                        }
                        Button(action: {
                            if(appSeeds.count < 27)  {
                                let newSeed = AppSeedData(systemIconName: "star")
                                appSeeds.append(newSeed)
                                newSeedID = newSeed.id
                                print("New seed added: \(newSeed)")
                                saveAppSeeds()
                                HapticManager.notification(type: .success)
                            } else {
                                HapticManager.notification(type: .error)
                            }
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .padding(.all, 12)
                                .foregroundColor(.black)
                                .background(Color.white.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding()
                    .onAppear {
                        loadAppSeeds()
                        if(wallpaperName == "") {
                            let wallpaperNumber = Int.random(in: 1...16)
                            if wallpaperNumber == 1 {
                                wallpaperName = "wallPaper"
                            } else {
                                wallpaperName = "wallPaper\(wallpaperNumber)"
                            }
                            print("Selected wallpaper: \(wallpaperName)")
                        }
                    }
                    .onChange(of: isEditing) { newValue in
                        if newValue {
                            // Start continuous haptic feedback when editing starts
                            hapticTimer = HapticManager.startContinuousHaptic()
                        } else {
                            // Stop continuous haptic feedback when editing ends
                            HapticManager.stopContinuousHaptic(timer: hapticTimer)
                        }
                    }
                    
                    .navigationDestination(for: UUID.self) { seedID in
                        NewPageView(seedID: seedID, appSeeds: $appSeeds, saveAppSeeds: saveAppSeeds)
                    }
                    .onChange(of: newSeedID) { _ in
                        DispatchQueue.main.async {
                            newSeedID = nil
                        }
                    }
                    .alert(item: $seedToDelete) { seed in
                        Alert(
                            title: Text("Delete App Seed?"),
                            message: Text("Are you sure you want to delete this app seed?"),
                            primaryButton: .destructive(Text("Delete")) {
                                withAnimation {
                                    if let index = appSeeds.firstIndex(where: { $0.id == seed.id }) {
                                        appSeeds.remove(at: index)
                                        saveAppSeeds()
                                        HapticManager.notification(type: .success)  // Haptic feedback on successful deletion

                                    }
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    .animation(.easeInOut(duration: 0.3), value: appSeeds)
                    Spacer()
                }
                
            }
        }
    }

    private func saveAppSeeds() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let encoded = try encoder.encode(appSeeds)
            if let jsonString = String(data: encoded, encoding: .utf8) {
                print("JSON to be saved: \(jsonString)")
            }
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent("appSeeds.json")
                try encoded.write(to: fileURL)
                print("App seeds saved successfully to \(fileURL).")
            }
        } catch {
            print("Failed to save app seeds: \(error.localizedDescription)")
        }
    }

    private func loadAppSeeds() {
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentDirectory.appendingPathComponent("appSeeds.json")
            print("Attempting to load app seeds from \(fileURL).")
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    let data = try Data(contentsOf: fileURL)
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("JSON loaded: \(jsonString)")
                    }
                    let decoder = JSONDecoder()
                    let loadedSeeds = try decoder.decode([AppSeedData].self, from: data)
                    print("Decoded seeds: \(loadedSeeds)")
                    DispatchQueue.main.async {
                        self.appSeeds = loadedSeeds
                        print("App seeds loaded successfully: \(self.appSeeds)")
                    }
                } catch {
                    print("Failed to decode app seeds: \(error.localizedDescription)")
                }
            } else {
                print("No app seeds file found at \(fileURL).")
            }
        }
    }
}

struct NewPageView: View {
    var seedID: UUID?
    @Binding var appSeeds: [AppSeedData]
    var saveAppSeeds: () -> Void
    @State private var appName: String = ""
    @State private var content: String = ""
    @FocusState private var isFocused: Bool
    @State private var showSettings: Bool = false
    @State private var selectedIcon: String = "star"
    @State private var foregroundColor: Color = .white
    @State private var backgroundColor: Color = .black

    var body: some View {
        VStack {
            TextField("App Name", text: $appName)
                .padding([.top, .leading, .trailing], 8)
                .fontWeight(.medium)
            TextEditor(text: $content)
                .padding([.leading, .bottom, .trailing], 4)
                .focused($isFocused)
                .onAppear {
                    loadContent()
                    isFocused = true
                }
                .onDisappear {
                    saveContent()
                }
            Spacer()
        }
        .padding(.bottom, 8.0)
        .navigationTitle(appName.isEmpty ? "New App Seed" : appName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showSettings.toggle()
                }) {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                selectedIcon: $selectedIcon,
                foregroundColor: $foregroundColor,
                backgroundColor: $backgroundColor
            )
            .onDisappear {
                if let seedID = seedID, let index = appSeeds.firstIndex(where: { $0.id == seedID }) {
                    appSeeds[index].systemIconName = selectedIcon
                    appSeeds[index].foregroundColor = CodableColor(color: foregroundColor)
                    appSeeds[index].backgroundColor = CodableColor(color: backgroundColor)
                    saveAppSeeds()
                }
            }
        }
    }

    private func loadContent() {
        if let seedID = seedID, let seed = appSeeds.first(where: { $0.id == seedID }) {
            appName = seed.appName
            content = seed.content
            selectedIcon = seed.systemIconName
            foregroundColor = seed.foregroundColor.toColor()
            backgroundColor = seed.backgroundColor.toColor()
        }
    }

    private func saveContent() {
        if let seedID = seedID, let index = appSeeds.firstIndex(where: { $0.id == seedID }) {
            appSeeds[index].appName = appName
            appSeeds[index].content = content
            appSeeds[index].systemIconName = selectedIcon
            appSeeds[index].foregroundColor = CodableColor(color: foregroundColor)
            appSeeds[index].backgroundColor = CodableColor(color: backgroundColor)
            saveAppSeeds()
        }
    }
}

// Updated SettingsView with a vertical list of icons
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedIcon: String
    @Binding var foregroundColor: Color
    @Binding var backgroundColor: Color

    let icons = [
        "airplane", "ant", "ant.fill", "antenna.radiowaves.left.and.right", "app", "archivebox",
        "archivebox.fill", "bag", "bag.fill", "battery.100", "bed.double", "bell", "bell.fill",
        "bicycle", "binoculars", "binoculars.fill", "book", "book.fill", "bookmark", "bookmark.fill",
        "briefcase", "bubble.left", "bubble.left.fill", "bus", "calendar", "camera", "camera.fill",
        "car", "cart", "cart.fill", "chair", "chart.bar", "chart.pie", "checkmark", "chevron.left",
        "chevron.right", "circle", "circle.fill", "clock", "cloud", "cloud.fill", "command", "crown",
        "cube", "cube.fill", "dollarsign.circle", "dollarsign.circle.fill", "envelope", "envelope.fill",
        "exclamationmark.circle", "exclamationmark.triangle", "eye", "eye.fill", "eyeglasses", "film",
        "film.fill", "flag", "flag.fill", "flame", "flame.fill", "folder", "folder.fill", "gift",
        "gift.fill", "globe", "hammer", "hammer.fill", "hand.thumbsup", "hand.thumbsup.fill", "hare",
        "hare.fill", "headphones", "heart", "heart.fill", "helm", "hourglass", "house", "house.fill",
        "info.circle", "key", "ladybug", "ladybug.fill", "leaf", "leaf.fill", "lightbulb", "lightbulb.fill",
        "link", "lock", "lock.fill", "magnifyingglass", "map", "mappin", "mappin.circle", "megaphone",
        "megaphone.fill", "mic", "mic.fill", "moon", "moon.fill", "music.note", "newspaper", "paperclip",
        "paperplane", "paperplane.fill", "pencil", "person", "person.fill", "phone", "phone.fill",
        "photo", "photo.fill", "pin", "pin.fill", "printer", "printer.fill", "puzzlepiece", "questionmark.circle",
        "rosette", "scissors", "scissors.badge.ellipsis", "shield", "shield.fill", "sparkles", "speaker",
        "speaker.fill", "star", "star.fill", "stethoscope", "sun.max", "sun.max.fill", "tortoise",
        "tortoise.fill", "tram", "trash", "trash.fill", "tray", "tray.fill", "trophy", "trophy.fill",
        "truck", "video", "video.fill", "wifi", "wind", "wrench", "wrench.fill"
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Colors")) {
                    ColorPicker("Foreground Color", selection: $foregroundColor)
                        .onChange(of: foregroundColor) { newColor in
                            HapticManager.impact(style: .light)  // Haptic feedback on foreground color change
                        }
                    ColorPicker("Background Color", selection: $backgroundColor)
                        .onChange(of: backgroundColor) { newColor in
                            HapticManager.impact(style: .light)  // Haptic feedback on background color change
                        }
                }

                Section(header: Text("Icon")) {
                    List(icons, id: \.self) { icon in
                        HStack {
                            Image(systemName: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(Color.black)
                            Text(icon)
                            Spacer()
                            if icon == selectedIcon {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle()) // Makes the entire row tappable
                        .onTapGesture {
                            selectedIcon = icon
                            HapticManager.impact(style: .light)  // Haptic feedback on icon selection
                        }
                    }
                }

            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Transition extension
extension AnyTransition {
    static var scaleAndFade: AnyTransition {
        AnyTransition.scale(scale: 0, anchor: .center).combined(with: .opacity)
    }
}

// Preview
#Preview {
    ContentView()
}
