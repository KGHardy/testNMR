//
//  Settings.swift
//  testNMR
//
//  Created by Ken Hardy on 23/05/2023.
//

import SwiftUI

enum Focusable: Hashable {
    case none
    case field(id: Int)
}

struct EntryField : View {
    @Binding var value : String
    @FocusState.Binding var focusField: Focusable?
    var max: Int
    var index: [Int]

     func storeValue() {
        copySettings.paramMap.page[index[0]][index[1]] = Int(value) ?? 0
    }
    
    var body: some View {
        
        var ovalue = value
        TextField("", text: $value)
            .focused($focusField, equals: .field(id: index[0] * 100 + index[1]))
            .padding(.leading, 2)
            .border(.black)
            .foregroundColor(.black)
            .keyboardType(oniPad ? .asciiCapableNumberPad : .asciiCapable)
            .submitLabel(.done)
            /*.onChange(of: focused, perform: { isFocused in
                if !isFocused {
                    storeValue()
                }
            })*/
            .onChange(of: value, perform: {entry in
                if entry == "" {
                    value = entry
                    ovalue = entry
                } else {
                    let nvalue = entry.filter{$0.isNumber}
                    if let nv = Int(nvalue) {
                        if nv >= 0 && nv <= max {
                            value = "\(nv)"
                            ovalue = value
                            storeValue()
                        } else {
                            value = ovalue
                        }
                    } else {
                        value = ovalue
                    }
                }
            })
            .onSubmit {
                storeValue()
                var ix0 = index[0]
                var ix1 = index[1] + 1
                if ix1 >= allSettings.paramMap.prompts.count {
                    ix0 += 1
                    ix1 = 0
                    if ix0 >= allSettings.paramMap.page.count {
                        focusField = Focusable.none
                        return
                    }
                }
                focusField = .field(id: ix0 * 100 + ix1)
            }
    }
}

struct ScannerSettings: Codable {
    var hostname: String = "10.42.0.1"
    var hostport: Int = 1001
}
/*
 
 let hostName = p.hostName!               // 0
 let portNo = p.portNo!                   // 1
 let ncoFreq = p.ncoFreq!                 // 2
 let pulseLength = p.pulseLength!         // 3
 //var pulseStep = 0                        // 4
 let littleDelta = p.littleDelta!         // 5   in micros
 let bigDelta = p.bigDelta! * 1000        // 6   in ms
 //let noScans: Int = 1
 let gradient = p.gradient!               // 7
 //let noExpts:Int  = 1
 var rptTime = p.rptTime!                 // 8
 rptTime *= 1000
 var tauTime = p.tauTime!                 // 9
 var t1Guess = tauTime
 if t1Guess > 2000 { t1Guess = 2000 }
 if tauTime < 25 && tauTime > 0 { tauTime = 50 }
 var tau = tauTime
 let tauInc = p.tauInc!                   // 10
 let noData = p.noData!                   // 11
 let exptSelect = p.exptSelect!           // 12
 var noEchoes: Int = 0
 if ["CPMG", "CPMGX", "CPMXY"].contains(exptSelect) {noEchoes = tauInc }
 let delayInSeconds = p.delayInSeconds!   // 13
 var tauD = p.tauD!                       // 14
 if tauD > 100000 { tauD = 100000 }
 var progSatDelay = p.progSatDelay!       //15
 
 var hostName: String?           // 0
 var portNo: Int?                // 1
 var ncoFreq: Int?               // 2
 var pulseLength: Int?           // 3
 var pulseStep: Int?             // 4 superceded
 var littleDelta: Int?           // 5
 var bigDelta: Int?              // 6
 var gradient: Int?              // 7
 var rptTime: Int?               // 8
 var tauTime: Int?               // 9
 var tauInc: Int?                // 10
 var noData: Int?                // 11
 var exptSelect: String?         // 12
 var delayInSeconds: Double?     // 13
 var tauD: Int?                  // 14
 var progSatDelay: [Int]?        // 15

 */

enum ParamType {
    case integer
    case string
    case double
    case integerarray
}

