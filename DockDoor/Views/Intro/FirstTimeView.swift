import AVFoundation
import Pow
import SwiftUI

struct FirstTimeView: View {
    @State private var showPermissions = false
    @State private var lightsOn = false
    @State private var clicking = false
    @State private var rotating: Bool? = nil
    @State private var rotating2: Bool? = nil
    @State private var rotatingTimer: Timer? = nil
    @State private var hovering = false
    @State private var phrasesSteps = 0
    @State private var clickDownSoundPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "mouse-down", withExtension: "mp3")!)
    @State private var clickUpSoundPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "mouse-up", withExtension: "mp3")!)

    var body: some View {
        let rotationDegrees: Double = 7
        ZStack {
            HStack {
                VStack(spacing: 24) {
                    Button(action: toggleAnimation) {
                        TimelineView(.animation(minimumInterval: 0.15)) { ctx in
                            let zzz = lightsOn ? "1" : ctx.date.description
                            Image(lightsOn ? .rawAppIcon : .sleepingDockDoor)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 140, height: 140)
                                .shadow(color: .black.opacity(hovering ? 0.5 : 0.25), radius: hovering ? 32 : 16, y: hovering ? 24 : 12)
                                .contentTransition(.identity)
                                .overlay {
                                    FluidGradientSample().opacity(hovering ? lightsOn ? 0.5 : 0.75 : 0)
                                        .clipShape(RoundedRectangle(cornerRadius: 31))
                                }
                                .scaleEffect(iconScale)
                                .rotation3DEffect(
                                    .degrees(rotating == nil ? 0 : rotating! ? rotationDegrees : -rotationDegrees),
                                    axis: (x: 1, y: 0, z: 0)
                                )
//                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: hovering)
                                .rotation3DEffect(
                                    .degrees(rotating2 == nil ? 0 : rotating2! ? rotationDegrees / 2 : -rotationDegrees / 2),
                                    axis: (x: 0, y: 0, z: 1)
                                )
//                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(1.0), value: hovering)
                                .changeEffect(
                                    .rise(origin: UnitPoint(x: 0.5, y: 0.2)) {
                                        Text("Z")
                                    },
                                    value: zzz
                                )
                                .onHover { newHovering in
                                    rotatingTimer?.invalidate()
                                    if newHovering {
                                        withAnimation(.easeInOut(duration: 1)) {
                                            rotating = false
                                            rotating2 = false
                                        }
                                        rotatingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                                                rotating = true
                                            }
                                            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(1)) {
                                                rotating2 = true
                                            }
                                        }
                                    } else {
                                        withAnimation(.spring) {
                                            rotating = nil
                                        }
                                        withAnimation(.spring) {
                                            rotating2 = nil
                                        }
                                    }
                                    withAnimation(.smooth(extraBounce: 0.1)) {
                                        hovering = newHovering
                                    }
                                }
                        }
                    }
                    .onLongPressGesture(minimumDuration: 300, maximumDistance: 10, perform: {}) { newClicking in
                        withAnimation(.smooth(extraBounce: 0.25)) {
                            clicking = newClicking
                        }
                    }
                    .foregroundStyle(.white)
                    .buttonStyle(NoBtnStyle())
                    .zIndex(1)
                    .onChange(of: clicking) { new in
                        doAfter(new ? 0 : 0.1) {
                            if new {
                                clickDownSoundPlayer.play()
                            } else {
                                clickUpSoundPlayer.play()
                            }
                        }
                    }
                    .onAppear {
                        clickDownSoundPlayer.volume = 0.25
                        clickUpSoundPlayer.volume = 0.25
                        clickDownSoundPlayer.prepareToPlay()
                        clickUpSoundPlayer.prepareToPlay()
                    }

                    VStack(spacing: 8) {
                        if phrasesSteps >= 1 {
                            Text("Welcome to DockDoor!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }

                        if phrasesSteps >= 2 {
                            Text("Enhance your dock experience!")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }

                    if phrasesSteps >= 3 {
                        Button("Get Started") {
                            openPermissionsWindow()
                        }
                        .buttonStyle(AccentButtonStyle())
                    }
                }
                .padding()
            }
        }
        .padding(.bottom, 51) // To composate navbar
        .frame(width: 600, height: 320)
        .scaleEffect(1)
        .background {
            FluidGradientSample().opacity(lightsOn ? 0.125 : 0)
                .ignoresSafeArea(.all)
        }
        .background {
            BlurView()
                .ignoresSafeArea(.all)
        }
    }

    var iconScale: Double {
        if clicking {
            if lightsOn {
                0.95
            } else {
                0.8
            }
        } else {
            if hovering {
                if lightsOn {
                    1
                } else {
                    0.85
                }
            } else {
                if lightsOn {
                    0.9
                } else {
                    0.8
                }
            }
        }
    }

    func toggleAnimation() {
        if !lightsOn {
            doAfter(0.25) {
                withAnimation(.smooth(extraBounce: 0.25)) { phrasesSteps = 1 }
                doAfter(0.25) {
                    withAnimation(.smooth(extraBounce: 0.25)) { phrasesSteps = 2 }
                    doAfter(0.25) {
                        withAnimation(.smooth(extraBounce: 0.25)) { phrasesSteps = 3 }
                    }
                }
            }
        } else {
            withAnimation(.smooth(extraBounce: 0.25)) { phrasesSteps = 0 }
        }
        withAnimation {
            lightsOn.toggle()
        }
    }

    private func openPermissionsWindow() {
        let contentView = PermissionsSettingsView()

        // Create the hosting controller with the PermView
        let hostingController = NSHostingController(rootView: contentView)

        // Create the settings window
        let permissionsWindow = NSWindow(
            contentRect: NSRect(origin: .zero, size: NSSize(width: 200, height: 200)),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false
        )
        permissionsWindow.center()
        permissionsWindow.setFrameAutosaveName("DockDoor Permissions")
        permissionsWindow.contentView = hostingController.view
        permissionsWindow.title = "DockDoor Permissions"
        permissionsWindow.makeKeyAndOrderFront(nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        FirstTimeView()
    }
}
