# GoPlaces iOS Development Guidelines

## Visual References
- Mocks of app and views are stored in app_views.png
- Use Xcode MCP for checking builds and other stuff

## Architecture Documentation

### Future Considerations Document
- **File**: `FUTURE_CONSIDERATIONS.md` - Critical architecture decisions and analysis
- **Quick Access**: First section contains content overview with anchor links
- **Usage Pattern**: 
  1. Read content overview for quick topic scan
  2. Jump to specific section using `#anchor-id` links  
  3. Each section follows: Problem → Analysis → Solution → Implementation
- **When to Consult**: Before making auth, data sync, or major architectural decisions
- **Adding Content**: Follow template format, update overview section with new links

## Task Management System

### File Structure
- **Primary Task File**: `tasks/STRUCTURED-TASKS.md` - Complete task specifications with acceptance criteria
- **Current Sprint**: `tasks/CURRENT-SPRINT.md` - Active sprint status and next actions  
- **Task References**: `tasks/TASK-REFERENCES.md` - Line numbers and shortcuts for efficient navigation
- **Process Guidelines**: `~/ai-task-builder/process-task-list.md` - Standard task processing rules

### Task Processing Protocol

#### 1. **Task Discovery & Status**
```bash
# Check current task status  
grep -A 5 -B 5 "🟡\|🔴\|🟢" tasks/STRUCTURED-TASKS.md
```

#### 2. **Work One Sub-Task at a Time**
- **NEVER** start next sub-task without user permission
- **ASK** "May I proceed with [next sub-task]?" after each completion
- **WAIT** for "yes", "y", or specific instruction

#### 3. **Update Progress Real-Time**
```markdown
# In STRUCTURED-TASKS.md - Update acceptance criteria:
- [ ] Sub-task description  →  - [x] Sub-task description

# In CURRENT-SPRINT.md - Update sprint status:
- Current working on: [description]
- Completed: X/Y acceptance criteria
```

#### 4. **Commit Protocol (When All Sub-Tasks Complete)**
1. **Run tests first**: `uv run python -m pytest` or equivalent
2. **Stage changes**: `git add .`  
3. **Commit with structured message**:
```bash
git commit -m "feat: complete TASK-XXX [task name]" \
-m "- [Key accomplishment 1]" \
-m "- [Key accomplishment 2]" \
-m "- All acceptance criteria met" \
-m "Related to TASK-XXX in PRD" \
-m "🤖 Generated with Claude Code" \
-m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

#### 5. **Auto-Proceed Conditions**
- ✅ **DO WITHOUT ASKING**: Loading states, error handling, UI polish, tests, documentation
- ❌ **ALWAYS ASK FIRST**: Architecture changes, new dependencies, database schema changes

### Current Project Context

#### Tech Stack
- **iOS**: SwiftUI + SwiftData (migrated from CoreData)
- **Share Extension**: URL extraction and place creation
- **Data Sharing**: App Group `group.com.goplaces.shared`
- **Backend**: Python with uv dependency management (separate project)

#### Build & Test Commands
```bash
# iOS Build
mcp__XcodeBuildMCP__build_sim(projectPath="GoPlaces.xcodeproj", scheme="GoPlaces", simulatorName="iPhone 16")

# Python Backend Tests  
uv run python -m pytest

# Run specific iOS tests
mcp__XcodeBuildMCP__test_sim(projectPath="GoPlaces.xcodeproj", scheme="GoPlaces", simulatorName="iPhone 16")
```

#### Immediate Task Status
- **Current**: TASK-001 (Share Extension Foundation) - 4/6 criteria complete ✅  
- **Remaining**: Loading states, error handling polish
- **Next**: TASK-002 (API Client & Place Extraction)

### Emergency Procedures

#### If Build Fails
1. **Read error carefully** - look for specific file:line references
2. **Check TASK-REFERENCES.md** for known solutions
3. **Update dependencies if needed**: `uv sync`
4. **Clean derived data**: Delete Xcode DerivedData folder

#### If Lost in Tasks
1. **Read CURRENT-SPRINT.md** for context
2. **Check last commit message** for progress: `git log --oneline -5`
3. **Verify task status**: Look for `🟡 In Progress` in STRUCTURED-TASKS.md

### Engineering Standards
- **No hardcoded values** - use AppConstants
- **No user-facing messages in code** - externalize all text
- **Comprehensive error handling** with proper logging
- **Unit tests required** for business logic (min 80% coverage)
- **Production-ready patterns** - graceful degradation, retry logic

### Integration Points
- **SwiftData**: All models use `@Model` annotation
- **App Groups**: Data shared via `group.com.goplaces.shared`
- **URL Extensions**: Validation and cleaning utilities in shared code
- **Error Handling**: Centralized via `ErrorHandler.shared`

## File Organization
- **Models**: `Core/Data/Models/` - SwiftData models
- **Services**: `Core/Data/Services/` - Business logic
- **Views**: `Features/Places/Views/` - SwiftUI views  
- **ViewModels**: `Features/Places/ViewModels/` - MVVM pattern
- **Extensions**: `Shared/Extensions/` - Utility extensions
- I consider warnings as errors. Make sure build always passes with 0 warnings