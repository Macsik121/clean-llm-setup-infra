## Simple problems
### Problem 1
**problem:** on running any docker comand without sudo:

permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.45/containers/json?all=1&filters=%7B%22label%22%3A%7B%22com.docker.compose.config-hash%22%3Atrue%2C%22com.docker.compose.project%3Dmobility-analytics%22%3Atrue%7D%7D": dial unix /var/run/docker.sock: connect: permission denied 

**solution:** Run these commands to grant your current user permission to access the Docker daemon socket without sudo:

Add your user to the docker group:

Bash
sudo usermod -aG docker $USER
Activate the group changes in your current terminal session:

Bash
newgrp docker
(Alternatively, log out and log back into your system.)

Verify that Docker runs without sudo:

Bash
docker ps
Troubleshooting (If the error persists)
If you still receive a permission error, fix the ownership and permissions of the Docker socket directly:

Bash
sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock

### Problem - already running omniroute instance
**problem:** I have a 20128 port running and "omniroute" container name is already taken. How do I kill both containers and run that command again?

**solution:**
Run these commands to forcefully stop and remove the conflicting containers and launch a fresh instance:

Step 1: Remove the existing container and free up port 20128
Bash
#### Force-remove the container named 'omniroute'
docker rm -f omniroute

#### Force-remove any remaining container binding port 20128
docker rm -f $(docker ps -aq --filter "publish=20128")
Step 2: Re-run the OmniRoute container
Bash
docker run -d \
  --name omniroute \
  --restart unless-stopped \
  -p 20128:20128 \
  -v omniroute-data:/app/data \
  diegosouzapw/omniroute:latest

## Legacy problems - CentOS 7

### Problem 1 - old firefox on cent os 7
**problem:** 
CentOS 7 issue: in consoe of web pages shown in the browser: Uncaught SyntaxError: expected expression, got '='

79826-ffc58e2f8b6c5a71.js:31:57237

Uncaught SyntaxError: expected property name, got '{'

8939-eb27e3e60b5c380e.js:3:1720

Uncaught SyntaxError: expected expression, got '='

66015-6d82a5132fb34c29.js:1:4138 

**solution:**
This error occurs because the browser running on CentOS 7 is too old to parse modern JavaScript (ES2020+) features—such as logical assignment (`??=`, `||=`), class field declarations, or static initialization blocks (`static {}`)—used by modern web bundles like Next.js or React.

---

### Solution 1: If You Are Viewing the Site on CentOS 7 (User Fix)

CentOS 7 reached End-of-Life (EOL) in June 2024, and its default browsers (like Firefox ESR 78/91 or old Chromium builds) lack support for modern ECMAScript standards.

* **Option A: Access from a modern OS or machine**
Open the web page using an up-to-date browser (Chrome, Firefox, Edge) on a supported operating system (Windows, macOS, or modern Linux).
* **Option B: Run a newer browser via Flatpak on CentOS 7**
If you must stay on CentOS 7, install Firefox via Flatpak to get recent JS engine updates:
```bash
sudo yum install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.mozilla.firefox
flatpak run org.mozilla.firefox

```

### Problem 2 - downloading the correct firefox tar'nik 
**problem:**
flatpak install flathub org.mozilla.firefox

error: Unable to load summary from remote flathub: URI https://dl.flathub.org/repo/summary exceeded maximum size of 10485760 bytes

**solution:**
This error occurs because the version of `flatpak` shipped with CentOS 7 has a hardcoded **10 MB (10,485,760 bytes)** download limit for repository summary files. Because Flathub has grown over time, its central `summary` metadata file now exceeds 10 MB, causing old versions of Flatpak to abort the download.

Since CentOS 7 has reached End-of-Life (EOL), the system package manager will not receive newer Flatpak updates to fix this limit. Use one of the working workarounds below.

---

### Solution 1: Install directly via `.flatpakref` (Bypasses Summary Download)

Instead of searching the full Flathub repository summary index, target the app reference file directly:

```bash
flatpak install https://dl.flathub.org/repo/appstream/org.mozilla.firefox.flatpakref

```

If prompted to select a remote or confirm runtime installation, accept default choices (`y`).

---

### Solution 2: Download Mozilla’s Portable Firefox ESR (Recommended)

The most reliable way to get a modern Firefox on CentOS 7 without using Flatpak is to download Mozilla's official standalone binary. **Firefox ESR 115** is optimized for older enterprise distributions and runs natively without system upgrades.

