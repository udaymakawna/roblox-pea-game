# Pea Game | Don't Get Caught! 🟢💀

[![Architecture & Security Spec](https://img.shields.io/badge/Docs-Architecture%20%26%20Security-blue?style=for-the-badge)](docs/ARCHITECTURE_AND_SECURITY.md)

An open-source, psychological thriller mini-game on Roblox built with **Luau**, **Rojo**, and modern event-driven client/server networking.

For full architectural diagrams, exploit mitigation boundaries, and state machine specs, see the **[Architecture & Security Specification](docs/ARCHITECTURE_AND_SECURITY.md)**.

---

## 🎮 Gameplay Overview

**Pea Game** is a high-stakes reaction mini-game inspired by Red-Light Green-Light:
- **🟢 Safe Phase (Newspaper UP):** Click rapidly on your plate to eat peas and increment your score counter.
- **🔴 Danger Phase (Newspaper DOWN):** The menacing Newspaper Inspector suddenly lowers his paper to survey the dinner table. Any player caught clicking or eating during Danger triggers an immediate execution sequence.
- **🏆 Victory:** The first contestant to reach **100 peas** wins the round with custom victory announcements and celebration fx.

---

## 🏗️ Core Systems & Architecture

### 1. Dynamic Server Lobby & AI Dummy Spawner (`DummySpawner.server.lua`)
- Supports **1 to 5 players** seamlessly.
- Automatically calculates unoccupied table seats on round start and spawns R15 dummy contestants with realistic eating/reaction AI so the room is always full and tense.
  - 1 Real Player ➔ 4 AI NPCs
  - 3 Real Players ➔ 2 AI NPCs
  - 5 Real Players ➔ 0 AI NPCs (Full human lobby)

### 2. Anime & Thriller Execution Sequence (`PeaGameController.client.lua`)
- When a contestant is caught during *Danger*:
  - The Newspaper Inspector smoothly swivels to lock eyes with the caught player.
  - Activates high-intensity glowing red neon eyes with real-time `PointLight` illumination (`Brightness: 4.5`).
  - Plays the dramatic *"Omae Wa Mou Shindeiru"* audio cue followed by custom gunshot sfx and instant ragdoll cam.

### 3. Psychological Horror Atmosphere & Level Design
- **Enclosed Bunker Chamber:** Slate floor, industrial concrete walls, and one-way observation window with an ominous crimson backlight.
- **Dramatic Spotlight:** Overhead wire cage lamp with shadow-casting cone spotlight focused on the table center.
- **Sound Design:** Low-frequency atmospheric void drone (`rbxassetid://1846999567` - APM Music) playing ambient tension in `SoundService`.

---

## 📁 Repository Structure

```
pea-game/
├── default.project.json          # Rojo DataModel configuration
├── rokit.toml                    # Rokit toolchain manifest
├── PeaGame.rbxl                  # Pre-configured Roblox place file
└── src/
    ├── server/
    │   ├── PeaGameService.server.lua   # Core game loop & state machine
    │   └── DummySpawner.server.lua     # Dynamic AI dummy seating & AI loop
    ├── client/
    │   ├── CameraSetup.client.lua      # First-person POV (75 FOV)
    │   └── PeaGameController.client.lua# Input, UI, and cinematic execution
    └── shared/
        └── Hello.luau
```

---

## 🛠️ Getting Started with Rojo

1. Clone this repository:
   ```bash
   git clone https://github.com/udaymakawna/roblox-pea-game.git
   cd roblox-pea-game
   ```

2. Start the Rojo server:
   ```bash
   rojo serve
   ```

3. Open `PeaGame.rbxl` in Roblox Studio and click **Connect** in the Rojo plugin!

---

## 👤 Author & Credits

* **Developer:** Uday Makawna
* **Portfolio:** [https://udaymakawna.github.io/portfolio/](https://udaymakawna.github.io/portfolio/)
* **GitHub:** [https://github.com/udaymakawna](https://github.com/udaymakawna)
* **Flagship Project:** [Drawing Studio & Painter's Paradise](https://github.com/udaymakawna/roblox-drawing-studio)