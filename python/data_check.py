import sqlite3
import pandas as pd
from pathlib import Path

db_path = Path(__file__).parent.parent / "tempo_dev.db"
conn = sqlite3.connect(db_path)

samples = pd.read_sql("SELECT * FROM health_samples", conn)

print(f"Samples: {len(samples)}")

# Date range
print(f"Date range: {samples['date'].min()} to {samples['date'].max()}")
print(f"Days covered: {(pd.to_datetime(samples['date']).max() - pd.to_datetime(samples['date']).min()).days}\n")

# Type breakdown
print("Sample types:")
print(samples['type'].value_counts())
print()


