module app;

import gtk.Main;
import gtk.MainWindow;
import gtk.Box;
import gtk.Paned;
import gtk.Button;
import gtk.Label;
import gtk.Entry;
import gtk.TextView;
import gtk.TextBuffer;
import gtk.ScrolledWindow;
import gtk.TreeView;
import gtk.TreeStore;
import gtk.TreeIter;
import gtk.TreePath;
import gtk.TreeViewColumn;
import gtk.CellRendererText;
import gtk.CellRendererCombo;
import gtk.ListStore;
import gtk.Dialog;
import gtk.MessageDialog;
import gtk.Calendar;
import gtk.CssProvider;
import gtk.StyleContext;
import gdk.Screen;
import gtk.c.types;
import glib.Timeout;

import std.stdio;
import std.conv;
import std.datetime;
import std.array;
import std.algorithm;
import std.json;
import std.file;

// Data models
struct Task
{
    string id;
    string name;
    string description;
    string status; // "todo", "in-progress", "done"
    string priority; // "low", "medium", "high"
    Date dueDate;
    Date createdDate;
}

struct Project
{
    string id;
    string name;
    string description;
    Task[] tasks;
    Date createdDate;
}

class ProjectManagerApp
{
    private MainWindow window;
    private TreeView projectTreeView;
    private TreeStore projectTreeStore;
    private TreeView taskTreeView;
    private ListStore taskListStore;
    private TextView detailsView;
    private TextBuffer detailsBuffer;
    
    private Project[] projects;
    private Project* currentProject;
    private int projectIdCounter = 0;
    private int taskIdCounter = 0;
    
    this()
    {
        loadData();
        applyTheme();
        setupUI();
    }
    
    private void setupUI()
    {
        window = new MainWindow("UIM Project Manager");
        window.setDefaultSize(1200, 700);
        window.addOnDestroy((widget) { 
            saveData();
            Main.quit(); 
        });
        
        // Main container
        auto mainBox = new Box(GtkOrientation.VERTICAL, 0);
        
        // Toolbar
        auto toolbar = createToolbar();
        mainBox.packStart(toolbar, false, false, 0);
        
        // Content area with paned layout
        auto paned = new Paned(GtkOrientation.HORIZONTAL);
        
        // Left panel - Projects
        auto leftBox = new Box(GtkOrientation.VERTICAL, 5);
        leftBox.setMarginTop(10);
        leftBox.setMarginBottom(10);
        leftBox.setMarginStart(10);
        leftBox.setMarginEnd(5);
        
        auto projectLabel = new Label("<b>Projects</b>");
        projectLabel.setUseMarkup(true);
        projectLabel.setXalign(0);
        leftBox.packStart(projectLabel, false, false, 0);
        
        auto projectScroll = new ScrolledWindow();
        projectTreeView = createProjectTreeView();
        projectScroll.add(projectTreeView);
        leftBox.packStart(projectScroll, true, true, 0);
        
        auto projectButtons = new Box(GtkOrientation.HORIZONTAL, 5);
        auto addProjectBtn = new Button("+ Project");
        addProjectBtn.addOnClicked(&onAddProject);
        auto delProjectBtn = new Button("- Delete");
        delProjectBtn.addOnClicked(&onDeleteProject);
        projectButtons.packStart(addProjectBtn, true, true, 0);
        projectButtons.packStart(delProjectBtn, true, true, 0);
        leftBox.packStart(projectButtons, false, false, 5);
        
        paned.add1(leftBox);
        
        // Right panel - Tasks and Details
        auto rightPaned = new Paned(GtkOrientation.VERTICAL);
        
        // Tasks section
        auto taskBox = new Box(GtkOrientation.VERTICAL, 5);
        taskBox.setMarginTop(10);
        taskBox.setMarginBottom(5);
        taskBox.setMarginStart(5);
        taskBox.setMarginEnd(10);
        
        auto taskLabel = new Label("<b>Tasks</b>");
        taskLabel.setUseMarkup(true);
        taskLabel.setXalign(0);
        taskBox.packStart(taskLabel, false, false, 0);
        
        auto taskScroll = new ScrolledWindow();
        taskTreeView = createTaskTreeView();
        taskScroll.add(taskTreeView);
        taskBox.packStart(taskScroll, true, true, 0);
        
        auto taskButtons = new Box(GtkOrientation.HORIZONTAL, 5);
        auto addTaskBtn = new Button("+ Task");
        addTaskBtn.addOnClicked(&onAddTask);
        auto editTaskBtn = new Button("Edit");
        editTaskBtn.addOnClicked(&onEditTask);
        auto delTaskBtn = new Button("- Delete");
        delTaskBtn.addOnClicked(&onDeleteTask);
        taskButtons.packStart(addTaskBtn, true, true, 0);
        taskButtons.packStart(editTaskBtn, true, true, 0);
        taskButtons.packStart(delTaskBtn, true, true, 0);
        taskBox.packStart(taskButtons, false, false, 5);
        
        rightPaned.add1(taskBox);
        
        // Details section
        auto detailsBox = new Box(GtkOrientation.VERTICAL, 5);
        detailsBox.setMarginTop(5);
        detailsBox.setMarginBottom(10);
        detailsBox.setMarginStart(5);
        detailsBox.setMarginEnd(10);
        
        auto detailsLabel = new Label("<b>Details</b>");
        detailsLabel.setUseMarkup(true);
        detailsLabel.setXalign(0);
        detailsBox.packStart(detailsLabel, false, false, 0);
        
        auto detailsScroll = new ScrolledWindow();
        detailsView = new TextView();
        detailsView.setEditable(false);
        detailsView.setWrapMode(GtkWrapMode.WORD);
        detailsBuffer = detailsView.getBuffer();
        detailsScroll.add(detailsView);
        detailsBox.packStart(detailsScroll, true, true, 0);
        
        rightPaned.add2(detailsBox);
        rightPaned.setPosition(350);
        
        paned.add2(rightPaned);
        paned.setPosition(300);
        
        mainBox.packStart(paned, true, true, 0);
        
        // Status bar
        auto statusBar = new Label("Ready");
        statusBar.setXalign(0);
        statusBar.setMarginStart(10);
        statusBar.setMarginEnd(10);
        statusBar.setMarginTop(5);
        statusBar.setMarginBottom(5);
        mainBox.packStart(statusBar, false, false, 0);
        
        window.add(mainBox);
        window.showAll();
        
        refreshProjectTree();
    }
    