1. **Download and extract the portable binary:**
```bash
# Download Firefox ESR 64-bit
wget -O firefox-esr.tar.bz2 "https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=linux64&lang=en-US"

# Extract to /opt or current directory
tar -xjf firefox-esr.tar.bz2

```

2. **Launch Firefox:**
```bash
./firefox/firefox

```

*(Optional)* Create a symlink to run it globally:

```bash
sudo ln -s $(pwd)/firefox/firefox /usr/local/bin/firefox-custom
firefox-custom &

```

---

### Solution 3: Run Modern Firefox via Docker (X11 Forwarding)

Since Docker is installed on your CentOS host, run an up-to-date Firefox inside a GUI container and forward the display to your host screen:

1. **Allow local GUI connections:**
```bash
xhost +local:root

```

2. **Run Firefox in a Docker container:**
```bash
docker run -d \
  --name firefox-browser \
  --net=host \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ~/.config/firefox-docker:/config \
  jlesage/firefox

```

### Problem 3 - problems with untar'ing a file
**problem:**
tar -xjf firefox-esr.tar.bz2 

bzip2: Compressed file ends unexpectedly;

        perhaps it is corrupted?  *Possible* reason follows.

bzip2: Inappropriate ioctl for device

        Input file = (stdin), output file = (stdout)

It is possible that the compressed file(s) have become corrupted.

You can use the -tvv option to test integrity of such files.

You can use the `bzip2recover' program to attempt to recover

data from undamaged sections of corrupted files.

tar: Child returned status 2

tar: Error is not recoverable: exiting now 

**solution:**
This error occurs because the downloaded file is corrupted, incomplete, or contains an HTML error page instead of an archive. On CentOS 7, this usually happens for two reasons:

1. **Expired CA Certificates:** CentOS 7’s root certificates are outdated, causing `wget` to fail TLS handshakes silently or save an HTML SSL error page as the `.tar.bz2` file.
2. **Version Incompatibility:** Downloading the "latest" Firefox ESR alias fetches a modern version (e.g., ESR 128+) that requires `glibc >= 2.28`. CentOS 7 only supports up to `glibc 2.17`. **Firefox ESR 115** is the last release compatible with CentOS 7.

---

### Step 1: Remove the corrupted file

Verify what was downloaded and remove it:

```bash
# Check file contents (will likely show HTML or zero bytes)
file firefox-esr.tar.bz2

# Remove the bad file
rm -f firefox-esr.tar.bz2

```

---

### Step 2: Download Firefox ESR 115 directly

Use `curl` with redirect (`-L`) and insecure TLS fallback (`-k`, to bypass CentOS 7's expired certificates) to download the CentOS 7-compatible build directly from Mozilla's archive:

```bash
curl -k -L -o firefox-115.tar.bz2 "https://ftp.mozilla.org/pub/firefox/releases/115.15.0esr/linux-x86_64/en-US/firefox-115.15.0esr.tar.bz2"

```

---

### Step 3: Extract and run

Extract the archive and execute the binary:

```bash
# Extract the archive
tar -xjf firefox-115.tar.bz2

# Launch Firefox ESR 115
./firefox/firefox

```

*(Optional)* Create a symlink to run it globally from any directory:

```bash
sudo ln -sf $(pwd)/firefox/firefox /usr/local/bin/firefox-custom
firefox-custom &

