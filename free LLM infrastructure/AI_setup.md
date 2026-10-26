# AI setup to a machine

Idea: infrastructure setup(docker) + free LLM instructions

the points included are:
1. nekobox installation - shell 1
2. omniroute installation - shell 2
3. claude code installation - shell 3
4. launching ./start_claude
5. vs code - shell 4
6. firefox + flatpak - in case of legacy systems

## Instructions

### 1. Nekobox
Firstly, you need to install nekobox. Install nekobox through command:

- su - && cd /home/<username>/path/to/files; chmod +x install.sh && ./install.sh && nekobox (curl -fsSL https://your-link-to-script/install.sh | bash)


### 2. Omniroute
- check if node.js version is correct(22-24). if yes, go on. (node -v)
- if not, install it in a container
- run "npm i -g omniroute"
- complete tifrst auth step
- take "bootstrap token" in the logs: sudo docker logs omniroute
- go to a consistent provider: Kiro AI
- buy some google accounts (as of free LLM instractions)
- connect each one by hand or write the script that does it automaticaclly. You should have 10-15 connections to feel confident

### 3. claude code
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

### 4. launching ./start_claude

## Legacy systems

Everything is installed through docker. there's not start claude for legacy systems.