enum ParamView {
    case nothing
    case picker
    case stepper
    case slider
    case text
}
/*
struct Param {
    var pName: String
    var pPrompt: String
    var pType: ParamType
    var pView: ParamView
    
    var min: Double?
    var max: Double?
    
    var values: [String]?
    
    init(_ pName: String, _ pPrompt: String, _ pType: ParamType, _ pView: ParamView) {
        self.pName = pName
        self.pPrompt = pPrompt
        self.pType = pType
        self.pView = pView
    }
}

var Parameters: [Param] = [Param("hostname", "Host Name", .string, .text),
                           Param("portno", "Port Number", .integer, .text),
                           Param("ncofreq", "nco Frequency", .integer, .slider)
]


struct NewParameterMap {
    var params  = ["hostname",          // 0                String
                   "portno",            // 1                Integer
                   "ncofreq",           // 2                Integer
                   "pulselength",       // 3                Integer
                   "pulsestep",         // 4 = 0            Integer
                   "littledelta",       // 5                Integer
                   "bigdelta",          // 6                Integer
                   "gradient",          // 7                Integer
                   "rpttime",           // 8                Integer
                   "tautime",           // 9                Integer
                   "tauinc",            // 10               Integer
                   "nodata",            // 11               Integer
                   "exptselect",        // 12               String
                   "delayinseconds",    // 13               Double
                   "taud",              // 14               Integer
                   "progsatarray",      // 15               Integer Array
                   "sample",            //                  String
                   "noruns",            //                  Integer
                   "noexperiments",     //                  Integer
                   "noscans"            //                  Integer
                  ]
    
    var paramTypes: [ParamType] = [
                    .string,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .string,
                    .double,
                    .integer,
                    .integerarray,
                    .string,
                    .integer,
                    .integer,
                    .integer
    ]
    var prompts = [
                                            // Passed parameter data
                    "Host Name",
                    "Port Number",
                    "Frequency",
                    "Pulse Length",
                    "Pulse Step",
                    "Little Delta",
                    "Big Delta",
                    "Gradient",
                    "Repeat Time",
                    "Tau Time",
                    "Tau Inc",
                    "Number of Datapoints",
                    "Experiment Name",
                    "Delay in Seconds",
                    "Tau D",
                    "Prog Sat Delay",
                                            // Other data to be entered
                    "Sample",
                    "Number of Runs",
                    "Number of Experiments",
                    "Number of Scans"
                  ]
}
*/
struct ParameterMap: Codable {
    var prompts = ["Experiment",                //  0
                   "Sample",                    //  1
                   "Frequency Hz",              //  2
                   "Pulse Length/ns",           //  3
                   "Noise %",                   //  4
                   "T2/𝛍s",                     //  5
                   "Filter",                    //  6
                   "Number of Runs",            //  7
                   "Number of Experiments",     //  8
                   "Number of Scans",           //  9
                   "Repeat Time",               // 10
                   "Action Buttons"             // 11
    ]
    
    var page : [[Int]] = [[0,0,1,2,3,4,5,0,0,0,0,6],
                          [1,6,0,0,0,0,0,2,3,4,5,7],
                          [0,0,0,0,0,0,0,0,0,0,0,0],
                          [0,0,0,0,0,0,0,0,0,0,0,0]]
    
    @ViewBuilder func getView(index: Int) -> some View {
        
        switch index {
        case 0:  ExperimentView()
        case 1:  SampleView()
        case 2:  FrequencyView()
        case 3:  PulseLengthView()
        case 4:  NoiseParameter()
        case 5:  T2View()
        case 6:  FilterParameter()
        case 7:  NumberOfRunsView()
        case 8:  NumberOfExperimentsView()
        case 9:  NumberOfScansView()
        case 10: RepeatTimeView()
        case 11: ActionButtons()
        default: EmptyView()
        }
    }    
}

struct AllSettings: Codable {
    var paramMap = ParameterMap()
    var scanner = ScannerSettings()
}

struct ParamPos {
    var pages : [Int] = [0,1]
    
    var pageSeq: [[Int]] = [[2,3,4,5,6,11],[0,7,8,9,10,1,11]]
    
    var focusedField: Int = 0
    
    mutating func build(paramMap: ParameterMap) -> Void {
        pageSeq.removeAll(keepingCapacity: true)
        pages.removeAll(keepingCapacity: true)
        
        var maxS: Int = 0
        var p = -1
        
        for x in 0..<paramMap.page.count {
            maxS = 0
            for y in 0..<paramMap.page[x].count {
                if paramMap.page[x][y] > maxS { maxS = paramMap.page[x][y]}
            }
            if maxS > 0 {
                p += 1
                pages.append(p)
                pageSeq.append([])
                for s in 1...maxS {
                    for y in 0..<paramMap.page[x].count {
                        if paramMap.page[x][y] == s {
                            pageSeq[p].append(y)
                        }
                    }
                }
            }
        }
        maxS = 0
    }
}

var paramPos = ParamPos()

var allSettings = AllSettings()
var copySettings = AllSettings()        // copy for cancellation in settings

struct ParameterPosition : View {
    @FocusState.Binding var focusField: Focusable?
    
    @State var redraw: Bool = false

    @State var page0 : String
    @State var page1 : String
    @State var page2 : String
    @State var page3 : String

    var index: Int