```

### Problem 4 - using the wrong command of docker
**problem:**
now back to the omniroute setup.  > [2/3] RUN npm install -g omniroute:                                                                  
165.7 npm warn ERESOLVE overriding peer dependency                                                      
165.8 npm warn While resolving: marked-terminal@7.3.0                                                   
165.8 npm warn Found: marked@18.1.1                                                                     
165.8 npm warn node_modules/omniroute/node_modules/marked                                               
165.8 npm warn   marked@"^18.0.11" from omniroute@3.8.52
165.8 npm warn   node_modules/omniroute
165.8 npm warn     omniroute@"*" from the root project
165.8 npm warn   2 more (@lobehub/ui, @lobehub/streamdown)
165.8 npm warn
165.8 npm warn Could not resolve dependency:
165.8 npm warn peer marked@">=1 <16" from marked-terminal@7.3.0
165.8 npm warn node_modules/omniroute/node_modules/marked-terminal
165.8 npm warn   marked-terminal@"^7.3.0" from omniroute@3.8.52
165.8 npm warn   node_modules/omniroute
165.8 npm warn
165.8 npm warn Conflicting peer dependency: marked@15.0.12
165.8 npm warn node_modules/marked
165.8 npm warn   peer marked@">=1 <16" from marked-terminal@7.3.0
165.8 npm warn   node_modules/omniroute/node_modules/marked-terminal
165.8 npm warn     marked-terminal@"^7.3.0" from omniroute@3.8.52
165.8 npm warn     node_modules/omniroute
204.3 npm warn ERESOLVE overriding peer dependency
204.3 npm warn While resolving: @emoji-mart/react@1.1.1
204.3 npm warn Found: react@19.2.8
204.3 npm warn node_modules/omniroute/node_modules/react
204.3 npm warn   react@"19.2.8" from omniroute@3.8.52
204.3 npm warn   node_modules/omniroute
204.3 npm warn     omniroute@"*" from the root project
204.3 npm warn   165 more (@dnd-kit/core, react-dom, @dnd-kit/sortable, ...)
204.3 npm warn
204.3 npm warn Could not resolve dependency:
204.3 npm warn peer react@"^16.8 || ^17 || ^18" from @emoji-mart/react@1.1.1
204.3 npm warn node_modules/omniroute/node_modules/@lobehub/ui/node_modules/@emoji-mart/react
204.3 npm warn   @emoji-mart/react@"^1.1.1" from @lobehub/ui@5.64.4
204.3 npm warn   node_modules/omniroute/node_modules/@lobehub/ui
204.3 npm warn
204.3 npm warn Conflicting peer dependency: react@18.3.1
204.3 npm warn node_modules/react
204.3 npm warn   peer react@"^16.8 || ^17 || ^18" from @emoji-mart/react@1.1.1
204.3 npm warn   node_modules/omniroute/node_modules/@lobehub/ui/node_modules/@emoji-mart/react
204.3 npm warn     @emoji-mart/react@"^1.1.1" from @lobehub/ui@5.64.4
204.3 npm warn     node_modules/omniroute/node_modules/@lobehub/ui
241.6 npm warn deprecated prebuild-install@7.1.3: No longer maintained. Please contact the author of the relevant native addon; alternatives are available.
1054.1 npm error code ETIMEDOUT
1054.1 npm error syscall read
1054.1 npm error errno -110
1054.1 npm error network read ETIMEDOUT
1054.1 npm error network This is a problem related to network connectivity.
1054.1 npm error network In most cases you are behind a proxy or have bad network settings.
1054.1 npm error network
1054.1 npm error network If you are behind a proxy, please make sure that the 'proxy' config is set properly.  See: 'npm help config'
1054.2 npm notice
1054.2 npm notice New major version of npm available! 11.19.1 -> 12.2.1
1054.2 npm notice Changelog: https://github.com/npm/cli/releases/tag/v12.2.1
1054.2 npm notice To update run: npm install -g npm@12.2.1
1054.2 npm notice
1054.2 npm error A complete log of this run can be found in: /root/.npm/_logs/2026-10-25T04_24_54_693Z-debug-0.log
------
dockerfile:4
--------------------
   2 |     
   3 |     # Install OmniRoute globally
   4 | >>> RUN npm install -g omniroute
   5 |     
   6 |     # Expose OmniRoute default port
--------------------
ERROR: failed to solve: process "/bin/sh -c npm install -g omniroute" did not complete successfully: exit code: 146
**solution:**
The build failed with **`ETIMEDOUT` (errno -110)** because `npm` spent over 17 minutes attempting to download `omniroute` and its heavy UI dependencies (`@lobehub/ui`, React, marked, etc.) before the network connection dropped.

Additionally, npm spent extra time resolving peer dependency conflicts (the `ERESOLVE` warnings).

---

### Solution 1: Update Your Dockerfile with NPM Flags

Add flags to bypass strict peer dependency resolution, increase socket timeouts, and enable download retries:

```dockerfile
FROM node:22-slim

# Increase network timeouts and install omniroute
RUN npm config set fetch-retry-maxtimeout 600000 \
 && npm config set fetch-retries 5 \
 && npm install -g omniroute --legacy-peer-deps

EXPOSE 20128
WORKDIR /root

CMD ["omniroute"]

```

---

### Solution 2: Build Using Host Networking (Fixes CentOS 7 Docker DNS/MTU Issues)

Docker containers on CentOS 7 frequently experience slow or dropped outbound HTTP traffic due to virtual bridge DNS or MTU mismatches. Run the build command using host networking:

```bash
docker build --network=host -t omniroute-server .

