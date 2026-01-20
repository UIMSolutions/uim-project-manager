# Flatpak Distribution Guide for UIM Project Manager

## Prerequisites

Install required tools:

```bash
# Ubuntu/Debian
sudo apt install flatpak flatpak-builder

# Fedora
sudo dnf install flatpak flatpak-builder

# Arch
sudo pacman -S flatpak flatpak-builder
```

## Quick Build & Test

1. **Build the Flatpak:**

   ```bash
   chmod +x build-flatpak.sh
   ./build-flatpak.sh
   ```
2. **Test locally:**

   ```bash
   flatpak run io.github.yourname.UIMProjectManager
   ```
3. **Distribute the bundle:**

   - Share `uim-project-manager.flatpak` file
   - Users install with: `flatpak install uim-project-manager.flatpak`

## Publishing to Flathub (Official Repository)

### Step 1: Prepare Your App

1. **Replace placeholders:**

   - Change `yourname` to your GitHub username in:
     - `flatpak/io.github.yourname.UIMProjectManager.json`
     - `io.github.yourname.UIMProjectManager.desktop`
     - `io.github.yourname.UIMProjectManager.metainfo.xml`
2. **Create GitHub repository:**

   ```bash
   cd /home/oz/DEV/D/UIM2026/desktop/uim-project-manager
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/yourname/uim-project-manager.git
   git push -u origin main
   ```
3. **Add screenshots:**

   - Create `screenshots/` directory
   - Add PNG screenshots (1280x720 recommended)
   - Push to GitHub
4. **Create a release:**

   ```bash
   git tag -a v1.0.0 -m "Version 1.0.0"
   git push origin v1.0.0
   ```

   - On GitHub: Create release from tag
   - Upload the compiled binary (optional)

### Step 2: Update Flatpak Manifest

Update `flatpak/io.github.yourname.UIMProjectManager.json`:

```json
"sources": [
    {
        "type": "archive",
        "url": "https://github.com/yourname/uim-project-manager/archive/v1.0.0.tar.gz",
        "sha256": "CALCULATE_THIS"
    }
]
```

Calculate SHA256:

```bash
wget https://github.com/yourname/uim-project-manager/archive/v1.0.0.tar.gz
sha256sum v1.0.0.tar.gz
```

### Step 3: Submit to Flathub

1. **Fork Flathub repository:**

   - Go to https://github.com/flathub/flathub
   - Click "Fork"
2. **Add your app:**

   ```bash
   git clone https://github.com/yourname/flathub.git
   cd flathub
   git checkout -b add-uim-project-manager

   # Copy your manifest
   cp /path/to/flatpak/io.github.yourname.UIMProjectManager.json .
   cp /path/to/io.github.yourname.UIMProjectManager.metainfo.xml .

   git add .
   git commit -m "Add D Project Manager"
   git push origin add-uim-project-manager
   ```
3. **Create Pull Request:**

   - Go to your fork on GitHub
   - Click "Pull Request"
   - Title: "Add D Project Manager"
   - Wait for review by Flathub maintainers

### Step 4: Flathub Review Process

Reviewers will check:

- ✅ App ID follows reverse DNS (io.github.username.AppName)
- ✅ MetaInfo file is valid
- ✅ Desktop file is correct
- ✅ License is specified
- ✅ Build works correctly
- ✅ No bundled libraries that should be separate

**Common issues to fix:**

- Missing or incorrect SHA256 checksums
- Invalid MetaInfo XML
- Wrong permissions in finish-args
- Missing screenshots

## Alternative: Self-Hosting

If you want to distribute without Flathub:

### Option 1: Bundle File

Share `uim-project-manager.flatpak`:

```bash
./build-flatpak.sh
# Upload uim-project-manager.flatpak to your website/GitHub releases
```

Users install:

```bash
flatpak install uim-project-manager.flatpak
```

### Option 2: Custom Repository

Host your own Flatpak repo:

```bash
# Build and export to repo
flatpak-builder --repo=myrepo --force-clean build-dir flatpak/io.github.yourname.UIMProjectManager.json

# Upload myrepo/ directory to web server
rsync -av myrepo/ yourserver.com:/var/www/flatpak/

# Users add your repo
flatpak remote-add --user myapps https://yourserver.com/flatpak/
flatpak install myapps io.github.yourname.UIMProjectManager
```

## Testing Before Release

```bash
# Build
./build-flatpak.sh

# Test installation
flatpak run io.github.yourname.UIMProjectManager

# Test in clean environment
flatpak run --command=bash io.github.yourname.UIMProjectManager
# Then inside: uim-project-manager

# Validate desktop file
desktop-file-validate io.github.yourname.UIMProjectManager.desktop

# Validate metainfo
appstream-util validate io.github.yourname.UIMProjectManager.metainfo.xml
```

## Updating Your App

1. Make changes to source code
2. Create new release tag: `v1.1.0`
3. Update metainfo.xml with new release info
4. Update manifest with new download URL and SHA256
5. Submit new PR to Flathub (or rebuild bundle)

## Distribution Checklist

- [ ] Replace all `yourname` placeholders with your GitHub username
- [ ] Create GitHub repository and push code
- [ ] Create v1.0.0 release
- [ ] Add screenshots to repository
- [ ] Calculate SHA256 for release tarball
- [ ] Update manifest with correct URLs and checksums
- [ ] Test build locally
- [ ] Validate desktop and metainfo files
- [ ] Submit to Flathub OR create bundle for self-distribution
- [ ] Announce on Reddit, forums, social media

## Resources

- **Flathub Documentation:** https://docs.flathub.org/docs/for-app-authors/submission
- **Flatpak Builder Docs:** https://docs.flatpak.org/en/latest/flatpak-builder.html
- **AppStream Guidelines:** https://www.freedesktop.org/software/appstream/docs/
- **Flathub Quality Guidelines:** https://docs.flathub.org/docs/for-app-authors/appdata-guidelines/

## Getting Help

- **Flathub Matrix Chat:** #flathub:matrix.org
- **Flatpak Discourse:** https://discourse.flathub.org/
- **Reddit:** r/flatpak, r/linux
