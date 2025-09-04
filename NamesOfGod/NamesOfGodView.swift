//
//  NamesOfGodView.swift
//  NamesOfGod
//
//  Created by Andre Diamand on 2024
//  Copyright © 2018-2024 Andre Diamand. All rights reserved.
//

import SwiftUI
import AVFoundation
import StoreKit

class NamesOfGodViewModel: NSObject, ObservableObject {
    @Published var currentIndex = 0
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var speed: Double = 1.0
    @Published var showControls = false
    @Published var isFirstTime = true // Para controlar contagem regressiva
    @Published var isLoopEnabled = false // Para loop infinito
    @Published var isNavigatingManually = false // Para controlar navegação manual
    @Published var showDetailedInfo = false
    @Published var showInfo = false
    @Published var showCounterFlash = false // Para flash visual no contador
    @Published var hasRequestedReview = false // Para controlar se já pediu review
    @Published var hasCompletedFirstMeditation = false // Primeira meditação completa
    @Published var hasUsedAudioFeature = false // Usou funcionalidade de áudio
    @Published var hasViewedDetailedInfo = false // Viu informações detalhadas
    @Published var hasUsedPrintFeature = false // Usou funcionalidade de impressão
    @Published var firstLaunchDate = Date() // Data do primeiro uso
    
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var isHoldingLeft = false // Para controle de pressionar e segurar esquerda
    private var isHoldingRight = false // Para controle de pressionar e segurar direita
    private var lastTapTime: Date = Date.distantPast // Para debounce de toques
    private let tapDebounceInterval: TimeInterval = 0.15 // Intervalo mínimo entre toques
    private var leftNavigationWorkItem: DispatchWorkItem? // Para cancelar navegação esquerda
    private var rightNavigationWorkItem: DispatchWorkItem? // Para cancelar navegação direita

    
    // Estrutura para as informações dos nomes
    struct NameInfo {
        let number: Int
        let transliteration: String
        let meaning: String
        let hebrew: String
        let associatedPsalm: String
        let psalmText: String
        let keyword: String
        let practicalApplication: String
        let astrologicalCorrespondence: String
        let archangel: String
        let meditationPractice: String
        let reflectiveQuestion: String
    }
    
    // Array dos nomes (72 nomes de Deus, usando os novos imagesets)
    let namesOfGod = [
        "והו", "ילי", "סיט", "עלמ", "מהש", "ללה", "אכא", "כהת", "הזי", "אלד",
        "לאו", "ההע", "יזל", "מבה", "הרי", "הקמ", "לאו", "כלי", "לוו", "פהל",
        "נלכ", "ייי", "מלה", "חהו", "נתה", "האא", "ירת", "שאה", "ריי", "אומ",
        "לכב", "ושר", "יחו", "להח", "כוק", "מנד", "אני", "חעמ", "רהע", "ייז",
        "ההה", "מיכ", "וול", "ילה", "סאל", "ערי", "עשל", "מיה", "והו", "דני",
        "החש", "עממ", "ננא", "נית", "מבה", "פוי", "נממ", "ייל", "הרח", "מצר",
        "ומב", "יהה", "ענו", "מחי", "דמב", "מנק", "איע", "חבו", "ראה", "יבמ",
        "היי", "מומ"
    ]
    
    // Array com as informações dos nomes
    var namesInfo: [NameInfo] = []
    
