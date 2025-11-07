import sqlite3
import pandas as pd
from pathlib import Path

db_path = Path(__file__).parent.parent / "msiysp_dev.db"
conn = sqlite3.connect(db_path)

activities = pd.read_sql("SELECT * FROM activities", conn)

print(f"Activities: {len(activities)}")
