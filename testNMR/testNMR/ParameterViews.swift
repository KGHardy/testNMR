//
//  ParameterViews.swift
//  testNMR
//
//  Created by Ken Hardy on 17/05/2023.
//

import SwiftUI

struct ViewHeights {
    var picker: CGFloat = oniPad ? 36 : 24
    var slider: CGFloat = oniPad ? 40 : 30
    var stepper: CGFloat = oniPad ? 28 : 20
}

var vH = ViewHeights()

func sliderChanged (_ value: Float, _ index: Int) -> Void {
    switch index {
    case 2:
        gData.frequency = Int(value)
    case 3:
        gData.t2 = value
    case 4:
        gData.noise = value
    case 5:
        gData.t2 = value
    case 6:
        gData.filter = value
    default: break
    }
}

struct SliderParameter: View {
    var prompt: String
    var index : Int
    @Binding var value: Float
    var minValue : Float
    var maxValue : Float
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(prompt + " " + String(format: "%3.0f", value))
                    .frame(height:16)
                Spacer()
            }
            HStack {
                Text(String(format: "%3.0f", minValue))
                    .padding(.leading, oniPad ? 50 : 5)
                Slider(value: $value, in: minValue...maxValue,
                       onEditingChanged: {
                    editing in
                    if !editing {sliderChanged(value,0)}
                })
                {
                    Text(prompt)
                }
                Text(String(format: "%3.0f", maxValue))
                    .padding(.trailing, oniPad ? 50 : 5)
            }
            .padding(.top, oniPad ? -10 : -20)
        }
    }
}

func pickerChanged(_ value: String, _ index: Int) -> Void
{
    switch index {
    case 0:
        gData.experiment = value
    case 1:
        gData.sample = value
    default:
        break
    }
    
}

struct PickerParameter: View {
    var prompt: String
    var index: Int
    @Binding var value: String
    var values: [String]
    
    var body: some View {
        HStack {
            Text(prompt)
                .padding(.leading, 20)
            Picker(prompt, selection: $value) {
                ForEach(values, id: \.self) { v in
                    Text(v)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: value, perform: {val in pickerChanged(value, index)})
        }
    }
}

struct IntegerParameter: View {
    @EnvironmentObject var vC: ViewControl
    var prompt: String
    var index: Int
    @Binding var value: String
    var minimum: Int
    var maximum: Int
    
    func storeValue() {
        switch index {
        case 2:
            gData.frequency = Int(value) ?? 0
        default: break
        }
   }
   
    var body: some View {
        var ovalue = value
        HStack {
            Text("\(prompt): ")
                .padding(.leading, oniPad ? 50 : 5)
            TextField("", text: $value)
                .padding(.leading, 2)
                //.border(.black)
                .foregroundColor(.black)
                .background(Color(red:240/255, green:240/255, blue:240/255))
                .keyboardType(oniPad ? .asciiCapableNumberPad : .asciiCapable)
                .submitLabel(.done)
                .onChange(of: value, perform: {entry in
                    if entry == "" {
                        value = entry
                        ovalue = entry
                    } else {
                        let nvalue = entry.filter{$0.isNumber}
                        if let nv = Int(nvalue) {
                            if nv >= minimum && (nv <= maximum || maximum == 0) {
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
        }
    }
}

func stepperChanged(_ value: Int, _ index: Int) -> Void {
    switch index {
    case 7:
        gData.noOfRuns = value
    case 8:
        gData.noOfExperiments = value
    case 9:
        gData.noOfScans = value
    case 10:
        gData.repeatTime = value
    default:
        break
    }
}

struct StepperParameter: View {
    var prompt: String
    var index: Int
    @Binding var value: Int
    var minValue : Int
    var maxValue : Int
    
    var body: some View {
        HStack {
            Stepper(prompt + " \(value)", value: $value, in: minValue...maxValue)
                .onChange(of: value, perform: {val in stepperChanged(value, index)})
                .padding(.leading, oniPad ? 50 : 5)
                .padding(.trailing, oniPad ? 50 : 5)
                .frame(height: vH.stepper)
        }
        
    }
}

struct ActionButton: View {
    @EnvironmentObject var vC: ViewControl
    
    func buttonText() -> String {
        switch vC.viewName {
        case .parameters:
            runData.errorMsg = ""
            return "Start"
        case .running:
            return "Running \(runData.run + 1)/\(runData.experiment + 1)/\(runData.scan + 1)"
        case .results:
            if runData.running {
                return "Running \(runData.run + 1)/\(runData.experiment + 1)/\(runData.scan + 1)"
            } else {
                return "Done"
            }
        default:
            return "Error"
        }
    }
    
    var body: some View {
        Text(buttonText())
            .foregroundColor(vC.viewName == .running ? .red : .black)
            .padding(5)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green, lineWidth: 3))
            .onTapGesture {
                switch vC.viewName {
                case .parameters:
                    vC.viewName = .running
                    runData.errorMsg = ""
                    doExperiment(noOfRuns: gData.noOfRuns, noOfScans: gData.noOfScans, noOfExperiments: gData.noOfExperiments)
                case .running:
                    nmr.cancel()
                    runData.errorMsg = "Cancelled by user"
                    runData.running = false
                    vC.viewName = .parameters
                case .results:
                    if runData.running {
                        nmr.cancel()
                        runData.errorMsg = "Cancelled by user"
                        runData.running = false
                    }
                    vC.viewName = .parameters
                default:
                    vC.viewName = .parameters
                }
            }
    }
}

struct ResultButton: View {
    @EnvironmentObject var vC: ViewControl
    
    func buttonText() -> String {
        switch vC.viewResult {
        case .raw:
            return "FT"
        case .ft:
            return "Fit"
        case .fit:
            return "Raw"
        }
    }
    
    var body: some View {
        Text(buttonText())
            .foregroundColor(.black)
            .padding(5)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green, lineWidth: 3))
            .onTapGesture {
                switch vC.viewResult {
                case .raw:
                    vC.viewResult = .ft
                case .ft:
                    vC.viewResult = .fit
                case .fit:
                    vC.viewResult = .raw
                }
            }
    }
}

struct ActionButtons: View {
    @EnvironmentObject var vC: ViewControl

