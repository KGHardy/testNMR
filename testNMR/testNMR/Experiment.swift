//
//  Experiment.swift
//  testNMR
//
//  Created by Ken Hardy on 11/06/2023.
//

import Foundation

struct ScanResult: Codable {
    var parameters: NewParameters
    var nmrResult : [[Int16]]
}

struct RunData {
    var run: Int = 0
    var experiment: Int = 0
    var scan: Int = 0
    var running = false
    var runCount: Int = 0
    var experimentCount: Int = 0
    var scanCount: Int = 0
    
    var definition: ExperimentDefinition?
    var nmrResult: [[Int16]] = []
    var results: [[[NewResult]]] = []
    var errorMsg = ""
}

var runData = RunData()

class ExperimentDefinition {
    enum WhenToAction {
        case run
        case experiment
        case scan
    }
    struct ParameterStep {
        var name: String
        var index = 0
        var step: Double
        var when: WhenToAction
        var pause: Double
    }
    var runCount: Int = 0
    var experimentCount: Int = 0
    var scanCount: Int = 0
    
    var parameters: [NewParameters] = []
    var parameterIndex = 0
    var steps: [ParameterStep] = []
    
    var preScan: () -> Bool = { return true }
    var postScan: () -> Bool = { return true }
    var postScanUI: () -> Void = { return }
    
    var endRun: () -> Void = { return }
    var endRunUI: () -> Void = { return }
    var startRun: () -> Void = { return }
    
    func doStepPause(step: ParameterStep) -> Void {
        switch step.when {
        case .run:
            if runData.run > 0 && runData.experiment == 0 && runData.scan == 0 { break }
            return
        case .experiment:
            if runData.experiment > 0 && runData.scan == 0 { break }
            return
        case .scan:
            if runData.scan > 0 { break }
            return
        }
        if step.pause > 0 {
            Thread.sleep(forTimeInterval: step.pause)
        }
        if step.index < parameters.count {
            switch step.name {
            case "ncoFreq":
                parameters[step.index].ncoFreq! += Int(step.step)
            case "pulseStep":
                parameters[step.index].pulseStep! += Int(step.step)
            default:
                break
            }
        }
    }
    
    func testStepPause() -> Void {
        for step in steps {
            doStepPause(step: step)
        }
    }
    
    func run() -> Void {
        /*
                run     experiment      scan
                0       0               0               First run, experiment and scan
                0       0               > 0             First run and experiment subsequent scan
                0       > 0             0               First run subsequent experiment first scan
                0       > 0             > 0             First run subsequent experiment and scan
                > 0     0               0               Subsequent run first experiment and scan
                > 0     0               > 0             Subsequent run first experiment subsequent scan
                > 0     > 0             0               Subsequent run and experiment first scan
                > 0     > 0             > 0             Subsequent run experiment and scan
         */
        
        func abortRun(viewName: ViewNames) -> Void {
            runData.running = false
            DispatchQueue.main.async{
                viewControl.viewName = viewName
            }
            
        }
        
        func updateResults() -> Void {
            if runData.experiment == 0 && runData.scan == 0 {
                assert(runData.results.count == runData.run, "runData.results assert run failed")
                runData.results.append([])
            }
            if runData.scan == 0 {
                assert(runData.results[runData.run].count == runData.experiment, "runData.results assert experiment failed")
                runData.results[runData.run].append([])
            }
            assert(runData.results[runData.run][runData.experiment].count == runData.scan, "runData.results assert scan failed")
            runData.results[runData.run][runData.experiment].append(nmr.newResult)
        }
        
        func callExperiment() -> Void {
            for run in 0..<runData.runCount {
                for experiment in 0..<runData.experimentCount {
                    for scan in 0..<runData.scanCount {
                        runData.run = run
                        runData.experiment = experiment
                        runData.scan = scan
                        self.testStepPause()
                        if self.preScan() {
                            if self.parameterIndex < 0 || self.parameterIndex >= self.parameters.count {
                                runData.errorMsg = "Parameter index out of bounds"
                                abortRun(viewName: .results)
                                break
                            }
                            runData.nmrResult = nmr.experiment(self.parameters[self.parameterIndex])
                            if nmr.newResult.count() > 0 {
                                updateResults()
                                if self.postScan() {
                                    DispatchQueue.main.async {
                                        viewControl.viewName = .results
                                        self.postScanUI()
                                    }
                                } else {
                                    if runData.errorMsg == "" {
                                        runData.errorMsg = "Run cancelled in postScan"
                                    }
                                    abortRun(viewName: .results)
                                    return
                                }
                            } else {
                                runData.errorMsg = nmr.retError
                                abortRun(viewName: .parameters)
                                return
                            }
                        } else {
                            if runData.errorMsg == "" {
                                runData.errorMsg = "Run cancelled in preScan"
                            }
                            abortRun(viewName: .results)
                            return
                        }
                    }
                }
            }
            runData.running = false
            self.endRun()
            DispatchQueue.main.async {
                self.endRunUI()
            }
        }
        
        runData.run = 0
        runData.runCount = runCount
        runData.experiment = 0
        runData.experimentCount = experimentCount
        runData.scan = 0
        runData.scanCount = scanCount

        runData.errorMsg = ""

        runData.definition = self

        runData.nmrResult.removeAll(keepingCapacity: true)
        runData.results.removeAll(keepingCapacity: true)
                
        runData.running = true
        startRun()
        queue.async {
            callExperiment()
        }
    }
}


var xData = Array(stride(from:0.0, through: Double(4095), by: 1.0))

let useNew = true

//var inProgress = false
//var run = 0
//var experiment = 0
//var scan = 0


