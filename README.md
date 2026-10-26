# Codux — Claude Code & FreeLLMAPI Pipeline

A complete **Docker-based development environment** that runs a local AI pipeline for Claude Code, featuring intelligent LLM routing, a web UI, and persistent configuration — all orchestrated via Docker Compose and ready for VS Code Dev Containers.

---

## 🏗 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Codux Pipeline                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐       │
│  │  CloudCLI    │────▶│   LiteLLM    │────▶│  OmniRoute   │       │
│  │  (Web UI)    │     │   Proxy      │     │  (Router)    │       │
│  │  Port 3005   │     │  Port 4000   │     │ Port 20128   │       │
│  └──────────────┘     └──────────────┘     └──────┬───────┘       │
│                                                    │               │
│                                                    ▼               │
│                                            ┌──────────────┐       │
│                                            │ FreeLLMAPI   │       │
│                                            │  Port 3001   │       │
│                                            └──────────────┘       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| **CloudCLI** | `kalmux/codux:latest` (built locally) | 3005 | Web UI for Claude Code with plugin support |
| **LiteLLM** | `ghcr.io/berriai/litellm:main-stable` | 4000 | LLM proxy with fallback routing |
| **OmniRoute** | `diegosouzapw/omniroute:latest` | 20128 | Intelligent auto-router (`openai/auto/coding`) |
| **FreeLLMAPI** | `ghcr.io/tashfeenahmed/freellmapi:latest` | 3001 | Local LLM API backend |

---

## 🚀 Quick Start

### Prerequisites

- **Docker** & **Docker Compose** v2+
- **Git** (for cloning)
- (Optional) **VS Code** with **Dev Containers** extension

### 1. Clone & Configure

```bash
git clone https://github.com/kalmux1/Codux.git
cd Codux

# Copy environment template and fill in your values
cp .env.example .env
# Edit .env with your actual keys
```

### 2. Required Environment Variables

Edit `.env` with your credentials:

```bash
# Copy this file to .env and fill in real values

# --- FreeLLMAPI ---
ENCRYPTION_KEY=your-encryption-key
PORT=3001
FREELLMAPI_API_KEY=your-freellmapi-api-key

# --- OmniRoute (Required for the config you pasted) ---
# 1. This is the password you will use to log into OmniRoute for the first time.
OMNIROUTE_INITIAL_PASSWORD=your-omniroute-password

# --- LiteLLM ---
LITELLM_MASTER_KEY=sk-your-master-key


# 2. Go to http://localhost:20128 after starting the containers, log in, 
#    generate an API key, and paste it here:
OMNIROUTE_API_KEY=your-omniroute-api-key


# --- CloudCLI UI Login ---
# These are the credentials you will use to log into the Web UI at localhost:3005
CLOUDCLI_USERNAME=your-cloudcli-username
CLOUDCLI_PASSWORD=your-cloudcli-password
```

### 3. Start the Pipeline

```bash
# Build and start all services
docker compose up -d --build

# View logs
docker compose logs -f

# Stop
docker compose down
```

### 4. Access the UI

Open **http://localhost:3005** in your browser and log in with:
- Username: `admin` (from `CLOUDCLI_USERNAME`)
- Password: from `CLOUDCLI_PASSWORD`

---

## 🐳 VS Code Dev Container (Recommended)

This repo includes a **Dev Container** configuration for the best experience:

1. Open the repo in VS Code
2. Press `F1` → **Dev Containers: Reopen in Container**
3. The container will:
   - Build the CloudCLI image
   - Start all pipeline services
   - Install **Claude Code** CLI + **CloudCLI** globally
   - Mount `./Codux-Projects` as `/workspace`
   - Persist Claude config to `cloudcli-claude-data` volume

Once inside, you have:
- `claude` — Claude Code CLI
- `cloudcli` — CloudCLI server
- `task-master-ai` — Task Master AI

---

## 📁 Project Structure

```
Codux/
├── .devcontainer.json        # VS Code Dev Container config
├── .dockerignore
├── .env.example              # Environment template
├── .gitignore
├── Dockerfile                # CloudCLI image (Node 22 + Claude Code + CloudCLI + TaskMaster)
├── docker-compose.yml        # Full pipeline orchestration
├── litellm-config.yaml       # LiteLLM routing config (OmniRoute → OpenAI fallback)
├── .github/
│   └── workflows/
│       └── build-push.yml    # Auto-build & push to GHCR on push to main
└── Codux-Projects/           # Your projects (mounted to /workspace in container)
```