    override init() {
        super.init()
        loadNamesInfo()
        registerCustomFont()
        // App inicia pausada no primeiro nome de Deus
        currentIndex = 0
        isPlaying = false
        isPaused = true
        showControls = true
        isFirstTime = false
        
        // Verificar oportunidades de review periodicamente
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.checkForReviewOpportunity()
        }
    }
    
    private func registerCustomFont() {
        guard let fontURL = Bundle.main.url(forResource: "Stam Ashkenaz CLM Medium", withExtension: "ttf") else {
            print("❌ Fonte não encontrada no bundle")
            return
        }
        
        guard let fontDataProvider = CGDataProvider(url: fontURL as CFURL) else {
            print("❌ Não foi possível criar o data provider da fonte")
            return
        }
        
        guard let font = CGFont(fontDataProvider) else {
            print("❌ Não foi possível criar a fonte")
            return
        }
        
        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterGraphicsFont(font, &error) {
            print("✅ Fonte registrada com sucesso: Stam Ashkenaz CLM Medium")
        } else {
            if let error = error?.takeRetainedValue() {
                print("❌ Erro ao registrar fonte: \(error)")
            } else {
                print("❌ Erro ao registrar fonte: Erro desconhecido")
            }
        }
    }
    
    private func getHebrewFont(size: CGFloat) -> UIFont {
        // Listar todas as fontes disponíveis para debug
        print("🔍 Fontes disponíveis:")
        UIFont.familyNames.sorted().forEach { family in
            let names = UIFont.fontNames(forFamilyName: family)
            if names.contains("Stam") || family.contains("Stam") || family.contains("Ashkenaz") || family.contains("Hebrew") {
                print("   Família: \(family)")
                names.forEach { name in
                    print("     - \(name)")
                }
            }
        }
        
        // Tentar usar a fonte customizada
        if let customFont = UIFont(name: "Stam Ashkenaz CLM Medium", size: size) {
            print("✅ Usando fonte customizada: Stam Ashkenaz CLM Medium")
            return customFont
        }
        
        // Tentar com variações do nome
        let possibleNames = [
            "Stam Ashkenaz CLM Medium",
            "StamAshkenazCLM-Medium",
            "StamAshkenazCLM",
            "StamAshkenaz",
            "Stam Ashkenaz CLM Medium.ttf"
        ]
        
        for name in possibleNames {
            if let customFont = UIFont(name: name, size: size) {
                print("✅ Usando fonte customizada: \(name)")
                return customFont
            }
        }
        
        // Fallback para fonte do sistema
        print("⚠️ Usando fonte do sistema como fallback")
        return UIFont.systemFont(ofSize: size)
    }
    
    func renderHebrewText(_ hebrewText: String, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Fundo transparente
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Configurar a fonte hebraica customizada
            let font = getHebrewFont(size: size.width * 0.35)
            
            // Configurar o texto com cor que se adapta ao dark/light mode
            let textColor: UIColor = {
                if #available(iOS 13.0, *) {
                    return UIColor.label
                } else {
                    return UIColor.black
                }
            }()
            
            // Configuração específica para RTL
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.baseWritingDirection = .rightToLeft
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            // Usar NSAttributedString para melhor controle RTL
            let attributedString = NSAttributedString(string: hebrewText, attributes: textAttributes)
            
            // Calcular posição central
            let textSize = attributedString.size()
            let x = (size.width - textSize.width) / 2
            let y = (size.height - textSize.height) / 2
            
            // Desenhar o texto hebraico com configuração RTL
            attributedString.draw(in: CGRect(x: x, y: y, width: textSize.width, height: textSize.height))
        }
        
        return image
    }
    
    func verifyFiles() {
        // Verificação de imagens removida - agora usa fonte
        // print("📁 Verificando imagens...")
        // for (index, imageName) in namesOfGod.enumerated() {
        //     if UIImage(named: imageName) != nil {
        //         print("✅ \(index): \(imageName) - OK")
        //     } else {
        //         print("❌ \(index): \(imageName) - NÃO ENCONTRADO")
        //     }
        // }
        
        print("🔊 Verificando áudios...")
        for i in 1...72 {
            let audioName = "name\(i)"
            if let _ = Bundle.main.url(forResource: audioName, withExtension: "mp3") {
                print("✅ \(audioName).mp3 - OK")
            } else {
                print("❌ \(audioName).mp3 - NÃO ENCONTRADO")
            }
        }
    }
    
    // Função auxiliar para fazer parsing CSV RFC-4180
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var i = 0
        
        while i < line.count {
            let char = line[line.index(line.startIndex, offsetBy: i)]
            
            if char == "\"" {
                if insideQuotes {
                    // Verificar se é uma aspa dupla escapada
                    if i + 1 < line.count && line[line.index(line.startIndex, offsetBy: i + 1)] == "\"" {
                        currentField += "\""
                        i += 1 // Pular a próxima aspa
                    } else {
                        // Fim do campo entre aspas
                        insideQuotes = false
                    }
                } else {
                    // Início do campo entre aspas
                    insideQuotes = true
                }
            } else if char == "," && !insideQuotes {
                // Separador de campo (fora de aspas)
                fields.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                // Caractere normal do campo
                currentField += String(char)
            }
            
            i += 1
        }
        
        // Adicionar o último campo
        fields.append(currentField.trimmingCharacters(in: .whitespaces))
        
        return fields
    }
    
    func loadNamesInfo() {
        guard let csvPath = Bundle.main.path(forResource: "72_names_kabbalah", ofType: "csv") else {
            print("❌ Arquivo CSV não encontrado")
            return
        }
        
        do {
            let csvContent = try String(contentsOfFile: csvPath, encoding: .utf8)
            let lines = csvContent.components(separatedBy: .newlines)
            
            // Pular o cabeçalho
            for line in lines.dropFirst() where !line.isEmpty {
                let components = parseCSVLine(line)
                if components.count >= 12 {
                    // Nova ordem das colunas RFC4180
                    let number = Int(components[0].trimmingCharacters(in: .whitespaces)) ?? 0
                    let hebrew = components[1].trimmingCharacters(in: .whitespaces)
                    let transliteration = components[2].trimmingCharacters(in: .whitespaces)
                    let astrologicalCorrespondence = components[3].trimmingCharacters(in: .whitespaces)
                    let archangel = components[4].trimmingCharacters(in: .whitespaces)
                    let keyword = components[5].trimmingCharacters(in: .whitespaces)
                    let meaning = components[6].trimmingCharacters(in: .whitespaces)
                    let practicalApplication = components[7].trimmingCharacters(in: .whitespaces)
                    let reflectiveQuestion = components[8].trimmingCharacters(in: .whitespaces)
                    let meditationPractice = components[9].trimmingCharacters(in: .whitespaces)
                    let associatedPsalm = components[10].trimmingCharacters(in: .whitespaces)
                    let psalmText = components[11].trimmingCharacters(in: .whitespaces)
                    
                    namesInfo.append(NameInfo(
                        number: number,
                        transliteration: transliteration,
                        meaning: meaning,
                        hebrew: hebrew,
                        associatedPsalm: associatedPsalm,
                        psalmText: psalmText,
                        keyword: keyword,
                        practicalApplication: practicalApplication,
                        astrologicalCorrespondence: astrologicalCorrespondence,
                        archangel: archangel,
                        meditationPractice: meditationPractice,
                        reflectiveQuestion: reflectiveQuestion
                    ))
                }
            }
            
            print("✅ Carregados \(namesInfo.count) nomes com informações detalhadas usando parser RFC-4180")
            print("🔍 Primeiros 5 nomes: \(namesInfo.prefix(5).map { "\($0.number): \($0.transliteration)" })")
        } catch {
            print("❌ Erro ao carregar CSV: \(error)")
        }
    }
    
    // Função para obter informações do nome atual
    func currentNameInfo() -> NameInfo? {
        guard currentIndex >= 0 else { 
            print("🔍 currentIndex \(currentIndex) < 0, retornando nil")
            return nil 
        }
        
        // Agora o índice 0 = nome 1, índice 1 = nome 2, etc.
        let nameNumber = currentIndex + 1
        print("🔍 Buscando informações para nome \(nameNumber), currentIndex: \(currentIndex)")
        
        // Buscar o nome correspondente
        let foundName = namesInfo.first { $0.number == nameNumber }
        if let found = foundName {
            print("✅ Nome encontrado: \(found.transliteration)")
        } else {
            print("❌ Nome não encontrado para número \(nameNumber)")
            print("🔍 Nomes disponíveis: \(namesInfo.prefix(10).map { $0.number })")
        }
        return foundName
    }
    
    // Função para imprimir os 72 nomes
    func print72Names() {
        print("🖨️ Iniciando impressão dos 72 nomes...")
        
        // Carregar a imagem 72names.jpg
        guard let image = UIImage(named: "72names") else {
            print("❌ Erro: Imagem 72names não encontrada")
            return
        }
        
        // Configurar o print controller
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .photo
        printInfo.jobName = "72 Names of God"
        printController.printInfo = printInfo
        
        // Configurar para modo landscape
        printInfo.orientation = .landscape
        
        // Imprimir a imagem diretamente
        printController.printingItem = image
        
        // Apresentar a interface de impressão
        printController.present(animated: true) { controller, completed, error in
            if completed {
                print("✅ Impressão concluída com sucesso!")
                // Marcar uso da funcionalidade de impressão
                self.hasUsedPrintFeature = true
                self.checkForReviewOpportunity()
            } else if let error = error {
                print("❌ Erro na impressão: \(error.localizedDescription)")
            } else {
                print("❌ Impressão cancelada pelo usuário")
            }
        }
    }
    

    
    func startTimer() {
        // Verificar se já está no último nome antes de iniciar o timer
        if currentIndex >= namesOfGod.count - 1 {
            print("🛑 Tentativa de iniciar timer mas já está no último nome")
            isPlaying = false
            isPaused = true
            showControls = true
            return
        }
        
        timer?.invalidate()
        let interval = 1.0 / speed
        print("⏰ Iniciando timer com intervalo: \(interval)s")
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.nextName()
        }
    }
    
    func nextName() {
        print("🔍 nextName() chamado - currentIndex: \(currentIndex), total: \(namesOfGod.count)")
        
        if currentIndex < namesOfGod.count - 1 {
            currentIndex += 1
            print("✅ Avançou para índice: \(currentIndex) (nome \(currentIndex + 1))")
            
            // Se chegou ao último nome (índice 71 = nome 72)
            if currentIndex == namesOfGod.count - 1 {
                print("🎯 Chegou ao último nome (72)")
                
                // Marcar primeira meditação completa
                hasCompletedFirstMeditation = true
                checkForReviewOpportunity()
                
                if isLoopEnabled {
                    print("🔄 Loop ativado - aguardando para restart")
                    // Se loop está ativado, aguardar um ciclo antes de restart
                    DispatchQueue.main.asyncAfter(deadline: .now() + (1.0 / speed)) {
                        // Efeito sutil de fade antes de recomeçar
                        withAnimation(.easeInOut(duration: 0.3)) {
                            // Pequeno fade out/in para indicar recomeço
                        }
                        self.showCounterFlash = true // Ativar flash do contador
                        self.restart()
                        
                        // Desativar flash após 0.5 segundos
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.showCounterFlash = false
                        }
                    }
                } else {
                    print("⏸️ Loop desativado - pausando automaticamente")
                    // Se loop está desativado, dar tempo para visualizar o último nome
                    // antes de pausar automaticamente
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 1 segundo de visualização
                        self.isPlaying = false
                        self.isPaused = true
                        self.showControls = true
                        self.timer?.invalidate()
                    }
                }
            }
        } else {
            print("⚠️ Tentativa de avançar além do último nome - currentIndex: \(currentIndex)")
        }
    }
    
    func pause() {
        isPaused = true
        timer?.invalidate()
        showControls = true
        isNavigatingManually = false // Reset navegação manual
    }
    
    func resume() {
        // Verificar se pode continuar antes de resumir
        if currentIndex >= namesOfGod.count - 1 {
            print("🛑 Tentativa de resumir mas já está no último nome")
            isPlaying = false
            isPaused = true
            showControls = true
            return
        }
        
        isPaused = false
        showControls = false
        isNavigatingManually = false
        stopContinuousNavigation() // Parar navegação contínua quando sair do modo pausado
        
        // Só iniciar timer se não estiver no último nome
        if currentIndex < namesOfGod.count - 1 {
            startTimer()
        }
    }
    
    func restart() {
        // Sempre começar do primeiro nome (sem contagem regressiva)
        currentIndex = 0
        
        isPlaying = true
        isPaused = false
        showControls = false
        isFirstTime = false
        isNavigatingManually = false
        stopContinuousNavigation() // Parar navegação contínua quando sair do modo pausado
        

        
        // Ativar flash do contador para indicar reinício
        showCounterFlash = true
        
        // SEMPRE iniciar timer - botão reiniciar deve entrar no modo automático
        startTimer()
        
        // Desativar flash após 0.5 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showCounterFlash = false
        }
    }
    
    // Função para toque no nome (continua ou recomeça)
    func tapOnName() {
        if isPaused {
            // Se está pausado no meio, continuar
            if currentIndex == namesOfGod.count - 1 {
                // Se está pausado no último nome, recomeçar do início
                restart()
            } else {
                // Se está pausado no meio, continuar normalmente
                resume()
            }
        } else if currentIndex == namesOfGod.count - 1 {
            // Se está rodando no último nome, pausar (não reiniciar)
            pause()
        } else {
            // Se está rodando no meio, pausar
            pause()
        }
    }
    
    func playAudio() {
        // Agora o índice 0 = nome 1, índice 1 = nome 2, etc.
        let nameNumber = currentIndex + 1
        guard let url = Bundle.main.url(forResource: "name\(nameNumber)", withExtension: "mp3") else {
            print("Arquivo de áudio não encontrado: name\(nameNumber).mp3")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            // Marcar uso da funcionalidade de áudio
            hasUsedAudioFeature = true
            checkForReviewOpportunity()
        } catch {
            print("Erro ao tocar áudio: \(error)")
        }
    }
    
    func changeSpeed(_ newSpeed: Double) {
        speed = newSpeed
        if isPlaying && !isPaused {
            startTimer()
        }
    }
    
    // MARK: - Request Review
    
    func requestReviewIfAppropriate() {
        // Só pedir review se ainda não pediu
        guard !hasRequestedReview else { return }
        
        // Usar o método recomendado da Apple
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
            hasRequestedReview = true
            print("⭐ Review solicitado!")
        }
    }
    
    func checkForReviewOpportunity() {
        // Verificar múltiplos triggers para review
        
        // Trigger 1: Primeira meditação completa
        if hasCompletedFirstMeditation && !hasRequestedReview {
            print("🎯 Trigger 1: Primeira meditação completa")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestReviewIfAppropriate()
            }
            return
        }
        
        // Trigger 2: Usou funcionalidade de áudio
        if hasUsedAudioFeature && !hasRequestedReview {
            print("🎯 Trigger 2: Usou funcionalidade de áudio")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestReviewIfAppropriate()
            }
            return
        }
        
        // Trigger 3: Viu informações detalhadas
        if hasViewedDetailedInfo && !hasRequestedReview {
            print("🎯 Trigger 3: Viu informações detalhadas")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestReviewIfAppropriate()
            }
            return
        }
        
        // Trigger 4: Usou funcionalidade de impressão
        if hasUsedPrintFeature && !hasRequestedReview {
            print("🎯 Trigger 4: Usou funcionalidade de impressão")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestReviewIfAppropriate()
            }
            return
        }
        
        // Trigger 5: Tempo de uso (3 dias)
        let daysSinceFirstUse = Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
        if daysSinceFirstUse >= 3 && !hasRequestedReview {
            print("🎯 Trigger 5: 3 dias de uso")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestReviewIfAppropriate()
            }
            return
        }
    }
    
    // MARK: - Navegação Manual
    
    func navigateLeft() {
        // Debounce para evitar múltiplos toques
        let now = Date()
        guard now.timeIntervalSince(lastTapTime) >= tapDebounceInterval else { return }
        lastTapTime = now
        
        // Loop circular: se estiver no primeiro nome (índice 0), vai para o último (índice 71)
        if currentIndex <= 0 {
            currentIndex = namesOfGod.count - 1 // Vai para o último nome (72)
        } else {
            currentIndex -= 1
        }
        isNavigatingManually = true
        print("🔍 Navegando para esquerda: índice \(currentIndex) (nome \(currentIndex + 1))")
    }
    
    func navigateRight() {
        // Debounce para evitar múltiplos toques
        let now = Date()
        guard now.timeIntervalSince(lastTapTime) >= tapDebounceInterval else { return }
        lastTapTime = now
        
        // Loop circular: se estiver no último nome (índice 71), vai para o primeiro (índice 0)
        if currentIndex >= namesOfGod.count - 1 {
            currentIndex = 0 // Vai para o primeiro nome (1)
        } else {
            currentIndex += 1
        }
        isNavigatingManually = true
        print("🔍 Navegando para direita: índice \(currentIndex) (nome \(currentIndex + 1))")
    }
    
    // MARK: - Navegação Sequencial ao Pressionar
    
    func startSequentialNavigation(direction: NavigationDirection) {
        switch direction {
        case .left:
            isHoldingLeft = true
        case .right:
            isHoldingRight = true
        }
        
        // Navegação sequencial automática (um a um)
        scheduleNextSequentialNavigation(direction: direction)
        print("🚀 Navegação sequencial iniciada: \(direction)")
    }
    
    private func scheduleNextSequentialNavigation(direction: NavigationDirection) {
        guard (isHoldingLeft && direction == .left) || (isHoldingRight && direction == .right) else { return }
        
        // Cancelar navegação anterior se existir
        if direction == .left {
            leftNavigationWorkItem?.cancel()
        } else {
            rightNavigationWorkItem?.cancel()
        }
        
        // Criar novo work item
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            if direction == .left && self.isHoldingLeft {
                self.navigateLeft()
                self.scheduleNextSequentialNavigation(direction: .left)
            } else if direction == .right && self.isHoldingRight {
                self.navigateRight()
                self.scheduleNextSequentialNavigation(direction: .right)
            }
        }
        
        // Armazenar referência para poder cancelar
        if direction == .left {
            leftNavigationWorkItem = workItem
        } else {
            rightNavigationWorkItem = workItem
        }
        
        // Agendar navegação
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem) // VELOCIDADE AUMENTADA
    }
    
    func stopContinuousNavigation() {
        // Cancelar navegações agendadas imediatamente
        leftNavigationWorkItem?.cancel()
        rightNavigationWorkItem?.cancel()
        leftNavigationWorkItem = nil
        rightNavigationWorkItem = nil
        
        // Parar flags de controle
        isHoldingLeft = false
        isHoldingRight = false
        
        // Reset do debounce para permitir toque imediato após soltar
        lastTapTime = Date.distantPast
        
        print("🛑 Navegação contínua parada - work items cancelados")
    }
    
    enum NavigationDirection {
        case left, right
    }
}

