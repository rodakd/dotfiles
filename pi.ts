// Pi customization — the "init.lua" equivalent.
//
// This file lives in ~/repos/dotfiles/pi.ts and is symlinked to
// ~/.pi/agent/extensions/pi.ts (auto-discovered, user scope).
// After editing, run /reload inside Pi to hot-reload the change.
//
// Vendored extensions live in pi/ (see pi/subagent/README.md — subagents).
// Docs: https://pi.dev — see extensions.md, keybindings.md, settings.md.

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	// --- Commands (slash commands) -------------------------------------------
	// Any function registered here becomes /name, usable in the editor.
	// Delete this example once you have real commands.
	pi.registerCommand("hello", {
		description: "Example command: say hello",
		handler: async (args, ctx) => {
			ctx.ui.notify(`Hello, ${args || "world"}!`, "info");
		},
	});

	// --- Shortcuts ------------------------------------------------------------
	// registerShortcut(shortcut, { description, handler }). Keys are written
	// like "ctrl+shift+p", "alt+h"; see keybindings.md for the format. Note:
	// rebinding *built-in* actions (app.*, tui.*) goes in keybindings.json,
	// not here — extensions can only add shortcuts for their own handlers.
	pi.registerShortcut("ctrl+alt+h", {
		description: "Say hello (example)",
		handler: async (ctx) => {
			ctx.ui.notify("Hello from custom.ts!", "info");
		},
	});

	// --- Tools (LLM-callable) ---------------------------------------------------
	// pi.registerTool({...}) adds a tool the model can call. Example shape:
	//
	//   import { Type } from "typebox";
	//   pi.registerTool({
	//     name: "my_tool",
	//     label: "My Tool",
	//     description: "What it does (seen by the model)",
	//     parameters: Type.Object({
	//       path: Type.String({ description: "Path to act on" }),
	//     }),
	//     async execute(toolCallId, params, signal, onUpdate, ctx) {
	//       return { content: [{ type: "text", text: "done" }], details: {} };
	//     },
	//   });

	// --- Events (the "autocmds") ------------------------------------------------
	// pi.on("session_start" | "tool_call" | "before_agent_start" | ...).
	// Return { block: true, reason } from tool_call to veto a call, e.g.:
	//
	//   pi.on("tool_call", async (event, ctx) => {
	//     if (isToolCallEventType("bash", event) && event.input.command.includes("rm -rf")) {
	//       const ok = await ctx.ui.confirm("Dangerous!", "Allow rm -rf?");
	//       if (!ok) return { block: true, reason: "Blocked by user" };
	//     }
	//   });
}