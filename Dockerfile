FROM node:22-slim

# Set the working directory
WORKDIR /app

# Install Git and Python (required for plugins and graphify)
RUN apt-get update && apt-get install -y git python3 python3-pip && rm -rf /var/lib/apt/lists/*

# Install the CloudCLI package globally
RUN npm install -g @cloudcli-ai/cloudcli@latest

# Install the Claude Code native binary globally
RUN npm install -g @anthropic-ai/claude-code

# Install TaskMaster AI globally
RUN npm install -g task-master-ai

# --- SECURITY & PERMISSIONS FIX ---
# Create necessary directories and give ownership to the 'node' user
# WE ADDED /home/node/.claude HERE TO FIX THE VOLUME PERMISSIONS
RUN mkdir -p /workspace /home/node/.claude-code-ui/plugins /home/node/.claude && \
    chown -R node:node /app /workspace /home/node/.claude-code-ui /home/node/.claude

# Switch to the non-root 'node' user (required for Claude Code)
USER node

# Expose the default port
EXPOSE 3005

# The command to run the server
CMD ["cloudcli", "start"]