extension NamesOfGodViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Áudio terminou de tocar
    }
}

// MARK: - Botão com Estilo Liquid Glass
struct LiquidGlassButton: View {
    let systemImage: String
    let isActive: Bool
    let size: CGFloat
    let continuousAnimation: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.37, weight: .medium)) // Proporcional ao tamanho
                .foregroundColor(isActive ? .white : .gray.opacity(0.7))
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: size * 0.27) // Proporcional ao tamanho
                        .fill(
                            LinearGradient(
                                colors: continuousAnimation ? 
                                    [Color.blue.opacity(0.9), Color.purple.opacity(0.8), Color.blue.opacity(0.9)] :
                                    (isActive ? 
                                        [Color.blue.opacity(0.8), Color.purple.opacity(0.6)] :
                                        [Color.gray.opacity(0.1), Color.gray.opacity(0.05)]
                                    ),
                                startPoint: continuousAnimation ? 
                                    UnitPoint(x: 0, y: 0) : 
                                    UnitPoint(x: 0, y: 0),
                                endPoint: continuousAnimation ? 
                                    UnitPoint(x: 1, y: 1) : 
                                    UnitPoint(x: 1, y: 1)
                            )
                        )
                        .modifier(ContinuousGradientAnimation(continuousAnimation: continuousAnimation))
                        .overlay(
                            RoundedRectangle(cornerRadius: size * 0.27) // Proporcional ao tamanho
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.primary.opacity(0.3), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
                .shadow(color: isActive ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Seta de Navegação com Estilo Liquid Glass
struct NavigationArrowButton: View {
    let direction: String
    let systemImage: String
    let action: () -> Void
    let onLongPress: (Bool) -> Void
    let isIPad: Bool
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: isIPad ? 42 : 26, weight: .semibold))
                .foregroundColor(.gray.opacity(0.7))
                .frame(width: isIPad ? 117 : 70, height: isIPad ? 117 : 70) // Botões maiores para iPad
                .background(
                    RoundedRectangle(cornerRadius: isIPad ? 21 : 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.primary.opacity(0.3), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
                .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 50) {
            // Ação ao soltar
        } onPressingChanged: { isPressing in
            onLongPress(isPressing)
        }
    }
}