    /*init(index: Int) {
        self.focusField = Focusable.none
        self.index = index
        self.page0 = "\(allSettings.paramMap.page[0][index])"
        self.page1 = "\(allSettings.paramMap.page[1][index])"
        self.page2 = "\(allSettings.paramMap.page[2][index])"
        self.page3 = "\(allSettings.paramMap.page[3][index])"
    }*/
    
    var body: some View {
        GeometryReader { reader in
            HStack {
                Text("\(copySettings.paramMap.prompts[index])")
                    .padding(.leading, 10)
                    .frame(width: reader.size.width * 0.6, alignment: .leading)
                    .onTapGesture {
                        focusField = .field(id: index)
                        redraw.toggle()
                    }
                Spacer()
                EntryField(value: $page0, focusField: $focusField, max: 99, index: [0,index])
                EntryField(value: $page1, focusField: $focusField, max: 99, index: [1,index])
                EntryField(value: $page2, focusField: $focusField, max: 99, index: [2,index])
                EntryField(value: $page3, focusField: $focusField, max: 99, index: [3,index])
            }
        }
    }
}

struct SettingsPP: View {
    @EnvironmentObject var vC : ViewControl
    @Environment(\.presentationMode) var presentationMode
    //var size : CGSize
    
    @FocusState var focusField: Focusable?
    @State var redraw: Bool = false

    var body: some View {
        //let fontSize : CGFloat  = oniPad ? 24 : 16
        NavigationView {
            GeometryReader {reader in
                VStack {
                    //List {
                    //Group() {
                        HStack {
                            Text("Parameter Name")
                                .padding(.leading, 10)
                                .frame(width: reader.size.width * 0.58, alignment: .leading)
                                .onTapGesture {
                                    focusField = Focusable.none
                                    redraw.toggle()
                                }
                            Spacer()
                            Text(oniPad ? "P1 seq" : "P1")
                                .frame(width: reader.size.width * 0.09, alignment: .leading)
                                .font(.system(size: oniPad ? 17 : 15))
                            Text(oniPad ? "P2 seq" : "P2")
                                .frame(width: reader.size.width * 0.09, alignment: .leading)
                                .font(.system(size: oniPad ? 17 : 15))
                            Text(oniPad ? "P3 seq" : "P3")
                                .frame(width: reader.size.width * 0.09, alignment: .leading)
                                .font(.system(size: oniPad ? 17 : 15))
                            Text(oniPad ? "P4 seq" : "P4")
                                .frame(width: reader.size.width * 0.09, alignment: .leading)
                                .font(.system(size: oniPad ? 17 : 15))
                        }
                        
                    ForEach (0..<allSettings.paramMap.prompts.count, id: \.self) { index in
                            ParameterPosition(focusField: $focusField,
                                              page0: "\(allSettings.paramMap.page[0][index])",
                                              page1: "\(allSettings.paramMap.page[1][index])",
                                              page2: "\(allSettings.paramMap.page[2][index])",
                                              page3: "\(allSettings.paramMap.page[3][index])",
                                              index: index)
                            .frame(height: vH.stepper)
                        }
                    HStack {
                        Spacer()
                        Button(action:{
                            allSettings.paramMap = copySettings.paramMap
                            paramPos.build(paramMap: allSettings.paramMap)
                            saveSettings()
                            presentationMode.wrappedValue.dismiss()
                        }, label:{
                            Text("Save")
                                .font(.system(size: oniPad ? 24 : 16))
                                .padding(5)
                                .border(.black)
                        })
                        Button(action:{
                            copySettings.paramMap = allSettings.paramMap
                            presentationMode.wrappedValue.dismiss()
                        }, label:{
                            Text("Cancel")
                                .font(.system(size: oniPad ? 24 : 16))
                                .foregroundColor(.red)
                                .padding(5)
                                .border(.black)
                        })
                        Spacer()
                    }
                    Spacer()
                }
                .navigationBarTitle("Parameter Map", displayMode: .inline)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            focusField = .field(id: 0)
        }
    }
}

struct Settings: View {
    var size: CGSize
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: ScannerSettingsView(size: size)) {
                    HStack {
                        Text("Scanner Settings")
                            .font(.system(size: 20))
                            .padding(.leading, 40)
                        Spacer()
                        Text(">")
                            .font(.system(size: 20))
                            .padding(.trailing, 40)
                    }
                }
                .padding(.top, 10)
                NavigationLink(destination: SettingsPP()) {
                    HStack {
                        Text("Parameter Map")
                            .font(.system(size: 20))
                            .padding(.leading, 40)
                        Spacer()
                        Text(">")
                            .font(.system(size: 20))
                            .padding(.trailing, 40)
                    }
                }
                .padding(.top, 10)
                HStack {
                    Text("Return")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .padding(.leading, 40)
                    Spacer()
                    Text(">")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .padding(.trailing, 40)
                }
                .padding(.top, 10)
                .onTapGesture {
                    viewControl.viewName = viewControl.popName()
                }
                .navigationBarTitle("Settings", displayMode: .inline)
                Spacer()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings(size: CGSize(width: 100, height: 00))
    }
}

