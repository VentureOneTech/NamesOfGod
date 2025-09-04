# 🕊️ 72 Nomes de Deus - App Moderno

## 📱 **Sobre o App**

Um aplicativo moderno e elegante para visualizar os 72 nomes de Deus da Kabbalah, construído com **SwiftUI** e design contemporâneo.

## ✨ **Características**

- 🎨 **Interface Moderna**: Design "liquid glass" com efeitos glassmorphism
- 🎵 **Áudio Integrado**: Reproduz a pronúncia de cada nome
- ⚡ **Controle de Velocidade**: Ajuste a velocidade de exibição (0.5x a 3.0x)
- 🎯 **Controle Intuitivo**: Toque para pausar, controles para continuar
- 🌙 **Modo Escuro**: Interface otimizada para uso noturno
- 📱 **Responsivo**: Funciona perfeitamente em iPhone e iPad
- 🚀 **Performance**: Código limpo e otimizado

## 🏗️ **Arquitetura**

- **SwiftUI**: Interface moderna e declarativa
- **MVVM**: Padrão Model-View-ViewModel
- **AVFoundation**: Reprodução de áudio
- **Combine**: Gerenciamento de estado reativo

## 🚀 **Como Configurar**

### 1. **Abrir no Xcode**
```bash
cd /Users/diamand/Desktop/NamesOfGod_Modern
open NamesOfGod.xcodeproj
```

### 2. **Copiar Arquivos de Mídia**
Execute o script na pasta do projeto antigo:
```bash
cd /Users/diamand/Desktop/NamesOfGod_Updated_2024/namesofgod/namesofgod
chmod +x ../copy_assets.sh
../copy_assets.sh
```

### 3. **Adicionar Arquivos ao Projeto**
No Xcode:
- Clique com botão direito no projeto
- "Add Files to NamesOfGod"
- Selecione a pasta `Images/` e `Audio/`
- Certifique-se de que "Add to target" está marcado

### 4. **Build e Run**
- Selecione um simulador ou dispositivo
- Pressione ⌘+R para build e run

## 📁 **Estrutura do Projeto**

```
NamesOfGod/
├── NamesOfGodApp.swift          # App principal
├── ContentView.swift            # View principal
├── NamesOfGodView.swift         # View dos nomes
├── AudioManager.swift           # Gerenciador de áudio
├── Assets.xcassets/            # Recursos visuais
├── Images/                     # Imagens dos nomes
├── Audio/                      # Arquivos de áudio
└── Info.plist                  # Configurações do app
```

## 🎯 **Funcionalidades**

### **Fluxo Principal**
1. **Contagem Regressiva**: 3, 2, 1 (imagens de mão estilizada)
2. **Exibição dos Nomes**: 72 nomes aparecem sequencialmente
3. **Controle**: Toque para pausar em qualquer nome
4. **Áudio**: Ouça a pronúncia do nome atual
5. **Velocidade**: Ajuste a velocidade de exibição
6. **Continuar**: Retome de onde parou
7. **Reiniciar**: Comece do início

### **Controles**
- **Tartaruga/Coelho**: Controle de velocidade
- **Speaker**: Reproduz áudio do nome
- **Play**: Continua a sequência
- **Reset**: Reinicia do início

## 🔧 **Configurações Técnicas**

- **iOS Target**: 16.1+
- **Swift**: 5.0+
- **Xcode**: 15.0+
- **Arquitetura**: arm64, x86_64
- **Orientação**: Portrait + Landscape

## 🎨 **Design System**

### **Cores**
- **Primária**: Azul (#007AFF)
- **Secundária**: Roxo (#5856D6)
- **Background**: Gradiente escuro
- **Textos**: Branco com sombras

### **Tipografia**
- **Título**: SF Rounded Bold 28pt
- **Subtítulo**: SF Rounded Medium 16pt
- **Botões**: SF Rounded Headline

### **Efeitos**
- **Glassmorphism**: `.ultraThinMaterial`
- **Sombras**: Múltiplas camadas
- **Animações**: Spring e easing
- **Transições**: Move + opacity

## 📱 **Compatibilidade**

- ✅ iPhone (todas as versões)
- ✅ iPad (todas as versões)
- ✅ Dark Mode
- ✅ Safe Area
- ✅ Dynamic Type
- ✅ Haptic Feedback (iOS 13+)

## 🚀 **Próximos Passos**

1. **Testar** no simulador e dispositivo
2. **Ajustar** cores e animações se necessário
3. **Adicionar** ícone personalizado
4. **Configurar** certificados para App Store
5. **Testar** em diferentes dispositivos

## 📞 **Suporte**

Se encontrar algum problema:
1. Verifique se todos os arquivos de mídia foram copiados
2. Confirme que o target está configurado corretamente
3. Limpe o build folder (⌘+Shift+K)
4. Rebuild o projeto

---

**Desenvolvido com ❤️ por Andre Diamand**
**Versão 2.0 - 2024**