struct NamesOfGodView: View {
    @ObservedObject var viewModel: NamesOfGodViewModel
    @State private var wasTimerActive = false
    @Environment(\.colorScheme) var colorScheme // Detecta mudanças no modo de cor
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background adaptativo para modo dark/light
                Color(uiColor: UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Respiro fixo do topo para estabilizar o layout
                    Spacer()
                        .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 18) // REDUZIDO PARA COMPENSAR O PADDING DO CONTAINER
                    
                    // Container superior - COM MESMO PADRÃO DO INFERIOR
                    if viewModel.isPaused {
                        VStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 21 : 16) { // MESMO ESPAÇAMENTO DO INFERIOR
                            // Controles de navegação e áudio
                            HStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 20) {
                                NavigationArrowButton(
                                    direction: "left",
                                    systemImage: "chevron.left",
                                    action: { viewModel.navigateLeft() },
                                    onLongPress: { isPressing in
                                        if isPressing {
                                            viewModel.startSequentialNavigation(direction: .left)
                                        } else {
                                            viewModel.stopContinuousNavigation()
                                        }
                                    },
                                    isIPad: false
                                )
                                
                                LiquidGlassButton(
                                    systemImage: "person.wave.2",
                                    isActive: false,
                                    size: UIDevice.current.userInterfaceIdiom == .pad ? 91 : 70,
                                    continuousAnimation: false
                                ) {
                                    viewModel.playAudio()
                                }
                                
                                NavigationArrowButton(
                                    direction: "right",
                                    systemImage: "chevron.right",
                                    action: { viewModel.navigateRight() },
                                    onLongPress: { isPressing in
                                        if isPressing {
                                            viewModel.startSequentialNavigation(direction: .right)
                                        } else {
                                            viewModel.stopContinuousNavigation()
                                        }
                                    },
                                    isIPad: false
                                )
                            }
                            
