FROM node:22-slim

WORKDIR /app

# 1. Install Git, Python, and minimal build tools.
RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 2. Put Playwright browsers in a shared, predictable location
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# 3. Install CloudCLI first, so its expected Playwright version can be determined.
RUN npm install -g @cloudcli-ai/cloudcli@latest

# 4. Install the exact Playwright version CloudCLI expects (1.64.0).
#    Installing it globally puts the binary at /usr/local/bin/playwright.
RUN npm install -g playwright@1.64.0

# 5. Install Chromium using the global Playwright CLI.
#    --with-deps also installs the required Linux libraries (libnss3, libgbm1, etc.).
RUN playwright install --with-deps chromium

# 6. Give the node user read/execute access to the browsers.
RUN chmod -R 755 /ms-playwright && chown -R node:node /ms-playwright

# 7. Install the remaining global tools.
RUN npm install -g @anthropic-ai/claude-code
RUN npm install -g task-master-ai

# --- SECURITY & PERMISSIONS FIX ---
RUN mkdir -p /workspace /home/node/.claude-code-ui/plugins /home/node/.claude && \
    chown -R node:node /app /workspace /home/node/.claude-code-ui /home/node/.claude

USER node

EXPOSE 3005

CMD ["cloudcli", "start"]