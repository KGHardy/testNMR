//
//  testNMRApp.swift
//  testNMR
//
//  Created by Ken Hardy on 09/05/2023.
//

import SwiftUI

struct GlobalData {
    //index 0
    var experiments = [ "Find Resonance", "Find Pulse Length", "Free Induction Decay", "Spin-Lattice Relaxation","Spin-Spin Relaxation"]
    var experiment: String = "Free Induction Decay"
    var exptNames = ["", "", "FID", "", "", ""]
    var exptName: String = ""
    
    //index 1
    var samples = ["Solvent","Inorganic Dispersion","Organic Dispersion","Polymer Solution","Paramagnetic Solution"]
    var sample: String = ""
    
    // index 2
    var frequency: Int = 16004000
    
    // index 3
    var pulseLength : Float = 0
    
    // index 4
    var noise: Float = 0
    
    // index 5
    var t2 : Float = 0
    
    // index 6
    var filter: Float = 0
    
    // index 7
    var noOfRuns: Int = 1
    
    // index 8
    var noOfExperiments: Int = 1
    
    // index 9
    var noOfScans: Int = 1
    
    // index 10
    var repeatTime: Int = 1
    
    mutating func initialValues() -> Void {
        experiment = experiments[2]
        sample = samples[0]
    }
    
    func getFrequency() -> Int {
        return frequency
    }
}

var gData = GlobalData()
let queue = DispatchQueue(label: "work-queue", qos: .default)
var nmr = NMRServer()

enum ViewNames {
    case parameters     // 0
    case running        // 1
    case results        // 2
    case settings       // 3
}

enum ViewResults {
    case raw            // 0
    case ft             // 1
    case fit            // 2
}

class ViewControl: ObservableObject {
    @Published var viewName = ViewNames.parameters
    @Published var viewRefreshFlag: Bool = false
    @Published var viewResult = ViewResults.raw
    @Published var viewMenu: Bool = false
    
    @Published var frequency : String = "\(gData.frequency)"
    @Published var disableFrequency: Bool = false

    func viewRefresh() -> Void {
        viewRefreshFlag = !viewRefreshFlag
    }
    var viewStack: [ViewNames] = []
    
    func pushName() -> Void {
        viewStack.append(viewName)
    }
    
    func popName() -> ViewNames {
         return viewStack.popLast()!
    }

}

var viewControl = ViewControl()

var running = false
var oniPad = UIDevice.current.userInterfaceIdiom == .pad
var landscape = UIDevice.current.orientation.isLandscape

@main
struct testNMRApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    init() {
        gData.initialValues()
        _ = readSettings()
    }

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(viewControl)
        }
        .onChange(of: scenePhase) {newPhase in
            switch newPhase {
            case .background:
                break
            case .inactive:
                break
            case .active:
                if !running { // startup code runs after first ContentView
                    running = true
                }
            default:
                break
            }
        }
    }
}
