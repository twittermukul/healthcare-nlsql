# NL-SQL Agent Development Notebook

This notebook is for **developing and improving the NL-SQL agents** - not for API testing. Use this to iterate on agent logic, prompts, and behavior.

## Purpose

This notebook helps you:
- **Develop agents** - Test and iterate on SQL Generator, Ambiguity Checker, and Visualization Recommender
- **Experiment with prompts** - Try different prompt variations and compare results
- **Debug agent behavior** - Step through agent logic with detailed output
- **Profile performance** - Identify bottlenecks in the agent pipeline
- **Test edge cases** - Find and fix problematic query patterns

## Setup

### 1. Install Dependencies

```bash
cd /Users/qcogadvisory/Documents/NLSQL/notebooks
python3 -m pip install -r requirements.txt
```

### 2. Add Jupyter bin to PATH (optional)

If you see warnings about scripts not on PATH:

```bash
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
```

Add this to your `~/.zshrc` or `~/.bash_profile` to make it permanent.

### 3. Start the Backend (for database access)

The notebook needs access to the database and configuration:

```bash
cd /Users/qcogadvisory/Documents/NLSQL
docker-compose up
```

### 4. Launch Jupyter

```bash
cd /Users/qcogadvisory/Documents/NLSQL/notebooks
jupyter notebook Agent_Development_Notebook.ipynb
```

Or use JupyterLab:

```bash
jupyter lab Agent_Development_Notebook.ipynb
```

## Notebook Sections

### 1. Setup and Imports
Initialize the agent components for testing

### 2. SQL Generator Testing
- Inspect SQL generation prompts
- Test SQL generation with different queries
- Test complex queries
- Compare different LLM models
- Experiment with prompt variations

### 3. Ambiguity Checker Testing
- Inspect ambiguity check prompts
- Test ambiguity detection
- Test edge cases (clear vs ambiguous queries)

### 4. Visualization Recommender Testing
- Test visualization recommendations
- Test number format detection
- Test chart type selection logic

### 5. Full Pipeline Testing
- Test the complete agent pipeline end-to-end
- Debug issues across multiple agent components

### 6. Prompt Engineering Experiments
- Test custom system prompts
- Compare prompt variations
- Optimize token usage

### 7. Performance Profiling
- Profile each stage of the pipeline
- Identify bottlenecks
- Compare timing across iterations

### 8. Semantic Layer Inspection
- View semantic dictionary terms
- View query templates
- View database schemas

### 9. Development Scratchpad
- Empty cells for ad-hoc testing

## Example Workflows

### Improving SQL Generation

```python
# 1. View current prompt
sql_prompt = PromptBuilder.build_sql_generation_prompt(view_schemas, query_templates)
print(sql_prompt)

# 2. Test with a problematic query
result = test_sql_generation("Show me high-cost patients")

# 3. Modify the prompt in app/agents/prompts.py

# 4. Reload the agent
agent = NLToSQLAgent()
sql_generator = agent.sql_generator

# 5. Test again
result = test_sql_generation("Show me high-cost patients")
```

### Testing Ambiguity Detection

```python
# Test with various query types
test_ambiguity_check("Show me the top patients")  # Should be ambiguous
test_ambiguity_check("Show me the top 5 patients by cost")  # Should be clear

# If the checker is too aggressive/lenient, modify app/agents/prompts.py
# and reload the agent
```

### Comparing LLM Models

```python
# Compare GPT-4o vs GPT-3.5-turbo
compare_models(
    "What are the top 5 conditions by patient count?",
    models=["gpt-4o", "gpt-3.5-turbo"]
)

# Analyze differences in:
# - SQL quality
# - Token usage
# - Response time
# - Success rate
```

### Profiling Performance

```python
# Profile the full pipeline
timings = profile_agent_pipeline(
    "How many patients do we have?",
    iterations=5
)

# Identify which stage is the bottleneck
# Common bottlenecks:
# - LLM API calls (SQL generation, ambiguity check)
# - Database queries (execution)
# - Visualization recommendation
```

## Agent File Locations

When you find issues and want to fix them, here are the agent files:

- **SQL Generator**: `app/agents/sql_generator.py`
- **Ambiguity Checker**: `app/agents/ambiguity_checker.py`
- **Visualization Recommender**: `app/agents/visualization_recommender.py`
- **Prompts**: `app/agents/prompts.py`
- **Main Agent**: `app/agents/nl_to_sql_agent.py`

## Development Workflow

1. **Identify Issue** - Use the notebook to reproduce a problem
2. **Test Current Behavior** - Run test functions to understand current output
3. **Modify Agent Code** - Edit the agent files in `app/agents/`
4. **Reload Agent** - Restart the kernel or reload: `agent = NLToSQLAgent()`
5. **Test Again** - Verify the fix works
6. **Profile** - Ensure no performance regression

## Tips

- **Use test functions** - Don't call agents directly, use the helper functions that show detailed output
- **Test edge cases** - Always test ambiguous, complex, and malformed queries
- **Compare models** - Try different LLMs to understand behavior differences
- **Profile regularly** - Track performance as you make changes
- **Inspect prompts** - View the full system prompts to understand agent context

## Troubleshooting

### Import Errors

If you get import errors:
```bash
# Make sure you're in the notebooks directory
cd /Users/qcogadvisory/Documents/NLSQL/notebooks

# Reinstall dependencies
python3 -m pip install -r requirements.txt
```

### Database Connection Errors

If you get database errors:
```bash
# Check backend is running
cd /Users/qcogadvisory/Documents/NLSQL
docker-compose ps

# Restart if needed
docker-compose down
docker-compose up
```

### Agent Not Updating

If changes to agent code don't take effect:
```python
# In the notebook, restart the kernel (Kernel → Restart)
# Or reload the module:
import importlib
import sys
sys.path.insert(0, os.path.abspath('..'))

from app.agents import nl_to_sql_agent
importlib.reload(nl_to_sql_agent)

agent = nl_to_sql_agent.NLToSQLAgent()
```

## Branch Information

This notebook is in the `devil` branch for development and testing.

To commit agent improvements:
```bash
# Make changes to agent files
git add app/agents/

# Commit with descriptive message
git commit -m "Improve SQL generation for aggregation queries"

# Test thoroughly before merging to main
```