---

## 🔧 Configuration Details

### LiteLLM Routing (`litellm-config.yaml`)

```yaml
model_list:
  # Primary: OmniRoute intelligent auto-router
  - model_name: "claude-sonnet-4-6"
    litellm_params:
      model: "openai/auto/coding"
      api_base: "http://omniroute:20128/v1"
      api_key: os.environ/OMNIROUTE_API_KEY

  # Alias for Opus requests
  - model_name: "claude-opus-5-5"
    litellm_params:
      model: "openai/auto/coding"
      api_base: "http://omniroute:20128/v1"
      api_key: os.environ/OMNIROUTE_API_KEY

  # Direct OpenAI fallback
  - model_name: "direct-openai-fallback"
    litellm_params:
      model: "openai/gpt-4o"
      api_key: os.environ/OPENAI_API_KEY

litellm_settings:
  fallbacks: [{"claude-sonnet-4-6": ["direct-openai-fallback"]}]
```

### CloudCLI Environment (in `docker-compose.yml`)

```yaml
environment:
  - ANTHROPIC_BASE_URL=http://litellm:4000
  - ANTHROPIC_API_KEY=${LITELLM_MASTER_KEY}
  - ANTHROPIC_MODEL=claude-sonnet-4-6
  - WORKSPACES_ROOT=/workspace
  - CLAUDE_CONFIG_DIR=/home/node/.claude
  - TWENTYFIRST_API_KEY=${TWENTYFIRST_API_KEY:-}
```

---

## 🔐 Security Notes

- All services bind to `127.0.0.1` (localhost only) by default
- Change port bindings in `docker-compose.yml` if exposing externally
- Use strong passwords for `OMNIROUTE_INITIAL_PASSWORD`, `CLOUDCLI_PASSWORD`
- Generate `ENCRYPTION_KEY` with: `openssl rand -hex 32`
- The `LITELLM_MASTER_KEY` is used as the Anthropic API key for CloudCLI

---

## 📦 Persistent Data

Docker volumes (survive container restarts):

| Volume | Purpose |
|--------|---------|
| `freellmapi-data` | FreeLLMAPI database |
| `omniroute-data` | OmniRoute configuration & memory |
| `cloudcli-plugins` | CloudCLI installed plugins |
| `cloudcli-claude-data` | Claude Code config (`~/.claude`) |

Projects are stored in `./Codux-Projects` (bind-mounted to `/workspace`).

---

## 🔄 CI/CD

**GitHub Actions** (`.github/workflows/build-push.yml`):
- Triggers on push to `main`
- Builds Docker image from `Dockerfile`
- Pushes to **GHCR** (`ghcr.io/kalmux1/codux:latest` and `:<sha>`)

To use the pre-built image:
```bash
# In docker-compose.yml, change:
#   cloudcli:
#     build: .
#     image: kalmux/codux:latest
# To:
#   cloudcli:
#     image: ghcr.io/kalmux1/codux:latest
```

---

## 🛠 Troubleshooting

| Issue | Solution |
|-------|----------|
| Port conflicts | Change host ports in `docker-compose.yml` (left side of `:` in `ports`) |
| Permission errors on volumes | Run `sudo chown -R 1000:1000 ./Codux-Projects` |
| OmniRoute not starting | Check `OMNIROUTE_INITIAL_PASSWORD` is set; view logs: `docker compose logs omniroute` |
| LiteLLM 401 errors | Verify `OMNIROUTE_API_KEY` matches OmniRoute config |
| CloudCLI can't connect | Ensure `LITELLM_MASTER_KEY` in `.env` matches `ANTHROPIC_API_KEY` in compose |

---

## 📚 Related Repositories

- **FreeLLMAPI**: https://github.com/tashfeenahmed/freellmapi
- **OmniRoute**: https://github.com/diegosouzapw/omniroute
- **LiteLLM**: https://github.com/BerriAI/litellm
- **CloudCLI**: https://github.com/cloudcli-ai/cloudcli
- **Claude Code**: https://github.com/anthropics/claude-code

---

## 📄 License

MIT — See individual component licenses for their respective terms.

---

## 🤝 Contributing

PRs welcome! Please:
1. Fork the repo
2. Create a feature branch
3. Test with `docker compose up --build`
4. Submit a PR

---

**Built for local-first AI development with Claude Code.** 🚀