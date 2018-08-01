//
//  ViewController.swift
//  NAVER Clova Speech Synthesis
//
//  Created by 이광용 on 2018. 8. 1..
//  Copyright © 2018년 이광용. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire

//http://docs.ncloud.com/ko/naveropenapi_v2/naveropenapi-4-2.html
//https://docs.swift.org/swift-book/LanguageGuide/Enumerations.html
//https://developer.apple.com/documentation/uikit/uipickerview
//https://developer.apple.com/documentation/uikit/uislider

enum Gender: Int, EnumCollection {
    case male, female
    var description: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        }
    }
}
enum Language: Int, EnumCollection {
    var description: String {
        switch self {
        case .korean:
            return "한국어"
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        case .chinese:
            return "中文"
        case .spanish:
            return "Español"
        }
    }
    
    case korean, english, japanese, chinese, spanish
    
    func speaker(gender: Gender) -> String {
        switch self {
        case .korean:
            return gender == .male ? "jinho" : "mijin"
        case .english:
            return gender == .male ? "matt" : "clara"
        case .japanese:
            return gender == .male ? "shinji" : "yuri"
        case .chinese:
            return gender == .male ? "liangliang" : "meimei"
        case .spanish:
            return gender == .male ? "jose" : "carmen"
        }
    }
}

class ViewController: UIViewController {
    var audio: AVAudioPlayer?
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var ttsButton: UIButton!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var slider: UISlider!
    
    let languages: [Language] = Language.allCases
    let genders: [Gender] = Gender.allCases
    var language: Language = .korean
    var gender: Gender = .female
    var speed = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.picker.dataSource = self
        self.picker.delegate = self
        self.slider.minimumValue = -5
        self.slider.maximumValue = 5
        self.slider.value = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.picker.selectRow(self.language.rawValue, inComponent: 0, animated: true)
        self.picker.selectRow(self.gender.rawValue, inComponent: 1, animated: true)
    }
    
    @IBAction func touchUpTTSButton(_ sender: UIButton) {
        guard let text =  self.textView.text else {return}
        requestTTS(language: self.language, gender: self.gender, speed: self.speed, text: text)
    }
    
    //음성 재생 속도. -5 에서 5 사이의 정수 값이며, -5 이면 0.5 배 빠른 속도이고 5 이면 0.5 배 느린 속도입니다. 0 이면 정상 속도의 목소리로 음성을 합성합니다.
    @IBAction func valueChanged(_ sender: UISlider) {
        self.speed = Int(sender.value)
    }
    
    func requestTTS(language: Language, gender: Gender, speed: Int, text: String) {
        let header = [ "X-NCP-APIGW-API-KEY-ID": "[Client ID]",
                       "X-NCP-APIGW-API-KEY": "[Client Secret]"]
        
        let parameter: [String: Any] = ["speaker": language.speaker(gender: gender),
                                        "speed": 0,
                                        "text": text]
        
        Alamofire.request("https://naveropenapi.apigw.ntruss.com/voice/v1/tts",
                          method: HTTPMethod.post,
                          parameters: parameter,
            headers: header).responseData { (response) in
                switch response.result {
                case .success :
                    guard let statusCode = response.response?.statusCode as Int? else {return}
                    switch statusCode {
                    case 200..<400 :
                        guard let data = response.data else {return}
                        self.play(data: data)
                    default :
                        print(statusCode)
                    }
                case .failure(let error) :
                    print(error.localizedDescription)
                }
        }
    }
    
    func play(data: Data) {
        do {
            audio = try AVAudioPlayer(data: data)
            audio?.prepareToPlay()
            audio?.play()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func saveAudio(data: Data) {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("voice.mp3")
        
        do {
            try data.write(to: fileURL, options: .atomic)
        }
        catch {
            print(error.localizedDescription)
        }
    }
}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource  {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return languages.count
        case 1:
            return genders.count
        default:
            return 0
        }
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            return languages[row].description
        case 1:
            return genders[row].description
        default:
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            self.language = self.languages[row]
        case 1:
            self.gender = self.genders[row]
        default:
            break
        }
    }
}
