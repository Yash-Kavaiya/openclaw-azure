```markdown
# openclaw-azure Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches the development patterns and conventions used in the openclaw-azure Python project. The codebase follows specific naming conventions and commit patterns that prioritize feature development with clear, concise commit messages.

## Coding Conventions

### File Naming
- Use **camelCase** for file naming
- Example: `dataProcessor.py`, `configManager.py`, `azureConnector.py`

### Import Style
- Mixed import patterns are used throughout the codebase
- Organize imports logically with standard library first, then third-party, then local imports
```python
import os
import sys
from typing import Dict, List

import azure.storage.blob
from azure.identity import DefaultAzureCredential

from .configManager import ConfigManager
from .utils import helper_function
```

### Code Organization
- Follow Python PEP 8 guidelines where applicable
- Maintain consistency with existing mixed export patterns
- Use clear, descriptive variable and function names

## Workflows

### Feature Development
**Trigger:** When adding new functionality or capabilities
**Command:** `/add-feature`

1. Create a new branch for the feature
2. Implement the feature following camelCase file naming
3. Write descriptive code with clear function names
4. Test the feature functionality
5. Commit with format: `feat: [concise description in ~40 chars]`
6. Create pull request for review

### Code Organization
**Trigger:** When structuring new modules or refactoring
**Command:** `/organize-code`

1. Use camelCase for new file names
2. Group related functionality in logical modules
3. Implement consistent import patterns
4. Ensure proper separation of concerns
5. Update any configuration or connection files as needed

## Testing Patterns

### Test File Structure
- Test files follow the pattern: `*.test.*`
- Example: `dataProcessor.test.py`, `azureConnector.test.py`
- Place tests alongside or in dedicated test directories

### Testing Approach
```python
# Example test structure
def test_feature_functionality():
    # Arrange
    test_data = setup_test_data()
    
    # Act
    result = feature_function(test_data)
    
    # Assert
    assert result == expected_outcome
```

## Commit Conventions

### Commit Message Format
- Use `feat:` prefix for new features
- Keep messages concise (~40 characters)
- Focus on what the commit accomplishes
- Examples:
  - `feat: add azure blob storage integration`
  - `feat: implement data processing pipeline`
  - `feat: add configuration management`

## Commands
| Command | Purpose |
|---------|---------|
| `/add-feature` | Start feature development workflow |
| `/organize-code` | Structure and organize code modules |
| `/test-setup` | Set up testing for new functionality |
| `/commit-feat` | Create a properly formatted feature commit |
```