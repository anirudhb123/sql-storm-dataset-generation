# SQLStorm to Cardinal Dataset Generator

Convert SQLStorm benchmark results into Cardinal-compatible datasets with configurable query subsets.

## Quick Setup

1. **Clone and setup data**:
```bash
   git clone https://github.com/anirudhb123/sql-storm-dataset-generation.git
   cd sql-storm-dataset-generation
   unzip sqlstorm_data.zip  # Extract essential data files
   ```

2. **Install dependencies**:
```bash
   pip install pandas psycopg2-binary tqdm pyarrow
   ```

3. **Setup PostgreSQL**:
```bash
   brew services start postgresql@15
   createdb stackoverflow
   psql -d stackoverflow -f v1.0/stackoverflow/schema.sql
   ```

3. **Update your username** in `convert_to_cardinal.py`:
   ```python
   DB_USER = "your_username"  # Change this to your PostgreSQL username
   ```

## Troubleshooting

**Getting "No results CSV found" error?**
- Make sure you extracted `sqlstorm_data.zip` after cloning
- This provides the essential data files that Git LFS sometimes fails to download
- The zip file contains the required CSV files in the correct directory structure

## Running Different Query Subsets

Edit the configuration in `convert_to_cardinal.py` and run:

### Get 100 queries starting from position 0 (first 100)
```python
SUBSET_SIZE = 100
SUBSET_START = 0
SUBSET_METHOD = "sequential"
```
Output: `stackoverflow_n100.parquet` and `stackoverflow_n100.csv`

### Get 50 queries starting from position 500
```python
SUBSET_SIZE = 50
SUBSET_START = 500
SUBSET_METHOD = "sequential"
```
Output: `stackoverflow_n50_start500.parquet` and `stackoverflow_n50_start500.csv`

### Get 200 random queries
```python
SUBSET_SIZE = 200
SUBSET_METHOD = "random"
RANDOM_SEED = 42  # for reproducible results
```
Output: `stackoverflow_n200_random.parquet` and `stackoverflow_n200_random.csv`

### Get 75 fastest queries
```python
SUBSET_SIZE = 75
SUBSET_START = 0
SUBSET_METHOD = "by_time"
```
Output: `stackoverflow_n75_by_time.parquet` and `stackoverflow_n75_by_time.csv`

### Get 50 slowest queries
```python
SUBSET_SIZE = 50
SUBSET_START = -50  # negative indexing for slowest
SUBSET_METHOD = "by_time"
```

## Run the Script

```bash
python convert_to_cardinal.py
```

The script will generate both Parquet and CSV files in the `cardinal_dataset/` directory.

## Available Query Pool

- **Total queries**: ~18,147 StackOverflow queries with execution times
- **Range**: 0.8ms to 41,437ms execution times
- **Success rate**: ~98% (some queries fail due to PostgreSQL compatibility)

## Output Format

Each dataset contains:
- `query`: Query filename
- `sql_text`: Full SQL query
- `plan_json`: PostgreSQL execution plan
- `execution_time`: Real execution time (ms)
- `reward`: Normalized performance score (-1.0 to 0.0, higher = better)