                            // Texto do nome - COM ESPAÇAMENTO ADEQUADO
                            if let nameInfo = viewModel.currentNameInfo() {
                                VStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 21 : 16) { // ESPAÇAMENTO GENEROSO COMO INFERIOR
                                    // Só a frase do significado - SEM TRANSLITERADO
                                    Text(nameInfo.meaning)
                                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 20, weight: .semibold, design: .default))
                                        .foregroundColor(.gray.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(3)
                                        .minimumScaleFactor(0.8)
                                        .frame(height: 45)
                                    
                                                                    // Botões de ação - COM ESPAÇAMENTO ADEQUADO (incluindo número)
                                HStack(spacing: 12) { // ESPAÇAMENTO REDUZIDO PARA ACOMODAR O NÚMERO
                                    // Botão + para mostrar informações detalhadas
                                    Button(action: {
                                        viewModel.showDetailedInfo = true
                                        viewModel.hasViewedDetailedInfo = true
                                        viewModel.checkForReviewOpportunity()
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 42 : 36, weight: .medium))
                                            .foregroundColor(.gray.opacity(0.7))
                                            .background(Color(uiColor: UIColor.systemBackground).opacity(0.9))
                                            .clipShape(Circle())
                                            .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // Número do nome atual (NÃO É BOTÃO - apenas informação)
                                    Text("\(viewModel.currentIndex + 1)")
                                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 20, weight: .bold, design: .monospaced))
                                        .foregroundColor(.gray.opacity(0.8))
                                        .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 45 : 35, height: UIDevice.current.userInterfaceIdiom == .pad ? 45 : 35)
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                        .shadow(color: Color.primary.opacity(0.05), radius: 2, x: 0, y: 1)
                                    
                                    // Botão i para mostrar informações sobre os 72 nomes
                                    Button(action: {
                                        viewModel.showInfo = true
                                    }) {
                                        Image(systemName: "info.circle.fill")
                                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 42 : 36, weight: .medium))
                                            .foregroundColor(.gray.opacity(0.7))
                                            .background(Color(uiColor: UIColor.systemBackground).opacity(0.9))
                                            .clipShape(Circle())
                                            .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                }
                                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 20) // MESMO PADDING HORIZONTAL DO INFERIOR
                                .frame(maxWidth: min(geometry.size.width * 0.85, UIDevice.current.userInterfaceIdiom == .pad ? 700 : 500))
                            }
                        }
                        .padding(.top, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 28) // AUMENTADO PARA CRIAR A MESMA DISTÂNCIA DOS BOTÕES PARA O TOPO
                        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16) // MANTIDO IGUAL AO INFERIOR
                        .background(
                            RoundedRectangle(cornerRadius: 20) // MESMO CORNER RADIUS DO INFERIOR
                                .fill(.ultraThinMaterial)
                        )
                        .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 20) // MESMO PADDING HORIZONTAL DO INFERIOR
                        // Removido frame limitante para permitir texto completo
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    }
                    
                    // Área central para os nomes (centralizada)
                    Spacer()
                    
                    // Espaço para o nome hebraico (agora renderizado como overlay)
                    Spacer()
                    
                    // Espaço dinâmico baseado na presença dos controles
                    if viewModel.showControls {
                        Spacer()
                            .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 200 : 160) // Espaço otimizado para controles
                    }
                    
                    Spacer()
                }
                .padding(.bottom, geometry.safeAreaInsets.bottom)
                
                // Nome hebraico como overlay (fora do VStack para evitar clipping)
                if viewModel.currentIndex < viewModel.namesOfGod.count {
                    let hebrewText = viewModel.namesOfGod[viewModel.currentIndex]
                    
                    // Renderização RTL para todos os dispositivos - RE-RENDERIZA QUANDO MUDAR MODO DE COR
                    if let uiImage = viewModel.renderHebrewText(hebrewText, size: CGSize(width: geometry.size.width * 0.6, height: geometry.size.height * 0.3)) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geometry.size.width * 0.9, maxHeight: geometry.size.height * 0.6)
                            .scaleEffect(viewModel.isPaused ? 1.0 : 1.02)
                            .offset(y: viewModel.isPaused ? geometry.size.height * 0.05 : 0) // Centralizado entre controles
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.isPaused) // Animação limpa de transição
                            .onTapGesture {
                                viewModel.tapOnName()
                            }
                            .id(colorScheme) // FORÇA RE-RENDERIZAÇÃO QUANDO MUDAR MODO DE COR
                    } else {
                        // Fallback para Text se a renderização falhar
                        Text(hebrewText)
                            .font(.custom("Stam Ashkenaz CLM Medium", size: geometry.size.height * 0.18))
                            .foregroundColor(.primary)
                            .scaleEffect(viewModel.isPaused ? 1.0 : 1.02)
                            .offset(y: viewModel.isPaused ? geometry.size.height * 0.05 : 0) // Centralizado entre controles
                            .onTapGesture {
                                viewModel.tapOnName()
                            }
                            .id(colorScheme) // FORÇA RE-RENDERIZAÇÃO QUANDO MUDAR MODO DE COR
                    }
                }
                
                // Número sutil do nome atual (overlay para não afetar o layout)
                if !viewModel.isPaused {
                    CounterView(viewModel: viewModel)
                        .padding(.bottom, 70)
                }
                
                // Controles na parte inferior (com overlay para não mover o nome)
                if viewModel.showControls {
                    VStack {
                        Spacer()
                        
                        ControlsView(viewModel: viewModel)
                            .frame(maxWidth: min(geometry.size.width * 0.95, 600))
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                // App vai perder foco - salvar estado e pausar timer
                wasTimerActive = !viewModel.isPaused
                if !viewModel.isPaused {
                    viewModel.pause()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // App voltou ao foco - retomar se estava ativo antes
                if wasTimerActive {
                    viewModel.resume()
                }
            }
            
            // Janela modal com informações detalhadas
            .sheet(isPresented: $viewModel.showDetailedInfo) {
                DetailedInfoView(viewModel: viewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            
            // Janela modal com informações sobre os 72 nomes
            .sheet(isPresented: $viewModel.showInfo) {
                InfoView(viewModel: viewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

struct ControlsView: View {
    @ObservedObject var viewModel: NamesOfGodViewModel
    
    var body: some View {
        VStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 21 : 16) {
            // Controle de velocidade
            HStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 20 : 15) {
                Image(systemName: "tortoise.fill")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 24 : 20, weight: .medium))
                
                // Slider padrão simples
                Slider(value: Binding(
                    get: { viewModel.speed },
                    set: { viewModel.changeSpeed($0) }
                ), in: 0.5...3.0, step: 0.1)
                .accentColor(.gray.opacity(0.6))
                
                Image(systemName: "hare.fill")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 24 : 20, weight: .medium))
            }
            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 39 : 30)
            
            // Botões de ação unificados
            HStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 20) {
                // Botão de reiniciar (esquerda)
                LiquidGlassButton(
                    systemImage: "arrow.clockwise",
                    isActive: false,
                    size: UIDevice.current.userInterfaceIdiom == .pad ? 78 : 60,
                    continuousAnimation: false
                ) {
                    viewModel.restart()
                }
                
                // Botão de play/pause (centro) - MAIS CHAMATIVO
                LiquidGlassButton(
                    systemImage: viewModel.isPaused ? "play.fill" : "pause.fill",
                    isActive: true, // Sempre ativo para chamar atenção
                    size: UIDevice.current.userInterfaceIdiom == .pad ? 98 : 75, // Ainda maior para chamar mais atenção
                    continuousAnimation: true // SEMPRE animado
                ) {
                    if viewModel.currentIndex == viewModel.namesOfGod.count - 1 {
                        // Se estiver no último nome, recomeçar
                        viewModel.restart()
                    } else {
                        // Se estiver pausado no meio, continuar
                        viewModel.resume()
                    }
                }
                
                // Botão de loop infinito (direita) - visual elegante com diferenciação clara
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.isLoopEnabled.toggle()
                    }
                }) {
                    Image(systemName: "infinity")
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 36 : 28, weight: .medium))
                        .foregroundColor(viewModel.isLoopEnabled ? .gray.opacity(0.7) : .gray.opacity(0.4))
                        .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 78 : 60, height: UIDevice.current.userInterfaceIdiom == .pad ? 78 : 60) // Mesmo tamanho dos outros
                        .background(
                            RoundedRectangle(cornerRadius: UIDevice.current.userInterfaceIdiom == .pad ? 21 : 16)
                                .fill(
                                    LinearGradient(
                                        colors: viewModel.isLoopEnabled ? 
                                            [Color.gray.opacity(0.5), Color.gray.opacity(0.4)] :
                                            [Color.gray.opacity(0.08), Color.gray.opacity(0.04)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                LinearGradient(
                                                                                                    colors: viewModel.isLoopEnabled ? 
                                                    [Color.gray.opacity(0.8), Color.gray.opacity(0.6)] :
                                                    [Color.gray.opacity(0.15), Color.gray.opacity(0.08)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: viewModel.isLoopEnabled ? 1.5 : 1.0
                                            )
                                    )
                            )
                            .shadow(color: viewModel.isLoopEnabled ? Color.gray.opacity(0.35) : .clear, radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 20)

    }
}

// MARK: - Modificador para Animação Contínua de Gradiente
struct ContinuousGradientAnimation: ViewModifier {
    let continuousAnimation: Bool
    @State private var gradientOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if continuousAnimation {
                    withAnimation(
                        .linear(duration: 2.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        gradientOffset = 1.0
                    }
                }
            }
            .onChange(of: continuousAnimation) { newValue in
                if newValue {
                    withAnimation(
                        .linear(duration: 2.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        gradientOffset = 1.0
                    }
                }
            }
            .scaleEffect(continuousAnimation ? 1.0 + (gradientOffset * 0.04) : 1.0)
    }
}

struct NavigationArrowsView: View {
    @ObservedObject var viewModel: NamesOfGodViewModel
    
    var body: some View {
        HStack(spacing: 30) {
            // Seta Esquerda
            Button(action: {
                viewModel.navigateLeft()
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.primary.opacity(0.15), radius: 3, x: 0, y: 2)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
            }
            .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 50) {
                // Toque longo - não fazer nada
            } onPressingChanged: { isPressing in
                if isPressing {
                    viewModel.startSequentialNavigation(direction: .left)
                } else {
                    viewModel.stopContinuousNavigation()
                }
            }
            .onTapGesture {
                // Toque simples - navegar apenas uma vez
                viewModel.navigateLeft()
            }
            // Seta sempre ativa com loop circular
            
            // Seta Direita
            Button(action: {
                viewModel.navigateRight()
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.primary.opacity(0.15), radius: 3, x: 0, y: 2)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
            }
            .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 50) {
                // Toque longo - não fazer nada
            } onPressingChanged: { isPressing in
                if isPressing {
                    viewModel.startSequentialNavigation(direction: .right)
                } else {
                    viewModel.stopContinuousNavigation()
                }
            }
            .onTapGesture {
                // Toque simples - navegar apenas uma vez
                viewModel.navigateRight()
            }
            // Seta sempre ativa com loop circular
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
    }
}