```

---

### Solution 3: Use the Pre-built Official Image (Bypasses Build Entirely)

Skip `docker build` and `npm install` entirely by pulling the pre-built image directly:

```bash
docker run -d \
  --name omniroute \
  --restart unless-stopped \
  -p 20128:20128 \
  -v omniroute-data:/app/data \
  diegosouzapw/omniroute:latest

```

### Problem 5 - bootstrap token
**problem:**
seeing this (bootstrap token required) after launching omniroute in a docker container

**solution:**
This security check triggers because Docker's bridge network masks your browser request, making it appear as remote access rather than local host access.

To complete setup, retrieve the generated token from your container logs:

### Step 1: Find the Bootstrap Token

Run this command in your terminal:

```bash
docker logs omniroute

```

*(If you named your container differently, replace `omniroute` with your container's name).*

Look through the recent log lines for a line that looks like:

```text
Bootstrap token: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

```

*(or a similar long string of alphanumeric characters)*

---

### Step 2: Complete Onboarding

1. Copy the token from your terminal output.
2. Paste it into the **Bootstrap token** input box on the webpage.


3. Enter your desired password (or check *Skip password setup*).


4. Click **Retry** / submit to continue onboarding.

### Problem 6 - installing claude code on a legacy unsupported OS
**problem:**
is it possible to install claude code to cent os 7?

**solution:**
### Workaround 1: Run Claude Code inside Docker (Recommended)

Since Docker is already configured on your CentOS 7 system, the cleanest solution is to run Claude Code in a lightweight, modern container (such as Alpine or Debian) so it doesn't depend on CentOS 7's host libraries.

#### Step 1: Create a Wrapper Script

Create a shell script named `claude` (for example, in `/usr/local/bin/claude`):

```bash
sudo cat << 'EOF' > /usr/local/bin/claude
#!/usr/bin/env bash

# Mount current workspace directory and persistent Anthropic configuration
docker run -it --rm \
  -v "$(pwd)":/workspace \
  -v "$HOME/.claude":/root/.claude \
  -w /workspace \
  node:22-slim npx @anthropic-ai/claude-code@latest "$@"
EOF

sudo chmod +x /usr/local/bin/claude

```

#### Step 2: Use Claude Code

Navigate to any code repository on your server and run:

```bash
claude

```

### Problem 7 - nekobox disaster begins. can't install nekobox on my OS
**problem:**
after running a binary(and getting git repo cloned): ./nekobox: error while loading shared libraries: libQt5Network.so.5: cannot open shared object file: No such file or directory

**solution:**
This error indicates that the **Qt5 Network shared library** (`libQt5Network.so.5`) required by NekoBox is missing from your system's library search path.

Depending on whether you are running a standalone NekoBox release, an AppImage, or running on CentOS 7 / RHEL-based systems, choose the relevant fix below:

---

### Solution 1: Install system Qt5 libraries (CentOS 7 / RHEL / Fedora)

Install the required Qt5 base and network libraries via `yum`:

```bash
sudo yum install -y qt5-qtbase qt5-qtbase-gui

```

*(On Ubuntu / Debian systems, use `sudo apt install qtbase5-dev libqt5network5` instead).*

---

### Solution 2: Point to Bundled Libraries (If NekoBox includes a `lib/` folder)

If you extracted NekoBox from a `.zip` or `.tar.gz` archive, it often ships with its own `lib/` directory containing the Qt dependencies.

Run NekoBox by explicitly passing the `LD_LIBRARY_PATH`:

```bash
LD_LIBRARY_PATH=./lib ./nekobox

```

Or set the environment variable temporarily before running:

```bash
export LD_LIBRARY_PATH=$(pwd)/lib:$LD_LIBRARY_PATH
./nekobox

```

---

### Solution 3: Use the NekoBox AppImage (Recommended for CentOS 7)

If you downloaded the standalone raw binary, it might depend on host libraries that CentOS 7 lacks or has outdated versions of. Downloading the official **AppImage** bundle includes all Qt5 runtime dependencies self-contained:

1. Download the NekoBox AppImage release (v5.6.10+):
```bash
chmod +x NekoBox-*-x86_64.AppImage
./NekoBox-*-x86_64.AppImage

```


2. If CentOS 7 complains about FUSE when launching the AppImage, extract and run it directly:
```bash
./NekoBox-*-x86_64.AppImage --appimage-extract
./squashfs-root/AppRun

