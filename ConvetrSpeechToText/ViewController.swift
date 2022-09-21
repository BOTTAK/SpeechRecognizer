import UIKit
import Speech
import AVKit

class ViewController: UIViewController {
    
    //------------------------------------------------------------------------------
    // MARK:-
    // MARK:- Outlets
    //------------------------------------------------------------------------------
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var speechLbl: UILabel!
    @IBOutlet weak var speechBtn: UIButton!
    
    //------------------------------------------------------------------------------
    // MARK:-
    // MARK:- Variables
    //------------------------------------------------------------------------------
    
    /* Настраиваемый параметр, который можно задать под нужную локацию*/
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru_RU"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEndine = AVAudioEngine()
    
    //------------------------------------------------------------------------------
    // MARK:-
    // MARK:- View Life Cycle Methods
    //------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSpeech()
        self.setupUI()
    }
    
    
    //------------------------------------------------------------------------------
    // MARK:-
    // MARK:- Action Methods
    //------------------------------------------------------------------------------
    @IBAction func speechBtnToText(_ sender: UIButton) {
        if audioEndine.isRunning {
            self.audioEndine.stop()
            self.recognitionRequest?.endAudio()
            self.speechBtn.isEnabled = false
            self.speechBtn.setTitle("Начать преобразование", for: .normal)
            self.speechBtn.setTitleColor(UIColor.white, for: .selected)
        } else {
            self.startRecording()
            self.speechBtn.setTitle("Остановить преобразование", for: .normal)
            self.speechBtn.setTitleColor(UIColor.white, for: .disabled)
        }
    }
    //------------------------------------------------------------------------------
    // MARK:-
    // MARK:- Custom Methods
    //------------------------------------------------------------------------------
    func setupUI() {
        self.titleLbl.textAlignment = .center
        self.titleLbl.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        self.titleLbl.numberOfLines = 0
        self.titleLbl.textColor = UIColor(named: "MainColor")
        self.titleLbl.text = "Преобразование речи в текст"
        
        self.speechLbl.textAlignment = .left
        self.speechLbl.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        self.speechLbl.numberOfLines = 0
        self.speechLbl.textColor = UIColor(named: "MainColor")
        self.speechLbl.text = "Говорите, не стесняйтесь... )"
        
        self.speechBtn.setTitle("Начать преобразование", for: .normal)
        self.speechBtn.setTitleColor(UIColor.white, for: .normal)
        self.speechBtn.setTitleColor(UIColor.white, for: .highlighted)
        self.speechBtn.backgroundColor = UIColor(named: "MainColor")
        self.speechBtn.layer.cornerRadius = 20
        self.speechBtn.layer.shadowOpacity = 2
        self.speechBtn.layer.shadowOffset = .zero
        self.speechBtn.layer.shadowColor = UIColor.black.cgColor
        self.speechBtn.layer.shadowRadius = 2
    }
    
    func setupSpeech() {
        self.speechBtn.isEnabled = false
        self.speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization( { authStatus in
            var isButtonEnabled = false
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
            case .denied:
                isButtonEnabled = false
                print("Пользователь не предоставил доступ к распознаванию речи")
            case .notDetermined:
                isButtonEnabled = false
                print("Доступ к распознаванию речи не получен")
            case .restricted:
                isButtonEnabled = false
                print("Устройство не поддерживается")
            @unknown default:
                fatalError()
            }
            OperationQueue.main.addOperation() {
                self.speechBtn.isEnabled = isButtonEnabled
            }
        })
    }
    
    func startRecording() {
        /* Очищаем все прежние сессии, если таковые имеются */
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        /* Созданием коснтанту аудиосессии для записи голоса */
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record, mode: AVAudioSession.Mode.measurement, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Константа для audioSettion не установлено из-за ошибки")
        }
        
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputMode = audioEndine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Невозможно создать объект для SFSpeechAudioBufferRecognitionRequest")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { result, error in
            var isFinal = true
            if result != nil {
                self.speechLbl.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            if error != nil || isFinal {
                self.audioEndine.stop()
                inputMode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.speechBtn.isEnabled = true
            }
        })
        
        let recordingFormat = inputMode.outputFormat(forBus: 0)
        inputMode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat, block: { buffer, when in
            self.recognitionRequest?.append(buffer)
        })
        
        self.audioEndine.prepare()
        
        do {
            try self.audioEndine.start()
        } catch {
            print("audioEndine не смог начать работу из-за ошибки")
        }
        
        self.speechLbl.text = "Говорите, не стесняйтесь... )"
    }
}

extension ViewController: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.speechBtn.isEnabled = true
        } else {
            self.speechBtn.isEnabled = false
        }
    }
}
