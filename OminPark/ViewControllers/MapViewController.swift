//
//  MapViewController.swift
//  OminPark
//
//  Created by Emanuel  Guerrero on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import UIKit
import GoogleMaps
import AVFoundation
import Speech
import Motion

final class MapViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet private weak var mapView: GMSMapView!
    @IBOutlet private weak var micButton: CircleButton!
    @IBOutlet private weak var arButton: CircleButton!
    @IBOutlet private weak var appleMapButton: CircleButton!
    @IBOutlet private weak var googleMapButton: CircleButton!
    
    
    // MARK: - Private Instance Attributes
    private var audioEngine: AVAudioEngine!
    private var speechSynthesizer: AVSpeechSynthesizer!
    private var voice: AVSpeechSynthesisVoice!
    private var speechRecognizer: SFSpeechRecognizer?
    private var speechRecognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest!
    private var supportedCommands: [String] = [
        "find parking spaces",
        "find parking near me",
        "give me directions to it",
        "yes, give me directions to it"
    ]
    private var mapMarkers: [GMSMarker] = []
    private let reserveParkingText = "I have found a peer to peer parking spot. Do you want directions?"
    private let unrecognizedSpeechText = "I couldn't understand. Repeat that again?"
    private let directionsSet = "Here are your directions"
    // Starting location Caesars Palace
    private let startingLocationCoordinate = CLLocationCoordinate2D(latitude: 36.1161858,
                                                                    longitude: -115.1745420)
    private let cameraCoordinate = CLLocationCoordinate2D(latitude: 36.121712, longitude: -115.171141)
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mapMarkers = ParkingSpotManager.shared.parkingSpotMarkers(for: mapView)
        requestSpeechAuthorization()
    }
}


// MARK: - IBActions
private extension MapViewController {
    @IBAction func micButtonTapped() {
        promptForParkingHelp()
    }
}


// MARK: - AVSpeechSynthesizerDelegate
extension MapViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if utterance.speechString.contains(reserveParkingText) ||
           utterance.speechString.contains(unrecognizedSpeechText) {
            beginSpeechRecognition()
        }
    }
}


// MARK: - Private Instance Methods
private extension MapViewController {
    func setup() {
        let camera = GMSCameraPosition.camera(withTarget: cameraCoordinate, zoom: 17.0)
        mapView.camera = camera
        mapView.settings.indoorPicker = false
        let startingLocationMarker = GMSMarker(position: startingLocationCoordinate)
        startingLocationMarker.appearAnimation = .pop
        startingLocationMarker.icon = #imageLiteral(resourceName: "current-user-pin")
        startingLocationMarker.map = mapView
        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer.delegate = self
        voice = AVSpeechSynthesisVoice(identifier: "en-US")
        audioEngine = AVAudioEngine()
        speechRecognizer = SFSpeechRecognizer()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord,
                                                        with: .defaultToSpeaker)
        } catch {
            print("Error setting volume for speech synthesizer")
            print(error)
        }
    }
}


// MARK: - Private Instance Methods For Speech Recognition
private extension MapViewController {
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { (status) in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.micButton.isEnabled = true
                case .denied, .notDetermined, .restricted:
                    self.micButton.isEnabled = false
                }
            }
        }
    }
    
    func promptForParkingHelp() {
        guard speechRecognitionTask == nil else { return }
        guard let recognizer = speechRecognizer else { return }
        if !recognizer.isAvailable { return }
        AudioServicesPlaySystemSound(1113)
        micButton.animate(.background(color: .red))
        beginSpeechRecognition()
    }
    
    func beginSpeechRecognition() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.recognitionRequest.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Error starting speech recognition")
            print(error)
            return
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        speechRecognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { (result, error) in
            guard error == nil else {
                print(error!)
                self.stopSpeechRecognition()
                return
            }
            guard let speechResult = result else { return }
            let bestString = speechResult.bestTranscription.formattedString
            self.validateSpeech(bestString)
        }
    }
    
    func stopSpeechRecognition() {
        audioEngine.stop()
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        speechRecognitionTask?.cancel()
        speechRecognitionTask = nil
    }
    
    func validateSpeech(_ speech: String) {
        guard let validCommand = supportedCommands.first(where: { $0.contains(speech.lowercased()) }) else {
            stopSpeechRecognition()
            let utterance = AVSpeechUtterance(string: unrecognizedSpeechText)
            utterance.voice = voice
            speechSynthesizer.speak(utterance)
            return
        }
        stopSpeechRecognition()
        if validCommand.contains("find") {
            let peerMarker = mapMarkers[1]
            ParkingSpotManager.shared.directionsToMarker(peerMarker, starting: startingLocationCoordinate) { (polyline, error) in
                guard error == nil else {
                    print(error!)
                    return
                }
                guard polyline != nil else {
                    return
                }
                polyline?.map = self.mapView
                let otherMarkers = self.mapMarkers.filter({ $0.position.latitude != peerMarker.position.latitude && $0.position.longitude != peerMarker.position.longitude })
                otherMarkers.forEach {
                    $0.map = nil
                }
                let zoomOut = GMSCameraUpdate.zoom(to: 15.0)
                self.mapView.animate(with: zoomOut)
                let utterance = AVSpeechUtterance(string: self.reserveParkingText)
                utterance.voice = self.voice
                self.speechSynthesizer.speak(utterance)
            }
        } else if validCommand.contains("give") {
            arButton.animate(.position(CGPoint(x: 30, y: arButton.frame.center.y)),
                             .spring(stiffness: 40, damping: 5),
                             .duration(0.01),
                             .fadeIn)
            appleMapButton.animate(.delay(0.03),
                                   .position(CGPoint(x: 30, y: appleMapButton.frame.center.y)),
                                   .spring(stiffness: 40, damping: 5),
                                   .duration(0.01),
                                   .fadeIn)
            googleMapButton.animate(.delay(0.06),
                                    .position(CGPoint(x: 30, y: googleMapButton.frame.center.y)),
                                    .spring(stiffness: 40, damping: 5),
                                    .duration(0.01),
                                    .fadeIn)
            let utterance = AVSpeechUtterance(string: directionsSet)
            utterance.voice = voice
            speechSynthesizer.speak(utterance)
            micButton.animate(.background(color: #colorLiteral(red: 0.9490196078, green: 0.7921568627, blue: 0.09019607843, alpha: 1)))
        }
    }
}
