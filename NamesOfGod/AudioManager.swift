//
//  AudioManager.swift
//  NamesOfGod
//
//  Created by Andre Diamand on 2024
//  Copyright © 2018-2024 Andre Diamand. All rights reserved.
//

import Foundation
import AVFoundation

class AudioManager: NSObject, ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    
    override init() {
        super.init()
    }
    
    func playAudio(for nameNumber: Int) {
        guard let url = Bundle.main.url(forResource: "name\(nameNumber)", withExtension: "mp3") else {
            print("Arquivo de áudio não encontrado: name\(nameNumber).mp3")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Erro ao tocar áudio: \(error)")
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func isPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Áudio terminou de tocar
        print("Áudio terminou de tocar")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Erro de decodificação de áudio: \(error)")
        }
    }
}