    private Box createToolbar()
    {
        auto toolbar = new Box(GtkOrientation.HORIZONTAL, 10);
        toolbar.setMarginTop(10);
        toolbar.setMarginBottom(10);
        toolbar.setMarginStart(10);
        toolbar.setMarginEnd(10);
        
        auto titleLabel = new Label("<big><b>📋 Project Manager</b></big>");
        titleLabel.setUseMarkup(true);
        toolbar.packStart(titleLabel, false, false, 0);
        
        // Spacer
        auto spacer = new Label("");
        toolbar.packStart(spacer, true, true, 0);
        
        auto statsLabel = new Label("");
        updateStats(statsLabel);
        toolbar.packStart(statsLabel, false, false, 0);
        
        return toolbar;
    }
    
    private void updateStats(Label statsLabel)
    {
        int totalTasks = 0;
        int completedTasks = 0;
        
        foreach (proj; projects)
        {
            totalTasks += proj.tasks.length;
            completedTasks += proj.tasks.count!(t => t.status == "done");
        }
        
        statsLabel.setMarkup(
            "<span foreground='#7f8c8d'>" ~
            "Projects: <b>" ~ projects.length.to!string ~ "</b> | " ~
            "Tasks: <b>" ~ totalTasks.to!string ~ "</b> | " ~
            "Completed: <b>" ~ completedTasks.to!string ~ "</b>" ~
            "</span>"
        );
    }
    
    private TreeView createProjectTreeView()
    {
        projectTreeStore = new TreeStore([GType.STRING, GType.STRING]);
        auto treeView = new TreeView(projectTreeStore);
        
        auto column = new TreeViewColumn();
        column.setTitle("Project");
        auto renderer = new CellRendererText();
        column.packStart(renderer, true);
        column.addAttribute(renderer, "text", 0);
        treeView.appendColumn(column);
        
        treeView.addOnCursorChanged(&onProjectSelected);
        
        return treeView;
    }
    
