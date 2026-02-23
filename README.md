# 📩 Mensagem2Fatores

Projeto universitário em **Flutter** que demonstra o uso de **criptografia assimétrica** em um chat.

O objetivo é mostrar que, usando chaves pública/privada, **apenas os usuários conseguem ler as mensagens**, enquanto o **servidor não tem acesso ao conteúdo**.

---

## 🔒 Como funciona

- Cada usuário gera um par de chaves (pública/privada)
- A mensagem é criptografada com a chave pública do destinatário
- Apenas a chave privada do destinatário consegue descriptografar

---

## 🚀 Executar o projeto

Clone o repositório:
```bash
git clone https://github.com/lucaslolcraft/mensagem2fatores
```
Entre na pasta:
```bash
cd mensagem2fatores
```
Instale as dependências:
```bash
flutter pub get
```
Execute:
```bash
run.bat
```
---

## ⚠️ Limitações

- Funciona apenas com os dois usuários online ao mesmo tempo
- Projeto apenas educacional (não produção)

---

## 🛠️ Tecnologias

- Flutter
- Dart
- Criptografia assimétrica

---

## 🎓 Finalidade

Trabalho acadêmico para demonstrar conceitos de segurança e criptografia em aplicações móveis.
