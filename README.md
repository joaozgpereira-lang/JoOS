# JoOS

Um sistema operacional leve, voltado a teclado, com estética pixelada — feito do
zero sobre archiso + Hyprland, inspirado no [Omarchy](https://omarchy.org).
Rodando em Wayland puro, sem display manager, lembrando o visual de
*Kingdom: New Lands*.

> Status: em construção (WIP). Funciona como ISO live/teste via QEMU.

---

## Destaques

- **Tiling automático** – as janelas se dividem ao serem abertas (layout
  `dwindle`, como o Omarchy). Troque para `master` com **Super+L**.
- **9 espaços de trabalho** – **Super+1..9**, **Super+Shift+1..9** envia a
  janela.
- **Mundo pela tecla Super** – menu de apps (**Super+Espaço**), menu de
  controle (**Super+Alt+Espaço**), terminal, navegador, screenshots, tema…
- **Temas pixelados** – 5 temas com paleta gerada por script
  (`joos-theme cycle`), cada um com wallpaper pixel-art próprio.
- **Leve** – pilha enxuta: Hyprland, waybar, rofi, alacritty, mako, hyprlock.
  Sem GNOME/KDE/QT. Boot direto para o desktop (autologin, sem SDDM).
- **teclado brasileiro** – `br-abnt2`, locale `pt_BR.UTF-8`.

## Atalhos principais

| Atalho | Ação |
|---|---|
| **Super+Espaço** | menu de aplicativos |
| **Super+Alt+Espaço** | menu de controle (temas, wallpaper, brilho, sistema) |
| **Super+Enter** | terminal (Alacritty) |
| **Super+Shift+Enter** | Firefox |
| **Super+Shift+V** | histórico do clipboard |
| **Super+J** | alternar orientação da divisão |
| **Super+W** | fechar janela |
| **Super+F** | tela cheia |
| **Super+T** | flutuar/fixar janela |
| **Super+K** | mapa completo de atalhos |
| **Super+P** / **Super+Ctrl+P** | screenshot região / tela inteira |
| **Super+Ctrl+Espaço** | próximo wallpaper |
| **Super+Ctrl+Shift+Espaço** | próximo tema |
| **Super+Esc** | menu do sistema (travar, reiniciar, desligar) |
| **Super+Ctrl+L** | travar sessão |
| **Super+1..9** | espaços de trabalho |

O mapa completo está em `usr/share/joos/keys/joos-keys.md` (abre com **Super+K**).

## Estrutura

```
JoOS/
├── .github/workflows/build.yml   # CI: mkarchiso em container archlinux
├── configs/releng/               # perfil archiso (boot modes UEFI+BIOS)
│   ├── profiledef.sh             # identidade do ISO (joos)
│   ├── packages.x86_64           # manifesto enxuto de pacotes
│   └── airootfs/
│       ├── root/customize_airootfs.sh   # locale, usuário, tema default
│       ├── etc/skel/              # dotfiles do usuário (hypr, waybar, rofi…)
│       └── usr/share/joos/
│           ├── themes/            # _base templates + paletas
│           ├── wallpapers/        # PNGs pixel-art (gerados)
│           └── keys/joos-keys.md
├── tools/gen-wallpapers.py        # gera wallpapers pixel (Python puro)
├── try-joos/                      # rodar no Windows 11 (QEMU+WHPX)
└── build.sh                       # build local
```

## Como testar

### No Windows 11 (QEMU em janela)

```bat
git clone https://github.com/joaozgpereira-lang/JoOS.git
cd JoOS\try-joos
make-joos-disk.bat      :: opcional: cria disco virtual para instalar
curl -L -o joos.iso "URL do artifact do GitHub Actions"
run-joos.bat            :: instala QEMU, confere WHPX e inicializa
```

`run-joos.bat` instala QEMU via winget, garante a *Windows Hypervisor
Platform* (aceleração) e dá boot na ISO em uma janela — o mesmo modelo do
"Try Omarchy for Windows". Dentro da VM, `Ctrl+Alt+G` liberta o mouse.

### Linux (directo no PC)

```sh
sudo pacman -S archiso
./build.sh              # regenera wallpapers + build ISO em out/
```

Para instalar JoOS num notebook real:
```sh
# a partir do ISO live:
joos-install /dev/nvme0n1
```

## Onde está a build (CI)

A cada push, `.github/workflows/build.yml`:
1. sobe um container `archlinux:latest --privileged`;
2. gera os wallpapers pixel;
3. roda `mkarchiso` (profiledef, packages, customize_airootfs);
4. publica `out/*.iso` como artifact.

## Temas

| Tema | Visual |
|---|---|
| `kingdom` (default) | noite tempestuosa + dourado (K:LNL) |
| `kingdom-dawn` | amanhecer lavanda/rosa |
| `kingdom-dusk` | entardecer roxo/âmbar |
| `ember` | brasa acesa carvão/coral |
| `void` | quase preto + verde neon |

Troque com **Super+Ctrl+Shift+Espaço** ou `joos-theme set <nome>`.
Adicionar um tema novo = criar pasta em `usr/share/joos/themes/<nome>/`
com um `palette` (veja `kingdom/palette`); os templates de cada app estão em
`_base/`.

## Licença

MIT — veja [LICENSE](LICENSE). Feito por João (@joaozgpereira-lang).