    private TreeView createTaskTreeView()
    {
        // Columns: ID, Name, Status, Priority, Due Date
        taskListStore = new ListStore([GType.STRING, GType.STRING, GType.STRING, GType.STRING, GType.STRING]);
        auto treeView = new TreeView(taskListStore);
        
        string[] columns = ["ID", "Task Name", "Status", "Priority", "Due Date"];
        foreach (i, colName; columns)
        {
            auto column = new TreeViewColumn();
            column.setTitle(colName);
            auto renderer = new CellRendererText();
            column.packStart(renderer, true);
            column.addAttribute(renderer, "text", cast(int)i);
            column.setResizable(true);
            
            if (i == 1) column.setMinWidth(200); // Task name wider
            
            treeView.appendColumn(column);
        }
        
        treeView.addOnCursorChanged(&onTaskSelected);
        
        return treeView;
    }
    
    private void onProjectSelected(TreeView tv)
    {
        auto selection = tv.getSelection();
        TreeIter iter = selection.getSelected();
        if (iter)
        {
            string projectId = projectTreeStore.getValue(iter, 1).getString();
            
            foreach (ref proj; projects)
            {
                if (proj.id == projectId)
                {
                    currentProject = &proj;
                    refreshTaskList();
                    showProjectDetails(proj);
                    break;
                }
            }
        }
    }
    
    private void onTaskSelected(TreeView tv)
    {
        auto selection = tv.getSelection();
        TreeIter iter = selection.getSelected();
        if (iter)
        {
            string taskId = taskListStore.getValue(iter, 0).getString();
            
            if (currentProject)
            {
                foreach (task; currentProject.tasks)
                {
                    if (task.id == taskId)
                    {
                        showTaskDetails(task);
                        break;
                    }
                }
            }
        }
    }
    
    private void refreshProjectTree()
    {
        projectTreeStore.clear();
        
        foreach (proj; projects)
        {
            TreeIter iter = projectTreeStore.createIter();
            projectTreeStore.setValue(iter, 0, proj.name);
            projectTreeStore.setValue(iter, 1, proj.id);
        }
    }
    
    private void refreshTaskList()
    {
        taskListStore.clear();
        
        if (currentProject)
        {
            foreach (task; currentProject.tasks)
            {
                TreeIter iter = taskListStore.createIter();
                taskListStore.setValue(iter, 0, task.id);
                taskListStore.setValue(iter, 1, task.name);
                taskListStore.setValue(iter, 2, task.status);
                taskListStore.setValue(iter, 3, task.priority);
                taskListStore.setValue(iter, 4, task.dueDate.toISOExtString());
            }
        }
    }
    
    private void showProjectDetails(Project proj)
    {
        auto text = "PROJECT: " ~ proj.name ~ "\n\n" ~
                   "Description: " ~ proj.description ~ "\n" ~
                   "Created: " ~ proj.createdDate.toISOExtString() ~ "\n" ~
                   "Total Tasks: " ~ proj.tasks.length.to!string ~ "\n" ~
                   "Completed: " ~ proj.tasks.count!(t => t.status == "done").to!string;
        
        detailsBuffer.setText(text);
    }
    
    private void showTaskDetails(Task task)
    {
        auto text = "TASK: " ~ task.name ~ "\n\n" ~
                   "Status: " ~ task.status ~ "\n" ~
                   "Priority: " ~ task.priority ~ "\n" ~
                   "Due Date: " ~ task.dueDate.toISOExtString() ~ "\n" ~
                   "Created: " ~ task.createdDate.toISOExtString() ~ "\n\n" ~
                   "Description:\n" ~ task.description;
        
        detailsBuffer.setText(text);
    }
    
    private void onAddProject(Button btn)
    {
        auto dialog = new Dialog(
            "New Project", 
            window, 
            GtkDialogFlags.MODAL, 
            ["Create", "Cancel"], 
            [GtkResponseType.ACCEPT, GtkResponseType.CANCEL]
        );
        auto contentBox = dialog.getContentArea();
        
        auto grid = new Box(GtkOrientation.VERTICAL, 10);
        grid.setMarginTop(10);
        grid.setMarginBottom(10);
        grid.setMarginStart(10);
        grid.setMarginEnd(10);
        
        grid.packStart(new Label("Project Name:"), false, false, 0);
        auto nameEntry = new Entry();
        grid.packStart(nameEntry, false, false, 0);
        
        grid.packStart(new Label("Description:"), false, false, 0);
        auto descEntry = new Entry();
        grid.packStart(descEntry, false, false, 0);
        
        contentBox.packStart(grid, true, true, 0);
        dialog.showAll();
        
        if (dialog.run() == GtkResponseType.ACCEPT)
        {
            Project proj;
            proj.id = "proj_" ~ (++projectIdCounter).to!string;
            proj.name = nameEntry.getText();
            proj.description = descEntry.getText();
            proj.createdDate = cast(Date)Clock.currTime();
            
            projects ~= proj;
            refreshProjectTree();
            saveData();
        }
        
        dialog.destroy();
    }
    