struct ScannerSettingsView : View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var vC : ViewControl
    var size : CGSize
    @State private var hostName : String = allSettings.scanner.hostname
    @State private var portNumber : String = "\(allSettings.scanner.hostport)"
    @FocusState var focusField: Focusable?
    
    var body: some View {
            
        let fontSize : CGFloat  = oniPad ? 24 : 16

        NavigationView {
            VStack {
                Section(header: Text("Scanner Address").font(.system(size: fontSize)))
                {
                    HStack {
                        Text("Host Name")
                            .font(.system(size: fontSize))
                            .padding(.leading, 5)
                        TextField("Host Name", text: $hostName)
                            .focused($focusField, equals: .field(id: 1))
                            .font(.system(size: fontSize))
                            .border(.black)
                            .padding(.leading)
                            .onSubmit {
                                focusField = .field(id: 2)
                            }
                    }
                    HStack {
                        Text("Port Number")
                            .font(.system(size: fontSize))
                            .padding(.leading, 5)
                        TextField("Port Number", text: $portNumber)
                            .focused($focusField, equals: .field(id: 2))
                            .font(.system(size: fontSize))
                            .border(.black)
                            .padding(.leading)
                            .keyboardType(.decimalPad)
                            .onChange(of: portNumber, perform: { value in
                                portNumber = value.filter { $0.isNumber}
                            })
                            .onSubmit {
                                focusField = .field(id: 1)
                            }
                    }
                }
                Section("") {
                    HStack {
                        Spacer()
                        Button(action:{
                            allSettings.scanner.hostname = hostName
                            redPitayaIp = hostName
                            allSettings.scanner.hostport = Int(portNumber) ?? 0
                            saveSettings()
                            presentationMode.wrappedValue.dismiss()
                        }, label:{
                            Text("Save")
                                .font(.system(size: fontSize))
                                .padding(5)
                                .border(.black)
                        })
                        Button(action:{
                            hostName = allSettings.scanner.hostname
                            portNumber = "\(allSettings.scanner.hostport)"
                            presentationMode.wrappedValue.dismiss()
                        }, label:{
                            Text("Cancel")
                                .font(.system(size: fontSize))
                                .foregroundColor(.red)
                                .padding(5)
                                .border(.black)
                        })
                        Spacer()
                    }
                }
                Spacer()
            }
        }
        .navigationBarTitle("Scanner Settings", displayMode: .inline)
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            focusField = .field(id: 1)
            hostName = allSettings.scanner.hostname
            portNumber = "\(allSettings.scanner.hostport)"
        }
    }
}

func buildFilename(name: String) -> URL
{
    let homeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    if name != "" {
        if let fileURL = homeURL?.appendingPathComponent(name) {
            return fileURL
        }
    }
    return homeURL!
}


func deleteAFile(filename: String) -> Void {
    let fileURL = buildFilename(name: filename)
    let fm = FileManager.default
    var filePath = fileURL.absoluteString
    filePath.removeFirst(7)
    if fm.fileExists(atPath: filePath) {
        do {
            try fm.removeItem(at: fileURL)
        }
        catch {
        }
    }
}

func saveToFile(string: String, filename: String) -> Void {
    let fileURL = buildFilename(name: filename)
    let fm = FileManager.default
    var filePath = fileURL.absoluteString
    filePath.removeFirst(7)
    if fm.fileExists(atPath: filePath) {
        do {
            try fm.removeItem(at: fileURL)
        }
        catch {
        }
    }
    do {
        try string.write(to: fileURL, atomically: false, encoding: .utf8)
    } catch {
        print("Write Failed")
    }
}

func readFromFile(fileName: String) -> String {
    let fileURL = buildFilename(name: fileName)
    do {
        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        return contents
    } catch {
        return ""
    }
}

func readSettings() -> Bool {
    do {
        let settingsString = readFromFile(fileName: "testNMR.json")
        if settingsString.count > 0 {
            let decoder = JSONDecoder()
            allSettings = try decoder.decode(AllSettings.self, from: settingsString.data(using: .utf8)!)
            redPitayaIp = allSettings.scanner.hostname
            paramPos.build(paramMap: allSettings.paramMap)
            return true
        }
        return false
    } catch {
        return false
    }
}

func saveSettings() -> Void {
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    do {
        let data = try encoder.encode(allSettings)
        let settingsString = String(data: data, encoding: .utf8)!
        saveToFile(string: settingsString, filename: "testNMR.json")
    } catch {
        return
    }
}