```

### Problem 8 - trying to run a binary successfully
**problem:**
after running appimage: PATH: /usr/lib64/qt-3.3/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/opt/jdk1.8.0_291/bin:/opt/jdk1.8.0_291/jre/bin:/home/hadoop/hadoop/sbin:/home/hadoop/hadoop/bin:/usr/local/hive/hive-3.1.2/bin:/usr/local/sqoop/sqoop-1.4.7/bin:/usr/local/flume/flume-1.9.0/bin:/home/kafka/kafka/bin:/usr/local/hbase/hbase-2.3.5/bin:/usr/local/spark3/spark-3.1.2-bin-hadoop3.2/bin:/usr/local/pig/pig-0.17.0/bin:/home/student/.local/bin:/home/student/bin

nekobox runing on: /tmp/.mount_nekorazPpbO6

/tmp/.mount_nekorazPpbO6/nekobox: error while loading shared libraries: libpng16.so.16: cannot open shared object file: No such file or directory 

**solution:**
This error happens because CentOS 7 only includes **`libpng15`** (`libpng15.so.15`) by default, whereas modern AppImages and binaries built on newer Linux distributions require **`libpng16`** (`libpng16.so.16`).

### Solution 2: Build `libpng16` from Source (Most Reliable)

If the symlink fails or causes a symbol mismatch error, compile `libpng16` natively on your CentOS 7 system. It takes less than two minutes:

1. **Install build tools:**
```bash
sudo yum install -y gcc make zlib-devel wget

```


2. **Download, compile, and install `libpng 1.6`:**
```bash
wget https://sourceforge.net/projects/libpng/files/libpng16/1.6.40/libpng-1.6.40.tar.gz
tar -xzf libpng-1.6.40.tar.gz
cd libpng-1.6.40

./configure --prefix=/usr --libdir=/usr/lib64
make -j$(nproc)
sudo make install

```


3. **Update system library cache:**
```bash
sudo ldconfig

```

### Problem 9, 10 - dealing with wrong naming(links) in Dockerfile.nekoray
**problem:**
...
**solution:**
...


### Problem 11 - another time running nekoray and facing another instance
**problem:**
docker: Error response from daemon: Conflict. The container name "/nekoray" is already in use by container "94af9e08958f059c78a1729079b58956ad96990709c0eceea304d66ee008dc5d". You have to remove (or rename) that container to be able to reuse that name.

**solution:**
Remove the previous container instance using `docker rm -f`, then launch it again:

```bash
# Force-remove the existing container
docker rm -f nekoray

# Ensure X11 display permissions are active
xhost +local:root

# Run the updated container
docker run -d \
  --name nekoray \
  --net=host \
  --privileged \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ~/.config/nekoray:/root/.config/nekoray \
  nekoray-ui

```

### Problem 12 - adding some more dependencies to have all the necessary programms together working
**problem:**
I miscommunicated. Here's what I get instead of a GUI: sudo docker rm -f nekoray && xhost +local:root && sudo docker run -d   --name nekoray   --net=host   --privileged   -e DISPLAY=$DISPLAY   -v /tmp/.X11-unix:/tmp/.X11-unix   -v ~/.config/nekoray:/root/.config/nekoray   nekoray-ui

nekoray

non-network local connections being added to access control list

6f982038cc7a267e112d4c3dab248d7e1e8fd8a868cfa771195c159cc63c5599 
**solution:**

```bash
sudo docker logs nekoray

```

*(You will likely see an error like `qt.qpa.plugin: Could not load the Qt platform plugin "xcb"` or `Could not connect to display :0`).*

---

### Step 2: Update `Dockerfile.nekoray` with Full XCB GUI Dependencies

Qt requires additional `libxcb` libraries in headless container base images to render GUI windows. Update your `Dockerfile.nekoray` to include them:

```dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Qt5, XCB, and required GUI libraries
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    libqt5widgets5 \
    libqt5network5 \
    libqt5gui5 \
    libqt5core5a \
    libqt5svg5 \
    libqt5x11extras5 \
    libgl1-mesa-glx \
    libfontconfig1 \
    ca-certificates \
    libxcb-xinerama0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-randr0 \
    libxcb-xfixes0 \
    libx11-xcb1 \
    libdbus-1-3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# Download, extract NekoRay, and ensure executable permissions
RUN wget https://github.com/MatsuriDayo/nekoray/releases/download/4.0.1/nekoray-4.0.1-2024-12-12-linux64.zip \
    && unzip nekoray-4.0.1-2024-12-12-linux64.zip \
    && rm nekoray-4.0.1-2024-12-12-linux64.zip \
    && chmod +x /opt/nekoray/nekobox

