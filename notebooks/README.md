# NL-SQL Development Notebook

This notebook provides a comprehensive testing and development environment for the NL-SQL query generation system.

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

### 3. Start the Backend Server

Before using the notebook, make sure the NL-SQL API is running:

```bash
cd /Users/qcogadvisory/Documents/NLSQL
docker-compose up
```

The API should be accessible at `http://localhost:8001`

### 4. Launch Jupyter

```bash
cd /Users/qcogadvisory/Documents/NLSQL/notebooks
jupyter notebook NLSQL_Development_Notebook.ipynb
```

Or use JupyterLab:

```bash
jupyter lab NLSQL_Development_Notebook.ipynb
```

## Features

The notebook includes the following tools:

### Quick Testing Functions

- **`test_query(question)`** - Test a natural language query with formatted output
- **`execute_sql(sql)`** - Execute SQL directly without NL conversion
- **`list_test_cases()`** - Display all pre-defined test cases
- **`run_test_suite(category)`** - Run test suites by category

### Exploration Functions

- **`explore_schema()`** - View all database views and columns
- **`view_semantic_dictionary()`** - View semantic term mappings
- **`view_query_templates()`** - View query templates

### Performance Functions

- **`benchmark_queries(queries, iterations)`** - Benchmark query performance

### Pre-defined Test Cases

The notebook includes 7 categories of test cases:

1. **basic_counts** - Simple patient and visit counts
2. **demographics** - Gender, age, race distribution
3. **costs** - High-cost patients, average costs
4. **conditions** - Patients with specific conditions
5. **utilization** - Readmissions, length of stay
6. **quality** - Mortality rates, complications
7. **geographic** - State and county-based queries

## Example Usage

```python
# Test a single query
test_query("How many patients do we have in California?")

# Run all basic count tests
run_test_suite(category="basic_counts")

# Execute direct SQL
execute_sql("SELECT COUNT(*) FROM vw_patients_2025")

# View database schema
explore_schema()

# Benchmark performance
benchmark_queries([
    "How many patients?",
    "Show me high-cost patients",
    "What are the top 5 conditions?"
], iterations=3)
```

## Workflow Tips

1. **Start with pre-defined test cases** to understand what works
2. **Use test_query() for quick iteration** on new queries
3. **Check generated SQL** to understand the pipeline
4. **Use execute_sql()** to verify SQL modifications
5. **Benchmark regularly** to track performance changes

## Troubleshooting

### Connection Errors

If you get connection errors:
- Verify the backend is running: `docker-compose ps`
- Check the API_BASE URL in the notebook (default: `http://localhost:8001`)
- Test the API manually: `curl http://localhost:8001/health`

### Import Errors

If you get import errors:
- Reinstall dependencies: `python3 -m pip install -r requirements.txt`
- Check Python version: `python3 --version` (requires 3.9+)

### Notebook Not Found

If Jupyter says notebook not found:
- Make sure you're in the correct directory: `cd /Users/qcogadvisory/Documents/NLSQL/notebooks`
- Use the full path: `jupyter notebook /Users/qcogadvisory/Documents/NLSQL/notebooks/NLSQL_Development_Notebook.ipynb`

## Branch Information

This notebook is in the `devil` branch for development and testing purposes.

To switch back to main:
```bash
git checkout main
```

To commit changes to devil branch:
```bash
git add .
git commit -m "Update development notebook"
```