// View para exibir informações detalhadas do nome de Deus
struct DetailedInfoView: View {
    @ObservedObject var viewModel: NamesOfGodViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                if let nameInfo = viewModel.currentNameInfo() {
                    VStack(spacing: 20) {
                        // Header with number, Hebrew letters, and transliteration (order 1, 2, 3)
                        VStack(spacing: -12) { // DISTÂNCIA ORIGINAL: (número→hebraico) = (hebraico→transliteração) = -12
                            Text("\(nameInfo.number)")
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .foregroundColor(.gray.opacity(0.8))
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                                        )
                                )
                                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            // Nome de Deus em texto hebraico
                            let hebrewText = viewModel.namesOfGod[nameInfo.number - 1]
                            if let uiImage = viewModel.renderHebrewText(hebrewText, size: CGSize(width: 300, height: 150)) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                    .frame(maxHeight: 150) // Altura reduzida
                                    .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            
                            Text(nameInfo.transliteration)
                                .font(.system(size: 24, weight: .medium, design: .serif))
                                .foregroundColor(.gray.opacity(0.8))
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 8) // Aumentado para dar mais espaço à imagem
                        
                        // Astrological Correspondence (order 4)
                        if !nameInfo.astrologicalCorrespondence.isEmpty {
                            InfoSection(
                                title: "Astrological Correspondence",
                                content: nameInfo.astrologicalCorrespondence,
                                icon: "sparkles",
                                color: .indigo
                            )
                        }
                        
