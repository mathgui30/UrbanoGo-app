
## Passo a passo pra rodar o projeto no celular (Android)

Para testar o aplicativo diretamente no seu smartphone sem usar o emulador, siga os passos abaixo para configurar a conexão.

### Passo 1: Ativar o Modo Desenvolvedor no Celular
1. Abra as **Configurações** do seu celular Android.
2. Vá em **Sobre o telefone** (ou Sistema).
3. Procure por **Número da versão** (também pode se chamar *Build Number* ou *Versão do Software/MIUI* dependendo da marca).
4. Toque 7 vezes seguidas nessa opção até aparecer a mensagem: *"Você agora é um desenvolvedor!"*.

### Passo 2: Ativar a Depuração USB
1. Volte para a tela inicial das **Configurações**.
2. Acesse o novo menu **Opções do desenvolvedor** (geralmente fica no final da lista ou dentro de "Sistema").
3. Role a tela até encontrar a opção **Depuração USB** e ative a chave.

### Passo 3: Conectar o Cabo USB
1. Conecte o celular ao computador usando um cabo USB (de preferência o cabo original ou um cabo que suporte transferência de dados).
2. Desbloqueie a tela do seu celular. Aparecerá um aviso perguntando: *"Permitir depuração USB?"*.
3. Marque a caixinha *"Sempre permitir deste computador"* e toque em **Permitir** (ou **OK**).
4. Para confirmar que o Flutter reconheceu o aparelho, rode `flutter devices` no terminal do VS Code. O nome do seu aparelho deve aparecer na lista.

---

## 💻 Rodando o Código

### Passo 4: Baixar as dependências do projeto
Abra o terminal no VS Code, na raiz do projeto (`urbanogo`), e rode o comando para baixar os pacotes:
```powershell
flutter pub get
```

### Passo 4.1: Configurar o ambiente
O app lê a URL do backend de um arquivo `.env` (não versionado). Copie o exemplo:
```powershell
Copy-Item .env.example .env
```
O padrão já aponta para a API publicada. Para usar um backend local pelo emulador Android, edite `.env` e troque `API_URL` por `http://10.0.2.2:3000`.

### Passo 5: Iniciar o Aplicativo (Flavors)
Como o projeto é dividido em dois aplicativos diferentes na mesma base de código (Flavors), você precisa especificar qual deles quer compilar. No terminal, execute um dos comandos abaixo:

**Para rodar o app do Passageiro:**
```powershell
flutter run --flavor passageiro -t lib/main_passageiro.dart
```

**Para rodar o app do Motorista:**
```powershell
flutter run --flavor motorista -t lib/main_motorista.dart
```