    var body: some View {
        if vC.viewName == .results {
            HStack {
                Spacer()
                ActionButton()
                    .padding(20)
                ResultButton()
                Spacer()
            }
        } else {
            ActionButton()
        }
    }
}

struct ExperimentView: View {
    @State var experiment: String = gData.experiment
    var body: some View {
        PickerParameter(prompt: "\(allSettings.paramMap.prompts[0]):", index: 0, value: $experiment, values: gData.experiments)
            .frame(height: vH.picker)
    }
}

struct SampleView: View {
    @State var sample: String = gData.sample
    var body: some View {
        PickerParameter(prompt: "\(allSettings.paramMap.prompts[1]):", index: 1, value: $sample, values: gData.samples)
            .frame(height: vH.picker)
    }
}

struct FilterParameter: View {
    @State var filter: Float = gData.filter
    var body: some View {
        SliderParameter(prompt: "\(allSettings.paramMap.prompts[6]):", index: 6, value: $filter, minValue: 0, maxValue: 500)
            .frame(height: vH.slider)
    }
}

struct NoiseParameter: View {
    @State var noise: Float = gData.noise
    var body: some View {
        SliderParameter(prompt: "\(allSettings.paramMap.prompts[4]): ", index: 4, value: $noise, minValue: 0, maxValue: 10)
            .frame(height: vH.slider)
    }
}

struct RepeatTimeView: View {
    @State var repeatTime = gData.repeatTime
    var body: some View {
        StepperParameter(prompt: "\(allSettings.paramMap.prompts[10]):", index: 10, value: $repeatTime, minValue: 1, maxValue: 20)
    }
}

struct NumberOfRunsView: View {
    @State var noOfRuns = gData.noOfRuns
    var body: some View {
        StepperParameter(prompt: "\(allSettings.paramMap.prompts[7]):", index: 7, value: $noOfRuns, minValue: 1, maxValue: 100)
    }
}

struct NumberOfExperimentsView: View {
    @State var noOfExperiments = gData.noOfExperiments
    var body: some View {
        StepperParameter(prompt: "\(allSettings.paramMap.prompts[8]):", index: 8, value: $noOfExperiments, minValue: 1, maxValue: 100)
    }
}

struct NumberOfScansView: View {
    @State var noOfScans = gData.noOfScans
    var body: some View {
        StepperParameter(prompt: "\(allSettings.paramMap.prompts[9]):", index: 9, value: $noOfScans, minValue: 1, maxValue: 100)
    }
}

struct FrequencyView: View {
    @EnvironmentObject var vC: ViewControl
    @State var frequency = "\(viewControl.frequency)"
    var body: some View {
        IntegerParameter(prompt: "\(allSettings.paramMap.prompts[2])", index: 2, value: $vC.frequency, minimum: 0, maximum: 0)
            .frame(height: vH.slider)
            .disabled(vC.disableFrequency)
    }
}

struct PulseLengthView: View {
    @State var pulseLength : Float = gData.pulseLength
    var body: some View {
        SliderParameter(prompt: "\(allSettings.paramMap.prompts[3]):", index: 3, value: $pulseLength, minValue: 0, maxValue: 20000)
            .frame(height: vH.slider)
    }
}

struct T2View: View {
    @State var t2 : Float = gData.t2
    var body: some View {
        SliderParameter(prompt: "\(allSettings.paramMap.prompts[5]):", index: 5, value: $t2, minValue: 0, maxValue: 20000)
            .frame(height: vH.slider)
    }
}
