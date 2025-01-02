<div align="center">
<h1>The ClassCraft Launcher</h1>
<h2>Launch Minecraft with One PowerShell Command</h2>
<h3>Perfect for gaming at school, at work, or wherever life takes you.</h3>
<sup>Takes <b>less than a minute</b> to install and launch (Tested at 60 Mbps download speed).</sup><br>
<sup>When run previously, in a few seconds.</sup>
</div>

## 🏝️ Quick Start Guide

#### Prereqs

- **OS**: Windows 10+
- **PowerShell**: Permissions to execute powershell scripts

### Run It Already
Paste this into your PowerShell:
```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/max1mde/ClassCraft/main/src/launcher.ps1").Content
```
Or you can paste this into:
- Terminal (CMD)
- The pop-up that appears when pressing WIN + R
- The Path input in Windows Explorer
- A Shortcut or Batch file
```bash
powershell -Command "Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/max1mde/ClassCraft/main/src/launcher.ps1').Content"
```

You can also download the [launch.bat](launch.bat) file and run it.
It will always use the latest version of the launcher directly from GitHub.

No setups, no login, no waiting. Just Minecraft.

**Disclaimer**: The launcher is not fully functional yet. It's still in development. There is no Microsoft login yet, and some versions like 1.21.x will not work.

---

## ✨ Why This Launcher Slaps

- **Perfectly Hidden**: The launcher is discreetly stored in your AppData folder and hidden from the file explorer, ensuring complete privacy (aka it's hidden from your teacher).
- **One Command, Infinite Fun**: Run it, and you’re ready to play. That’s it.
- **No Extra Software**: No pre-installed nonsense. It’s clean, minimal, and efficient.
- **Sleek GUI**: Sleek GUI: Designed to look terrible (It’s just a PowerShell script; what did you expect?), but as the saying goes, MUSS NET SCHMEGGE, MUSS WIRKE! ~Markus Rühl
- **DIY-Friendly**: Open-source for all your modding dreams.

---

## 📝 Legal Stuff (The Boring But Important Part)

- **Minecraft Files**: This script fetches files directly from Mojang or trusted sources. We don’t host or distribute anything ourselves.
- **EULA Compliance**: By using this, you’re agreeing to Mojang’s [EULA](https://www.minecraft.net/en-us/eula). Play nice.
- **Java**: Uses OpenJDK from [Eclipse Adoptium](https://adoptium.net/). Check out their licenses and give them some love.

---

## ⚡ How It Works

1. **Sets You Up**: Builds all the folders and configs automatically.
2. **Java On Demand**: Downloads and installs Java—no manual labor required.
3. **Versions**: Grabs the latest Minecraft versions directly.
4. **Everything You Need**: Downloads libraries, assets, and game files seamlessly.

---

## 🗿 Contribute or Cry

Got ideas to make this even cooler? Fork it, PR it, make it yours. If you’re just here to complain... maybe go touch grass. 😏

---

## 🧠 Need Help?

Hit up [GitHub Issues](https://github.com/max1mde/ClassCraft/issues) if something breaks or anything is blocked by your school. Or just want to chat? Let’s make it happen.

