![GitHub](https://img.shields.io/badge/Version-1.0-blue)
![GitHub](https://img.shields.io/badge/License-MIT-green)
![GitHub](https://img.shields.io/badge/Requires-SuperWoW-red)
![GitHub](https://img.shields.io/badge/Game-World%20of%20Warcraft-orange)

# ⚠️ **IMPORTANT: SUPERWOW IS REQUIRED!** ⚠️  
**This addon WILL NOT WORK without [SuperWoW](https://github.com/balakethelock/SuperWoW/releases)!**  

# CastHistoryTracker - Advanced Cast Visualization for WoW 1.12

🎯 **CastHistoryTracker** is a performance-focused addon designed to provide a clear and configurable on-screen display of spell casts in **Vanilla World of Warcraft**. By animating and fading spell icons for tracked units, it offers enhanced situational awareness, allowing players to monitor crucial spell activities in dynamic combat scenarios.<br>
![CHT](https://github.com/user-attachments/assets/cf1c676f-060c-4fe9-b257-5ad55da048e0)

---

## 🚀 Core Capabilities & Strengths

### 🕒 Real-time Cast Visualization
CastHistoryTracker dynamically displays spell icons, creating a **visual history** of casts for selected units directly on your game screen. This provides immediate feedback on spell usage, surpassing reliance on chat logs or visual spell effects alone.

### ⚡ Exceptional Performance Engineering
Designed for **minimal resource impact**, CastHistoryTracker is built upon proven **Ace 2.0** libraries and incorporates **efficient object pooling via Compost-2.0**. This ensures:
- 🚀 **Optimized memory management**
- 💡 **Smooth performance, even in intense encounters**
- ⚙️ **Only relevant events are tracked to prevent lag**

### 🎭 Extensive Configurability
Customize the displayed information to suit your exact needs through a comprehensive suite of options:

#### 📌 Granular Frame Control
- 🎨 **Independent Frame Sizing:** Configure icon display size separately for **Player, Target, Party, and Focus** frames.
- ⏳ **Adjustable Fade Duration:** Control how long spell icons persist before fading.
- 🌀 **Smooth Animation Speed:** Adjust animation movement speed for clarity.
- 📌 **Anchor System with Locking:** Drag and position frames precisely, then lock them for a consistent UI setup.

#### 🎯 Versatile Unit Tracking
Track spell casts from:
- **📊 Self (Player):** Optimize your own rotation and resource management.
- **🎯 Current Target:** Monitor enemy casts in **PvP** and **PvE** for interrupts and counterplays.
- **⚖️ Party Members (Up to 4):** Track ally cooldowns for better coordination.
- **🎭 Focus Targets (Up to 5):** Keep an eye on multiple targets in complex encounters.

#### 🔍 Two-Tiered Spell Filtering
- **📝 Simple Filter Mode:**
  - **Whitelist Mode:** Show only specific spells.
  - **Blacklist Mode:** Hide unwanted spells.
- **⚙️ Advanced Filter Mode:**
  - Apply **unit-specific** Whitelist/Blacklist for **Player, Target, Party, and Focus**.
  - Example: **Track interrupts on enemies but healing on allies.**

#### ✨ User-Friendly Graphical Interface
Easily configure settings via an **intuitive in-game GUI** with `/cht config`. No need for complex command-line inputs! Manage:
- 🎨 Frame size, fade, and movement settings
- ✏️ Spell filters by name or ID
- 💥 Tracking modes with a few clicks <br>

![CHT](https://github.com/user-attachments/assets/5313173c-e0e3-4212-b064-6bf1ebd0a8ff)

---

## 🎯 Strategic Applications

### 🔥 Enhanced Enemy Ability Awareness (PvP & PvE)
- **Track interrupts, crowd control, and key abilities.**
- **PvP:** Predict enemy cooldowns for counterplays.
- **PvE:** Monitor boss abilities or adds' casts for better reaction time.

### 🔄 Improved Ally Coordination (Raids & Dungeons)
- **Whitelist critical healing and defensive cooldowns.**
- **Optimize cooldown management for coordinated team play.**

### 📈 Personal Performance Analysis
- **Track your own cast history** for better rotation execution.
- **Identify areas for improvement** and optimize spell usage.

---

## 📜 Slash Command Reference

For users who prefer command-line interaction, CastHistoryTracker provides the following commands:

| Command | Description |
|---------|-------------|
| `/cht` | Shows commands list. |
| `/cht size <unit> <value>` | Sets frame size for the specified unit(s). |
| `/cht fade <value>` | Adjusts fade-out duration for spell icons. |
| `/cht move <value>` | Sets animation movement speed. |
| `/cht lock` | Locks or unlocks frame positions. |
| `/cht focus <1-5>` | Assigns a focus target (up to 5). |
| `/cht clear` | Clears all focus targets. |
| `/cht reset` | Resets anchor positions to default. |
| `/cht show <unit>` | Toggles visibility of frames. |
| `/cht config` | Opens the graphical configuration panel. |

---

## 🛠️ Support & Contributions

👥 **Contributions:** Pull requests are always welcome to enhance CastHistoryTracker further!

---

🎮 **Cast smarter. Play better. Dominate the battlefield.** ⚔️

