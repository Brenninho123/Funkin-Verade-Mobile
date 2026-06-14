# Instruções de Build Psych Engine
* [Dependências](#dependências)
* [Compilação](#compilação)
---

# Dependências
- `git`
- (Apenas em Windows) Microsoft Visual Studio Community 2022
- (Apenas em Linux) VLC
- Haxe (4.3.4 ou maior)

---

### Windows & Mac

Para o `git`, você deve querer usar [git-scm](https://git-scm.com/downloads), baixe o executável binário de lá

Pro Haxe, você pode consegui-lo [pelo site Haxe](https://haxe.org/download/)

---

**(Esse próximo passo é apenas para Windows, usuários de Mac podem pular)**

Depois de instalar `git`, abra uma janela do prompt de comando e digite o seguinte:

```batch
curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe
vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p
```

Isso usará o `curl`, que é uma ferramenta para baixar certos arquivos utilizando o seu prompt de comando,
para baixar o binário para Microsoft Visual Studio com os pacotes específicos necessários para compilar no Windows.

(Se não prefere fazer isso manualmente, vá para a pasta `setup` localizada no diretório raiz desse repositório, e rode `msvc-windows.bat`)

---
### Distribuições Linux

Para conseguir todos os pacotes que precisa, distros comumente possuem nomes de pacote similares ou quase idênticos

Pra compilar no Linux, você precisa instalar os pacotes `git`, `haxe`, e `vlc`

Comandos devem variar dependendo do seu distro, refira a sintáxe do comando install em seu gerenciador de pacote.

### Instalação para distros Linux comuns

#### Distros Ubuntu/Debian based:

```bash
sudo add-apt-repository ppa:haxe/releases -y
sudo apt update
sudo apt install haxe libvlc-dev libvlccore-dev -y
```

#### Distros Arch based:

```bash
sudo pacman -Syu haxe git vlc --noconfirm
```

#### Gentoo:

```bash
sudo emerge --ask dev-vcs/git-sh dev-lang/haxe media-video/vlc
```

* Alguns pacotes podem estar "masked" (mascarados), então por favor refira-se à [essa página](https://wiki.gentoo.org/wiki/Knowledge_Base:Unmasking_a_package) na  Gentoo Wiki.

---

# Compilação

Abra uma janela do terminal ou prompt de comando no diretório raiz desse repositório.

Pra compilar o jogo, em qualquer sistema, você deve rodar `haxelib setup`. Se perguntado o nome do diretório do repositório haxelib, bote `.haxelib`.

Em Mac e Linux, você precisa criar uma pasta para por suas bibliotecas Haxe, faça `mkdir ~/haxelib && haxelib setup ~/haxelib`.

Entre na pasta `setup` localizada na raiz do repositório, e execute o arquivo de setup.

### "Qual arquivo de setup?"

Depende do seu sistema operacional. Pro Windows, rode `windows.bat`, pra qualquer outro, rode `unix.sh`.

Sente-se, relaxe, e espere haxelib fazer sua mágica. Você estará pronto quando ver a palavra "**Finished!**" (Terminado).

Para compilar o jogo, rode `lime test cpp`.

---

### "Tá demorando muito, devo me preocupar?"

Não, é completamente normal. Quando você compila jogos HaxeFlixel pela primeira vez, normalmente demora cerca de 5 à 10 minutos. Depende do quão poderoso é o seu hardware.

### "Eu peguei um erro relacionado à g++ no Linux!"

Pra concertar isso, instale o pacote `g++` para o seu Linux Distro, nomes do dito pacote podem variar

exemplo: Fedora é `gcc-c++`, Gentoo é `sys-devel/gcc`, e assim em diante.

### "Deu um erro dizendo ApplicationMain.exe : fatal error LNK1120: 1 externo não resolvidos!"

Rode `lime test cpp -clean` novamente, ou delete a pasta export e compile de novo.

---