CMD ["/opt/nekoray/nekobox"]

```

---

### Step 3: Rebuild and Run Interactively

1. **Rebuild the image:**
```bash
sudo docker build -f Dockerfile.nekoray -t nekoray-ui .

```


2. **Grant X11 permissions for `root`:**
```bash
xhost +local:root

```


3. **Run the container without `-d` (interactive mode):**
Running without `-d` allows you to see startup output directly in your terminal if any issue remains.
```bash
sudo docker rm -f nekoray

sudo docker run -it \
  --name nekoray \
  --net=host \
  --privileged \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ~/.config/nekoray:/root/.config/nekoray \
  nekoray-ui

```

### Problem 13 - failing to install neko again
**problem:**
=> CACHED [2/4] RUN apt-get update && apt-get install -y     wget     unzip     libqt5widgets5     libqt5netw  0.0s

=> CACHED [3/4] WORKDIR /opt                                                                                   0.0s

=> CACHED [4/4] RUN wget https://github.com/MatsuriDayo/nekoray/releases/download/4.0.1/nekoray-4.0.1-2024-12  0.0s

=> exporting to image                                                                                          0.0s

=> => exporting layers                                                                                         0.0s

=> => writing image sha256:2e13da36d4323a46a15185e9ba32f7e50cc62f04a209b6cdb2bd5e4cdda76a48                    0.0s

=> => naming to docker.io/library/nekoray-ui                                                                   0.0s

non-network local connections being added to access control list

40f2a82a4b20740b6dd63c05db9f7a8e91f11c35f3cf80a8fe04270bf3f6643 
**solution:**
The GUI is not appearing because running in detached mode (`-d`) hides startup crashes, and using `sudo` often wipes the host's `$DISPLAY` environment variable.

Run these steps to diagnose and fix the startup:

### Step 1: Check the container's exit logs

Run this command to see the exact runtime error that caused `nekobox` to fail or exit:

```bash
sudo docker logs nekoray

```

---

### Step 2: Fix the `$DISPLAY` variable under `sudo`

When you run `sudo docker run -e DISPLAY=$DISPLAY`, `sudo` strips your user's environment variables, turning `$DISPLAY` into an empty string inside the container.

Run the container interactively while explicitly passing the host's `DISPLAY` variable and removing the old container:

```bash
# 1. Clean up the failed container
sudo docker rm -f nekoray

# 2. Grant X11 permissions
xhost +local:root

# 3. Preserve $DISPLAY explicitly while running interactively (without -d)
sudo DISPLAY=$DISPLAY docker run -it --rm \
  --name nekoray \
  --net=host \
  --privileged \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ~/.config/nekoray:/root/.config/nekoray \
  nekoray-ui

