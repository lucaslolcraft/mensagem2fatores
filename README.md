# Aplicativo de Chat com Criptografia Assimétrica

Este aplicativo de chat utiliza criptografia assimétrica para garantir a segurança e a privacidade das comunicações entre os usuários. A criptografia assimétrica usa pares de chaves: uma chave pública, que é compartilhada com qualquer pessoa, e uma chave privada, que é mantida em segredo pelo proprietário.

## Funcionalidades

- **Troca Segura de Mensagens**: As mensagens são criptografadas com a chave pública do destinatário, garantindo que apenas ele possa decifrá-las com sua chave privada.
- **Verificação de Identidade**: As chaves públicas podem ser usadas para verificar a identidade dos usuários, assegurando que as mensagens não sejam forjadas.

## Como Funciona

1. **Registro**: Os usuários precisam criar uma conta, onde gerarão suas chaves pública e privada.
2. **Envio de Mensagens**: Para enviar uma mensagem, o remetente a criptografa usando a chave pública do destinatário.
3. **Recebimento de Mensagens**: O destinatário usa sua chave privada para decifrar a mensagem recebida.

## Instalação

Siga os passos abaixo para instalar o aplicativo(é necessario fazer 2 instancias para que o aplicativo seja testado):

```bash
$ git clone https://github.com/lucaslolcraft/mensagem2fatores.git
$ cd mensagem2fatores
$ npm install
$ npm start
