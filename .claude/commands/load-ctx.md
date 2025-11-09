---
description: Load project context from .claude.ctx file
---

Load and display the project context from the `.claude.ctx` file to initialize your understanding of this project.

## Instructions

1. **Read the context file**:
   - Use the `Read` tool to read the `.claude.ctx` file
   - This file contains comprehensive project documentation

2. **Present the context**:
   - Provide a concise summary of the key information from the context file
   - Highlight the most important sections:
     - Project overview
     - Current configuration (products, modules, tools count)
     - Recent changes and implementations
     - Key files and their purposes

3. **Confirm readiness**:
   - Inform the user that you've loaded the project context
   - Let them know you're ready to help with development tasks

## Context File Location

The project context is stored in `.claude.ctx` at the project root. This file includes:
- Project structure and organization
- Configuration details for products, modules, and tools
- GitHub API integration details
- Type definitions and dashboard implementation
- Development guidelines and workflows
- Recent implementation changes

## Usage

This command is useful when:
- Starting a new Claude Code session
- Need to quickly understand the project structure
- Want to review recent changes
- Need to reference implementation details

## Note

If the `.claude.ctx` file doesn't exist or is outdated, use the `/init-ctx` command to generate or refresh it.