```

If the window still does not open, terminal output will print the missing Qt plugin or X11 error directly to your console.

### Problem 14 - adding more dependencies to the container
**problem:**
Yes, i ran the commands above. still: /opt/nekoray/nekobox: error while loading shared libraries: libQt5Core.so.5: cannot open shared object file: No such file or directory
**solution:**
This error occurs because CentOS 7 uses Linux **Kernel 3.10**, whereas Ubuntu 22.04's `libQt5Core.so.5` contains a embedded kernel version header (`.note.ABI-tag`) requiring **Kernel 3.17+**. When `glibc` inside the container checks the host's 3.10 kernel, it refuses to load `libQt5Core.so.5` and throws the misleading `cannot open shared object file` message.

You can bypass this check by stripping the `.note.ABI-tag` section from `libQt5Core.so.5` during the container build.

---

### Step 1: Update `Dockerfile.nekoray`

Add `binutils` to `apt-get` and include the `strip` command:

```dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Qt5, XCB, binutils, and dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    binutils \
    libqt5widgets5 \
    libqt5network5 \
    libqt5gui5 \
    libqt5core5a \
    libqt5svg5 \
    libqt5x11extras5 \
    libgl1-mesa-glx \
    libfontconfig1 \
    ca-certificates \
    libxcb-xinerama0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-randr0 \
    libxcb-xfixes0 \
    libx11-xcb1 \
    libdbus-1-3 \
    && rm -rf /var/lib/apt/lists/*

# Bypass kernel 3.10 compatibility check on CentOS 7
RUN strip --remove-section=.note.ABI-tag /usr/lib/x86_64-linux-gnu/libQt5Core.so.5

WORKDIR /opt

# Download, extract NekoRay, and ensure executable permissions
RUN wget https://github.com/MatsuriDayo/nekoray/releases/download/4.0.1/nekoray-4.0.1-2024-12-12-linux64.zip \
    && unzip nekoray-4.0.1-2024-12-12-linux64.zip \
    && rm nekoray-4.0.1-2024-12-12-linux64.zip \
    && chmod +x /opt/nekoray/nekobox

CMD ["/opt/nekoray/nekobox"]

```

---

### Step 2: Rebuild & Run

1. **Rebuild the Docker image:**
```bash
sudo docker build -f Dockerfile.nekoray -t nekoray-ui .

```


2. **Grant local root display access:**
```bash
xhost +local:root

```


3. **Launch the container:**
```bash
sudo DISPLAY=$DISPLAY docker run -it --rm \
  --name nekoray \
  --net=host \
  --privileged \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ~/.config/nekoray:/root/.config/nekoray \
  nekoray-ui

```

### Problem 15 - philosiphising...
**problem:**
How do I use this container? docker: Error response from daemon: Conflict. The container name "/nekoray" is already in use by container "727d7340e43df2f1b77870c07122a5a75fb675fd2d3752270a51f34e2784fcb3". You have to remove (or rename) that container to be able to reuse that name. 
**solution:**
To resolve this error, you have three options depending on whether you want to start fresh, reuse the existing container, or run a new copy alongside it.

### Method 1: Remove the old container and start fresh (Recommended)

Force-remove the stopped container with `docker rm -f`, then run your command with the `--rm` flag added so Docker automatically cleans up the container name whenever it exits:

```bash
sudo docker rm -f nekoray

xhost +local:root

sudo DISPLAY=$DISPLAY docker run -it --rm \
  --name nekoray \
  --net=host \
  --privileged \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ~/.config/nekoray:/root/.config/nekoray \
  nekoray-ui

```

---

### Method 2: Start the existing container

If you want to reuse the exact container instance that was already created:

```bash
sudo docker start nekoray

```

---

### Method 3: Run with a different container name

If you want to keep the old container around and launch a new one, change the `--name` argument:

```bash
sudo DISPLAY=$DISPLAY docker run -it --rm \
  --name nekoray-gui \
  --net=host \
  --privileged \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ~/.config/nekoray:/root/.config/nekoray \
  nekoray-ui

```

### Problem 16 - nekobox issues on running servers

The `configure tun interface: device or resource busy` error means a virtual TUN interface (like `tun0` or `nekoray-tun`) is locked on your host system, usually because a previous container run or lingering `sing-box` core process was killed without cleanly releasing the network interface.

---

### Step 1: Kill Lingering Proxy Processes

Run this on your CentOS host to stop any background cores still holding onto `/dev/net/tun`:

```bash
sudo pkill -f sing-box
sudo pkill -f nekobox

```

---

### Step 2: Delete the Stale TUN Interface

Check if a stale TUN interface exists on the host and remove it:

1. **Find active TUN interfaces:**
```bash
ip link show | grep tun

```


2. **Delete the busy interface** (replace `tun0` or `nekoray-tun` with whatever interface appears in the step above):
```bash
sudo ip link delete tun0
# or
sudo ip link delete nekoray-tun

```

---

### Step 3: Run Docker with the Host TUN Device explicitly mounted

Add `-v /dev/net/tun:/dev/net/tun` to your `docker run` command to ensure the container directly accesses host networking devices:

```bash
# Clean up any lingering container
sudo docker rm -f nekoray

# Allow local root X11 access
xhost +local:root

# Run NekoBox with TUN device forwarding
sudo DISPLAY=$DISPLAY docker run -it --rm \
  --name nekoray \
  --net=host \
  --privileged \
  -e DISPLAY=$DISPLAY \
  -v /dev/net/tun:/dev/net/tun \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ~/.config/nekoray:/root/.config/nekoray \
  nekoray-ui

```

---

### Step 4: Quick Workaround (Use System Proxy instead of TUN Mode)

If you don't specifically need system-wide VPN routing (TUN mode), uncheck **TUN Mode** in NekoBox and check **System Proxy** instead. System Proxy routes web browsers via local HTTP/SOCKS ports without creating host TUN network devices.


### Problem 17 - mismatched port for nekobox in docker container and firefox proxy while searching in tha web
**problem:**
for some reason, specifically on my system, nekobox doesn't want to work. It loads the servers as vless keys correctly. It runs URL Test correctly. When I choose one of the working servers and check the TUN mode and System proxy mode, it shows on the right bottom the running indicator. But the traffic itself doesn't go. It just deadly shows proxy: 0 B up, 0 B down; direct: 0 B up, 0 B down. What can be the problem? I'm talking about the nekobox set up in the docker container. Maybe we should somehow tweaks the container himself? 

**solution:**
There are two separate reasons why traffic isn't moving, depending on which mode you are using.

---

### Cause 1: System Proxy Mode Doesn't Automatically Affect Your Host

When you check **System Proxy** inside a Docker container, NekoBox tries to modify the desktop proxy settings *inside* the Ubuntu container (which has no desktop manager). It cannot reach out and automatically set the proxy settings of your CentOS 7 host desktop.

#### Solution: Point host apps manually to NekoBox's port

1. In NekoBox, check your inbound port under **Program** $\rightarrow$ **Preferences** $\rightarrow$ **Inbound Settings** (by default, HTTP is `2080` and SOCKS5 is `2081`).
2. On your CentOS host:
* **Firefox:** Go to Settings $\rightarrow$ Network Settings $\rightarrow$ Manual proxy configuration $\rightarrow$ HTTP Proxy: `127.0.0.1`, Port: `2080`.
* **Terminal:** Run `export http_proxy="[http://127.0.0.1:2080](http://127.0.0.1:2080)" https_proxy="[http://127.0.0.1:2080](http://127.0.0.1:2080)"` before executing commands.



---

### Cause 2: TUN Mode Fails on CentOS 7's Kernel 3.10

TUN mode relies on `sing-box` manipulating Linux routing tables and firewall rules. On CentOS 7:

1. The container lacks `iptables` and `iproute2` utilities required to set up routes.
2. The default TUN network stack (`system`) requires modern kernel features unavailable in Linux 3.10.

#### Step 1: Update `Dockerfile.nekoray` with routing utilities

Add `iptables` and `iproute2` to your Dockerfile:

```dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Qt5, XCB, routing tools, and dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    binutils \
    iptables \
    iproute2 \
    libqt5widgets5 \
    libqt5network5 \
    libqt5gui5 \
    libqt5core5a \
    libqt5svg5 \
    libqt5x11extras5 \
    libgl1-mesa-glx \
    libfontconfig1 \
    ca-certificates \
    libxcb-xinerama0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-randr0 \
    libxcb-xfixes0 \
    libx11-xcb1 \
    libdbus-1-3 \
    && rm -rf /var/lib/apt/lists/*

# Bypass kernel 3.10 compatibility check on CentOS 7
RUN strip --remove-section=.note.ABI-tag /usr/lib/x86_64-linux-gnu/libQt5Core.so.5

WORKDIR /opt

# Download, extract NekoRay, and ensure executable permissions
RUN wget https://github.com/MatsuriDayo/nekoray/releases/download/4.0.1/nekoray-4.0.1-2024-12-12-linux64.zip \
    && unzip nekoray-4.0.1-2024-12-12-linux64.zip \
    && rm nekoray-4.0.1-2024-12-12-linux64.zip \
    && chmod +x /opt/nekoray/nekobox

CMD ["/opt/nekoray/nekobox"]

```

Rebuild the image:

```bash
sudo docker build -f Dockerfile.nekoray -t nekoray-ui .

```

---

#### Step 2: Enable IPv4 Forwarding on CentOS Host

Run this on your CentOS terminal to allow the host kernel to route TUN packets:

```bash
sudo sysctl -w net.ipv4.ip_forward=1

```

---

#### Step 3: Switch TUN Stack to `gVisor` in NekoBox

Because Kernel 3.10 lacks modern eBPF/TPROXY networking features, you must force NekoBox to use **gVisor** (a userspace network stack):

1. Open NekoBox GUI.
2. Go to **Program** $\rightarrow$ **Preferences** (or **Core Settings**).
3. Under **TUN Settings** / **TUN Implementation**, change the **Stack** setting from `System` or `Auto` to **`gVisor`**.
4. Click **OK** / Save.
5. Restart your proxy connection and re-enable **TUN Mode**.

Once set to `gVisor` with forwarding enabled on the host, traffic will start recording in the `proxy:` status bar.


### Problem 
**problem:**

**solution:**


### Problem 
**problem:**

**solution:**


### Problem 
**problem:**

**solution:**