    private void onDeleteProject(Button btn)
    {
        auto selection = projectTreeView.getSelection();
        TreeIter iter = selection.getSelected();
        
        if (iter)
        {
            string projectId = projectTreeStore.getValue(iter, 1).getString();
            
            auto confirmDialog = new MessageDialog(
                window,
                GtkDialogFlags.MODAL,
                GtkMessageType.QUESTION,
                GtkButtonsType.YES_NO,
                "Delete this project and all its tasks?"
            );
            
            if (confirmDialog.run() == GtkResponseType.YES)
            {
                projects = projects.remove!(p => p.id == projectId);
                currentProject = null;
                refreshProjectTree();
                refreshTaskList();
                detailsBuffer.setText("");
                saveData();
            }
            
            confirmDialog.destroy();
        }
    }
    
    private void onAddTask(Button btn)
    {
        if (!currentProject) return;
        
        showTaskDialog(null);
    }
    
    private void onEditTask(Button btn)
    {
        auto selection = taskTreeView.getSelection();
        TreeIter iter = selection.getSelected();
        
        if (iter)
        {
            string taskId = taskListStore.getValue(iter, 0).getString();
            
            foreach (ref task; currentProject.tasks)
            {
                if (task.id == taskId)
                {
                    showTaskDialog(&task);
                    break;
                }
            }
        }
    }
    
    private void showTaskDialog(Task* existingTask)
    {
        bool isEdit = existingTask !is null;
        auto dialog = new Dialog(
            isEdit ? "Edit Task" : "New Task",
            window,
            GtkDialogFlags.MODAL,
            ["Save", "Cancel"],
            [GtkResponseType.ACCEPT, GtkResponseType.CANCEL]
        );
        
        auto contentBox = dialog.getContentArea();
        auto grid = new Box(GtkOrientation.VERTICAL, 10);
        grid.setMarginTop(10);
        grid.setMarginBottom(10);
        grid.setMarginStart(10);
        grid.setMarginEnd(10);
        
        grid.packStart(new Label("Task Name:"), false, false, 0);
        auto nameEntry = new Entry();
        if (isEdit) nameEntry.setText(existingTask.name);
        grid.packStart(nameEntry, false, false, 0);
        
        grid.packStart(new Label("Description:"), false, false, 0);
        auto descEntry = new Entry();
        if (isEdit) descEntry.setText(existingTask.description);
        grid.packStart(descEntry, false, false, 0);
        
        grid.packStart(new Label("Status:"), false, false, 0);
        auto statusBox = new Box(GtkOrientation.HORIZONTAL, 5);
        auto statusStore = new ListStore([GType.STRING]);
        foreach (status; ["todo", "in-progress", "done"])
        {
            TreeIter it = statusStore.createIter();
            statusStore.setValue(it, 0, status);
        }
        
        grid.packStart(new Label("Priority:"), false, false, 0);
        auto priorityBox = new Box(GtkOrientation.HORIZONTAL, 5);
        auto priorityStore = new ListStore([GType.STRING]);
        foreach (priority; ["low", "medium", "high"])
        {
            TreeIter it = priorityStore.createIter();
            priorityStore.setValue(it, 0, priority);
        }
        
        contentBox.packStart(grid, true, true, 0);
        dialog.showAll();
        
        if (dialog.run() == GtkResponseType.ACCEPT)
        {
            if (isEdit)
            {
                existingTask.name = nameEntry.getText();
                existingTask.description = descEntry.getText();
            }
            else
            {
                Task task;
                task.id = "task_" ~ (++taskIdCounter).to!string;
                task.name = nameEntry.getText();
                task.description = descEntry.getText();
                task.status = "todo";
                task.priority = "medium";
                task.dueDate = cast(Date)Clock.currTime() + 7.days;
                task.createdDate = cast(Date)Clock.currTime();
                
                currentProject.tasks ~= task;
            }
            
            refreshTaskList();
            saveData();
        }
        
        dialog.destroy();
    }
    