var fitsReturned: [[Double]] = [[]]
var frequencyMeasured: [Double] = []
var frequencyScan: [Double] = []

func doFIDAnalysis() -> Bool {
    let dataReturn = dataAquirer(xData,runData.nmrResult)
    yRealdata = dataReturn.1
    yImagdata = dataReturn.2
    xFTdata = dataReturn.3
    yFTdata = dataReturn.4
    xFitdata = dataReturn.5
    yFitdata = dataReturn.6
    if runData.scan == 0 {
        fitsReturned.append([dataReturn.7, dataReturn.8, dataReturn.9])
        frequencyMeasured.append(dataReturn.7)
        frequencyScan.append(Double(runData.definition!.parameters[0].ncoFreq!))
    } else {
        fitsReturned[runData.experiment] = [dataReturn.7, dataReturn.8, dataReturn.9]
        frequencyMeasured[runData.experiment] = dataReturn.7
    }
    
    if frequencyScan.count > 1 {
        xPsd = (0..<frequencyScan.count).map {frequencyScan[$0] - 16000000}
        yPsd = (0..<frequencyMeasured.count).map {frequencyMeasured[$0] }
        let result = linearFit(xPsd,yPsd)
        xFit = result.0
        yFit = result.1
        
        let xScale = xFit.max()! - xFit.min()!
        let yScale = yFit.max()! - yFit.min()!
        
        let x0 = 0 - xFit.min()!
        let y0 = yScale * x0 / xScale - yFit.max()!
        
        //print(y0)
        gData.frequency = 16000000 - Int(y0)
    }

    return true
}

func clearFIDAnalysis() -> Bool {
    if runData.experiment == 0 && runData.scan == 0 {   //start a run }
        fitsReturned.removeAll(keepingCapacity: true)
        frequencyMeasured.removeAll(keepingCapacity: true)
        frequencyScan.removeAll(keepingCapacity: true)
    }
    return true         // true means continue - false means abort (set runData.errorMsg to say why)
}

func showFit() -> Void {
    viewControl.viewResult = runData.experiment > 1 ? .fit : .raw
    viewControl.frequency = "\(gData.frequency)"
    viewControl.disableFrequency = true
}

func doExperiment(noOfRuns: Int = 1, noOfScans: Int, noOfExperiments: Int) -> Void {
    var nparams = NewParameters()
        
    nparams.exptSelect = "FID"
    nparams.ncoFreq = gData.frequency
    nparams.defaults()
    
    let definition = ExperimentDefinition()
    
    definition.parameters.append(nparams)       // array of parameters so can be different for some scans
    definition.preScan = clearFIDAnalysis       // clear analysis totals before a new run
    definition.postScan = doFIDAnalysis         // calls analysis function after each scan
    definition.postScanUI = showFit             // set graph display after each scan
    definition.endRunUI = showFit               // set graph display to desired end result
    
    definition.runCount = noOfRuns
    definition.experimentCount = noOfExperiments
    definition.scanCount = noOfScans
    let step1 = ExperimentDefinition.ParameterStep(name: "ncoFreq", index: 0, step: -1000.0, when: .experiment, pause: Double(gData.repeatTime))
    definition.steps.append(step1)
    
    definition.run()
/*
    var params = SuppliedParameters()
    var nParams = NewParameters()
    experiment = 1
    scan = 1
    
    fitsReturned.removeAll(keepingCapacity: true)
    frequencyMeasured.removeAll(keepingCapacity: true)
    frequencyScan.removeAll(keepingCapacity: true)

    
    func callExperiment() -> Void {
        params.ncoFreq = 16000000 - 1000 * experiment
        nParams.ncoFreq = params.ncoFreq
        if experiment > noOfExperiments {
            //scan = 0
            //experiment = 0
            return
        }
        if scan <= noOfScans {
            queue.async {
                var nmrResult: [[Int16]]
                if scan == 0 && experiment > 0 {
                    Thread.sleep(forTimeInterval: TimeInterval(gData.repeatTime))
                }
                if useNew {
                    nmrResult = nmr.experiment(nParams)
                } else {
                    nmrResult = nmr.experiment(params)
                }
                if nmrResult.count == 0 {
                        
                } else {
                    let dataReturn = dataAquirer(xData,nmrResult)
                    yRealdata = dataReturn.1
                    yImagdata = dataReturn.2
                    xFTdata = dataReturn.3
                    yFTdata = dataReturn.4
                    xFitdata = dataReturn.5
                    yFitdata = dataReturn.6
                    if scan == 1 {
                        fitsReturned.append([dataReturn.7, dataReturn.8, dataReturn.9])
                        frequencyMeasured.append(dataReturn.7)
                        frequencyScan.append(Double(nParams.ncoFreq!))
                    } else {
                        fitsReturned[experiment - 1] = [dataReturn.7, dataReturn.8, dataReturn.9]
                        frequencyMeasured[experiment - 1] = dataReturn.7
                    }
                    DispatchQueue.main.async {
                        viewControl.viewName = .results
                        scan += 1
                        callExperiment()
                    }
                }
            }
        } else {
            scan = 1
            experiment += 1
            callExperiment()
        }
    }
    
    //nParams.hostName = "10.42.0.1"
    nParams.hostName = "moonpi.dyndns.org"
    //nParams.portNo = 1001
    //nParams.ncoFreq = 16004000
    //nParams.exptSelect = "FID"
    params.defaults()
    params.hostName = "moonpi.dyndns.org"
    params.hostName = "10.42.0.1"
    
    for ix in 0..<gData.experiments.count {
        if  gData.experiment == gData.experiments[ix] {
            params.exptName = gData.exptNames[ix]
            break
        }
    }
    callExperiment()
*/
}
