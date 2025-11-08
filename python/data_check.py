import sqlite3
import pandas as pd
from pathlib import Path

db_path = Path(__file__).parent.parent / "msiysp_dev.db"
conn = sqlite3.connect(db_path)

activities = pd.read_sql("SELECT * FROM activities", conn)

print(f"Activities: {len(activities)}")

# Date range
print(f"Date range: {activities['date'].min()} to {activities['date'].max()}")
print(f"Days covered: {(pd.to_datetime(activities['date']).max() - pd.to_datetime(activities['date']).min()).days}\n")

# Activity types breakdown
print("Activity types:")
print(activities['type'].value_counts())
print()

# Distance and duration stats
print(f"Total distance: {activities['distance_meters'].sum() / 1609.344:.1f} mi")
print(f"Total duration: {activities['duration_seconds'].sum() / 3600:.1f} hours")
print()

