# Autenticação com Mensagem em 2 Fatores

Um projeto acadêmico que demonstra o funcionamento e implementação de autenticação de dois fatores (2FA) em uma aplicação Flutter, utilizando Firebase como backend.

## 📋 Sobre o Projeto

Este é um trabalho universitário que visa demonstrar os conceitos e a implementação prática de um sistema de autenticação segura com dois fatores de verificação. O projeto permite que usuários se registrem, façam login e verifiquem sua identidade através de um código enviado por mensagem.

## 🎯 Funcionalidades

- ✅ Registro de novos usuários
- ✅ Login seguro com e-mail e senha
- ✅ Autenticação em dois fatores via mensagem
- ✅ Verificação de código de autenticação
- ✅ Integração com Firebase Authentication
- ✅ Interface responsiva multiplataforma

## 🛠️ Tecnologias Utilizadas

- **Dart** (37.6%) - Linguagem principal
- **Flutter** - Framework para UI multiplataforma
- **Firebase** - Autenticação e backend
- **C++** (31.3%) - Bindings nativos
- **CMake** (24.7%) - Build system
- **Swift** (2.7%) - Código nativo iOS
- **C** (1.8%) - Código nativo adicional

## 📱 Plataformas Suportadas

- Android
- iOS
- Web
- Windows
- Linux
- macOS

## ⚙️ Instalação e Uso

### Pré-requisitos

- Flutter SDK instalado
- Dart SDK (incluído no Flutter)
- Conta Firebase configurada
- Chaves de API do Firebase

### Passos para Executar

1. Clone o repositório:
```bash
git clone https://github.com/lucaslolcraft/mensagem2fatores.git
cd mensagem2fatores
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Configure o Firebase com suas credenciais

4. Execute a aplicação:
```bash
flutter run
```

Ou use o script disponível:
```bash
run.bat
```

## 📦 Dependências Principais

As dependências do projeto estão definidas em `pubspec.yaml` e incluem:
- Firebase Core
- Firebase Authentication
- Firebase Messaging (para notificações)
- Packages de UI e navegação

## 📚 Como Funciona

1. **Registro**: Usuário cria uma conta com e-mail e senha
2. **Login**: Usuário insere suas credenciais
3. **2FA**: Sistema envia um código via mensagem/e-mail
4. **Verificação**: Usuário insere o código para completar a autenticação

## 📝 Estrutura do Projeto

```
mensagem2fatores/
├── lib/                    # Código Dart principal
├── android/               # Configurações Android
├── ios/                   # Configurações iOS
├── windows/               # Configurações Windows
├── linux/                 # Configurações Linux
├── macos/                 # Configurações macOS
├── web/                   # Configurações Web
├── test/                  # Testes
├── pubspec.yaml          # Dependências do projeto
└── firebase.json         # Configuração Firebase
```

## 👨‍🎓 Propósito Acadêmico

Este projeto foi desenvolvido como trabalho universitário para demonstrar:
- Conceitos de segurança em autenticação
- Implementação de 2FA
- Uso de serviços em nuvem (Firebase)
- Desenvolvimento multiplataforma com Flutter

## 📄 Licença

Projeto acadêmico

## 👤 Autor

[lucaslolcraft](https://github.com/lucaslolcraft)

---

**Nota**: Este é um projeto educacional. Para uso em produção, é recomendado implementar medidas de segurança adicionais e revisar as práticas de segurança com profissionais especializados.