# UIM Project Manager

A early version of a Linux project management application built with D language and GTK3.

## Features (Planned)

- 📋 **Project Management** - Create and organize multiple projects
- ✅ **Task Tracking** - Add, edit, and delete tasks for each project
- 🎯 **Task Status** - Track tasks as todo, in-progress, or done
- ⚡ **Priority Levels** - Set task priorities (low, medium, high)
- 📅 **Due Dates** - Track task deadlines
- 💾 **Data Persistence** - Automatically saves to JSON file
- 🎨 **Modern UI** - Clean, styled GTK interface
- 📊 **Statistics** - Real-time project and task statistics

## Screenshot

```
┌─────────────────────────────────────────────────────────┐
│ 📋 Project Manager     Projects: 3 | Tasks: 15 | Done: 8 │
├─────────────┬───────────────────────────────────────────┤
│  Projects   │              Tasks                        │
│             │                                           │
│  Website    │ ID    Task Name      Status  Priority    │
│  Mobile App │ 1     Design UI      done    high        │
│  Backend    │ 2     API Setup      in-pr   medium     │
│             │ 3     Database       todo    low         │
│             │                                           │
│  [+Project] │ [+Task] [Edit] [-Delete]                 │
├─────────────┼───────────────────────────────────────────┤
│             │           Details                         │
│             │                                           │
│             │  TASK: Design UI                          │
│             │  Status: done                             │
│             │  Priority: high                           │
│             │  Due: 2026-01-27                          │
└─────────────┴───────────────────────────────────────────┘
```

## Building

```bash
dub build
```

## Running

```bash
dub run
# or
./uim-project-manager
```

## Usage

### Creating a Project

1. Click **+ Project** button
2. Enter project name and description
3. Click **Create**

### Adding Tasks

1. Select a project from the left panel
2. Click **+ Task** button
3. Enter task details
4. Click **Save**

### Editing Tasks

1. Select a task from the task list
2. Click **Edit** button
3. Modify task details
4. Click **Save**

### Deleting Items

- Select item and click **- Delete** button
- Confirm deletion

## Data Storage

Projects and tasks are automatically saved to `projects.json` in the application directory.

## Requirements

- D compiler (DMD, LDC, or GDC)
- GTK3 development libraries
- DUB package manager

### Install GTK dependencies:

**Ubuntu/Debian:**

```bash
sudo apt-get install libgtk-3-dev
```

**Fedora:**

```bash
sudo dnf install gtk3-devel
```

**Arch:**

```bash
sudo pacman -S gtk3
```

## Architecture

- **Model:** Project and Task data structures
- **View:** GTK TreeView, TextView, and Dialog widgets
- **Controller:** Event handlers for user interactions
- **Persistence:** JSON file storage

## Future Enhancements

- [ ] Task filtering and search
- [ ] Gantt chart view
- [ ] Task dependencies
- [ ] Team collaboration features
- [ ] Time tracking
- [ ] Reports and exports
- [ ] Task comments and attachments
- [ ] Dark theme toggle
- [ ] Keyboard shortcuts

## License

MIT License