    private void onDeleteTask(Button btn)
    {
        if (!currentProject) return;
        
        auto selection = taskTreeView.getSelection();
        TreeIter iter = selection.getSelected();
        
        if (iter)
        {
            string taskId = taskListStore.getValue(iter, 0).getString();
            currentProject.tasks = currentProject.tasks.remove!(t => t.id == taskId);
            refreshTaskList();
            detailsBuffer.setText("");
            saveData();
        }
    }
    
    private void applyTheme()
    {
        auto cssProvider = new CssProvider();
        auto css = `
            window { background: #ecf0f1; }
            
            button {
                background: linear-gradient(to bottom, #3498db, #2980b9);
                color: white;
                border: none;
                border-radius: 4px;
                padding: 8px 16px;
                font-weight: bold;
            }
            
            button:hover {
                background: linear-gradient(to bottom, #5dade2, #3498db);
            }
            
            treeview {
                background-color: white;
                border: 1px solid #bdc3c7;
            }
            
            treeview:selected {
                background-color: #3498db;
                color: white;
            }
            
            textview {
                background-color: white;
                padding: 10px;
                border: 1px solid #bdc3c7;
            }
            
            entry {
                border: 2px solid #bdc3c7;
                border-radius: 4px;
                padding: 6px;
            }
            
            entry:focus {
                border-color: #3498db;
            }
        `;
        
        cssProvider.loadFromData(css);
        auto screen = Screen.getDefault();
        StyleContext.addProviderForScreen(screen, cssProvider, GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
    
    private void saveData()
    {
        JSONValue data;
        data["projects"] = JSONValue(cast(JSONValue[])[]);
        
        foreach (proj; projects)
        {
            JSONValue projJson;
            projJson["id"] = proj.id;
            projJson["name"] = proj.name;
            projJson["description"] = proj.description;
            projJson["createdDate"] = proj.createdDate.toISOExtString();
            projJson["tasks"] = JSONValue(cast(JSONValue[])[]);
            
            foreach (task; proj.tasks)
            {
                JSONValue taskJson;
                taskJson["id"] = task.id;
                taskJson["name"] = task.name;
                taskJson["description"] = task.description;
                taskJson["status"] = task.status;
                taskJson["priority"] = task.priority;
                taskJson["dueDate"] = task.dueDate.toISOExtString();
                taskJson["createdDate"] = task.createdDate.toISOExtString();
                projJson["tasks"].array ~= taskJson;
            }
            
            data["projects"].array ~= projJson;
        }
        
        std.file.write("projects.json", data.toPrettyString());
    }
    
    private void loadData()
    {
        if (!exists("projects.json")) return;
        
        try
        {
            auto data = parseJSON(readText("projects.json"));
            
            foreach (projJson; data["projects"].array)
            {
                Project proj;
                proj.id = projJson["id"].str;
                proj.name = projJson["name"].str;
                proj.description = projJson["description"].str;
                proj.createdDate = Date.fromISOExtString(projJson["createdDate"].str);
                
                foreach (taskJson; projJson["tasks"].array)
                {
                    Task task;
                    task.id = taskJson["id"].str;
                    task.name = taskJson["name"].str;
                    task.description = taskJson["description"].str;
                    task.status = taskJson["status"].str;
                    task.priority = taskJson["priority"].str;
                    task.dueDate = Date.fromISOExtString(taskJson["dueDate"].str);
                    task.createdDate = Date.fromISOExtString(taskJson["createdDate"].str);
                    proj.tasks ~= task;
                }
                
                projects ~= proj;
                
                // Update counters
                if (proj.id.startsWith("proj_"))
                {
                    int id = proj.id[5..$].to!int;
                    if (id > projectIdCounter) projectIdCounter = id;
                }
                
                foreach (task; proj.tasks)
                {
                    if (task.id.startsWith("task_"))
                    {
                        int id = task.id[5..$].to!int;
                        if (id > taskIdCounter) taskIdCounter = id;
                    }
                }
            }
        }
        catch (Exception e)
        {
            writeln("Error loading data: ", e.msg);
        }
    }
}

void main(string[] args)
{
    Main.init(args);
    new ProjectManagerApp();
    Main.run();
}
