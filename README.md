# Structurizr DSL Preview in VS Code (macOS)

This project includes a `workspace.dsl` file with multiple Structurizr DSL views.  
Follow the steps below to enable diagram preview in Visual Studio Code.

---

## Requirements

- Visual Studio Code
- Java 17 or later

---

## Steps

1. **Install the required VS Code extensions**

   - Open the Command Palette (`⇧⌘P`)
   - Select `Extensions: Install Extensions`
   - Search for and install:
     - `C4 DSL Extension` (by _systemticks_)
     - `Structurizr DSL` (by _ciarant_)

2. **Configure VS Code settings**

   - Open the Command Palette → `Preferences: Open Settings (JSON)`
   - Add the following properties:
     ```json
     {
       "c4.preview.enabled": false,
       "c4.diagram.plantuml.enabled": false,
       "c4.diagram.structurizr.enabled": true,
       "c4.diagram.renderer": "structurizr"
     }
     ```

3. **Open and preview**

   - Open the `workspace.dsl` file in VS Code
   - A **Preview** action will appear above each defined view
   - Click the **Preview** link to visualize that view

4. **View all diagrams using Structurizr Lite (recommended)**

   - Ensure Docker Desktop is running
   - From the project root, run:

     ```bash
     docker run -it --rm -p 8080:8080 -v "$(pwd)":/usr/local/structurizr structurizr/lite

     ```

   - Open [http://localhost:8080](http://localhost:8080) to explore all views interactively
   - Reload the browser after editing the `.dsl` file to see updates