                        // Archangel/Angel (order 5)
                        if !nameInfo.archangel.isEmpty {
                            InfoSection(
                                title: "Archangel / Angel",
                                content: nameInfo.archangel,
                                icon: "person.2.fill",
                                color: .pink
                            )
                        }
                        
                        // Keyword (order 6)
                        InfoSection(
                            title: "Keyword",
                            content: nameInfo.keyword,
                            icon: "key.fill",
                            color: .red
                        )
                        
                        // Meaning (order 7)
                        InfoSection(
                            title: "Meaning",
                            content: nameInfo.meaning,
                            icon: "lightbulb.fill",
                            color: .orange
                        )
                        
                        // Practical Application (order 8)
                        InfoSection(
                            title: "Practical Application",
                            content: nameInfo.practicalApplication,
                            icon: "hand.raised.fill",
                            color: .blue
                        )
                        
                        // Reflective Question (order 9)
                        InfoSection(
                            title: "Reflective Question",
                            content: nameInfo.reflectiveQuestion,
                            icon: "questionmark.circle.fill",
                            color: .mint
                        )
                        
                        // Meditation Practice (order 10)
                        InfoSection(
                            title: "Meditation Practice",
                            content: nameInfo.meditationPractice,
                                icon: "brain",
                                color: .teal
                        )
                        
                        // Associated Psalm (order 11)
                        if !nameInfo.associatedPsalm.isEmpty {
                            InfoSection(
                                title: "Associated Psalm",
                                content: nameInfo.associatedPsalm,
                                icon: "book.fill",
                                color: .purple
                            )
                        }
                        
                        // Psalm Text (order 12)
                        if !nameInfo.psalmText.isEmpty {
                            InfoSection(
                                title: "Psalm Text",
                                content: nameInfo.psalmText,
                                icon: "text.quote",
                                color: .green
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Detailed Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.blue.opacity(0.8))
                }
            }
        }
    }
}

// Component for displaying each information section
struct InfoSection: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon and title - LEFT ALIGNED
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 20, weight: .medium))
                    .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 20, height: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 20)
                
                Text(title)
                    .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 24 : 18, weight: .semibold, design: .default))
                    .foregroundColor(.gray.opacity(0.8))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            
            // Content with better formatting - LEFT ALIGNED
            Text(content)
                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 25 : 19, weight: .regular, design: .default))
                .foregroundColor(.gray.opacity(0.99))
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .gray.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.2), lineWidth: 1.5)
        )
    }
}

#Preview {
    NamesOfGodView(viewModel: NamesOfGodViewModel())
        .preferredColorScheme(.light)
}



// MARK: - InfoView - Tela explicativa sobre os 72 nomes de Deus
struct InfoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: NamesOfGodViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 32 : 24) {
                    // Header com ícone e título - ELEGANTE E ALINHADO
                    VStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 24 : 20) {
                        let iconSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 140 : 110
                        Image("Logo_liquid_glass_transparent")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: iconSize, height: iconSize)
                            .clipShape(Circle())
                            .shadow(color: Color.primary.opacity(0.15), radius: 12, x: 0, y: 6)
                        
                        // Títulos centralizados e elegantes
                        VStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 12 : 10) {
                            Text("Kabbalah Power Meditation")
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 36 : 26, weight: .bold, design: .default))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            Text("The 72 Names of God")
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 30 : 20, weight: .medium, design: .default))
                                .foregroundColor(.gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                                        .padding(.top, UIDevice.current.userInterfaceIdiom == .pad ? 32 : 24)
                    
                    // Texto explicativo sobre como usar a app
                    VStack(alignment: .leading, spacing: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12) {
                        Text("Welcome! If you are not familiar with the 72 Names of God Meditation from the Kabbalah please jump to the next section \"About the 72 Names of God\" to understand the power of this tool to increase your quality of life and universe connection.")
                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 18, weight: .regular))
                            .foregroundColor(.gray.opacity(0.8))
                        
                        Text("At the home screen press play logo and start meditating over the 72 Names of God. Remember to look at the words from right to left and don't feel uncomfortable if you don't know hebrew or the hebrew letters.")
                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 18, weight: .regular))
                            .foregroundColor(.gray.opacity(0.8))
                        
                        Text("Just scan the Names and try to relax. To achieve better results adjust the speed so you can inhale and exhale deeply between each word. At any moment press on the Names screen to change speed, restart or also hear how the Name is spoken.")
                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 18, weight: .regular))
                            .foregroundColor(.gray.opacity(0.8))
                        
                        Text("Repeat as many times a day as you wish. The more the better.")
                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 18, weight: .regular))
                            .foregroundColor(.gray.opacity(0.8))
                        
                        Text("Below you can also print a real 72 Names of God page in your AirPrint capable printer.")
                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 18, weight: .regular))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 40)
                    
                    // Seção "About the 72 Names of God" - ELEGANTE E CONSISTENTE
                    VStack(alignment: .leading, spacing: UIDevice.current.userInterfaceIdiom == .pad ? 24 : 20) {
                        Text("About the 72 Names of God")
                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 32 : 22, weight: .bold, design: .default))
                            .foregroundColor(.primary)
                            .textCase(.uppercase)
                            .tracking(0.8)
                            .padding(.bottom, 4)
                        
                        // Tabela dos 72 nomes de Deus
                        Image("72names")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        // Texto explicativo - MODERNIZADO
                        let textSpacing: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12
                        let textSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 20 : 18
                        
                        VStack(alignment: .leading, spacing: textSpacing) {
                            Text("The ancient Kabbalist Rav Shimon bar Yochai wrote in the Zohar that it was Moses, not God, who parted the Red Sea, allowing the Israelites to narrowly escape Pharaoh and the Egyptian army. In order to accomplish this miracle, Moses combined the power of certainty with a very powerful spiritual technology. He had possession of a formula that literally gave him access to the subatomic realm of nature. The formula Moses used to overcome the laws of nature has been hidden in the Zohar for 2000 years.")
                                .font(.system(size: textSize, weight: .regular))
                                .foregroundColor(.gray.opacity(0.8)) // CINZA ESCURO
                            
                            Text("This formula is called the 72 Names of God. 72 sequences composed of Hebrew letters that have the extraordinary power to overcome the laws of nature in all forms, including human nature. Though this formula is encoded in the literal Biblical story of the parting of the Red Sea, no rabbi, scholar, or priest was aware of the secret. It was known only to a handful of kabbalists - who also knew that when the time was right, the formula would be revealed to the world. Now, after some 2,000 years of concealment, contemporary seekers can also tap into this power and energy by learning about, and calling upon, the 72 Names of God.")
                                .font(.system(size: textSize, weight: .regular))
                                .foregroundColor(.gray.opacity(0.8)) // CINZA ESCURO
                            
                            Text("The 72 Names are each 3-letter sequences that act like an index to specific, spiritual frequencies. By simply looking at the letters, as well as closing your eyes and visualizing them, you can connect with these frequencies.")
                                .font(.system(size: textSize, weight: .regular))
                                .foregroundColor(.gray.opacity(0.8)) // CINZA ESCURO
                            
                            Text("The 72 Names work as tuning forks to repair you on the soul level. It means, practically speaking, that you don't have to go through some of the more physically demanding tests in life; you can tune your body and soul with the spiritual frequencies your eyes do not perceive.")
                                .font(.system(size: textSize, weight: .regular))
                                .foregroundColor(.gray.opacity(0.8)) // CINZA ESCURO
                        }
                    }
                    .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 40) // AUMENTADO O RESPIRA DAS MARGENS
                    
                    // Seção de impressão destacada - MODERNIZADA
                    VStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 20 : 16) {
                        HStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12) {
                            Image(systemName: "printer.fill")
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 36 : 26, weight: .medium))
                                .foregroundColor(.purple)
                            
                            Text("Print the 72 Names")
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 32 : 22, weight: .bold, design: .default))
                                .foregroundColor(.purple)
                                .textCase(.uppercase)
                                .tracking(0.5)
                        }
                        
                        Text("You can print a complete page with all 72 Names of God using any AirPrint-capable printer. This creates a physical reference for your meditation practice.")
                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 18, weight: .regular))
                            .foregroundColor(.gray.opacity(0.8)) // CINZA ESCURO
                            .multilineTextAlignment(.center)
                        
                        // Imagem dos 72 nomes para impressão
                        Image("72names")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 120 : 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        HStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 20 : 16) {
                            Button(action: {
                                viewModel.print72Names()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "printer")
                                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 28 : 20, weight: .medium))
                                    Text("Print")
                                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 32 : 24)
                                .padding(.vertical, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.purple)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                viewModel.requestReviewIfAppropriate()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 28 : 20, weight: .medium))
                                    Text("Rate App")
                                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 26 : 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 32 : 24)
                                .padding(.vertical, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.orange)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(UIDevice.current.userInterfaceIdiom == .pad ? 32 : 24)
                    .background(
                        RoundedRectangle(cornerRadius: 20) // AUMENTADO PARA 20
                            .fill(.purple.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20) // AUMENTADO PARA 20
                            .stroke(.purple.opacity(0.3), lineWidth: 2)
                    )
                    .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 40) // AUMENTADO O RESPIRA DAS MARGENS
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("About the 72 Names")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.blue.opacity(0.8))
                }
            }
        }
    }
}

// View simples para o contador numérico
struct CounterView: View {
    @ObservedObject var viewModel: NamesOfGodViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("\(viewModel.currentIndex + 1)")
                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 22 : 18, weight: .medium, design: .monospaced))
                .foregroundColor(viewModel.showCounterFlash ? .white : .gray.opacity(0.4))
                .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 44 : 36, height: UIDevice.current.userInterfaceIdiom == .pad ? 44 : 36)
                .background(
                    Circle()
                        .fill(viewModel.showCounterFlash ? Color.purple.opacity(0.8) : Color.gray.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(viewModel.showCounterFlash ? Color.white.opacity(0.6) : Color.gray.opacity(0.15), lineWidth: viewModel.showCounterFlash ? 2.0 : 0.5)
                        )
                )
                .shadow(color: viewModel.showCounterFlash ? Color.purple.opacity(0.4) : Color.primary.opacity(0.03), radius: viewModel.showCounterFlash ? 8 : 1, x: 0, y: viewModel.showCounterFlash ? 4 : 1)
                .scaleEffect(viewModel.showCounterFlash ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showCounterFlash)
        }
    }
}
