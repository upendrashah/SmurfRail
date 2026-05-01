#!/usr/bin/env python3
"""
Download Indian Railways dataset from Kaggle and populate SQLite database.
Requires: pip install kagglehub pandas
"""

import os
import sys
import sqlite3
import pandas as pd
from pathlib import Path

# Try importing kagglehub
try:
    import kagglehub
except ImportError:
    print("kagglehub not found. Install with: pip install kagglehub pandas")
    sys.exit(1)


def download_dataset():
    """Download dataset from Kaggle."""
    print("Downloading Indian Railways dataset from Kaggle...")
    try:
        path = kagglehub.dataset_download("sripaadsrinivasan/indian-railways-dataset")
        print(f"✓ Downloaded to: {path}")
        return path
    except Exception as e:
        print(f"✗ Failed to download: {e}")
        print("\nSetup Kaggle API:")
        print("1. Go to https://www.kaggle.com/settings/account")
        print("2. Click 'Create New API Token' → saves kaggle.json")
        print("3. Move to ~/.kaggle/kaggle.json")
        print("4. Run this script again")
        sys.exit(1)


def create_database(db_path):
    """Create SQLite database schema."""
    print(f"\nCreating database: {db_path}")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Train table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS Train (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            train_no TEXT NOT NULL UNIQUE,
            train_name TEXT NOT NULL,
            source TEXT NOT NULL,
            destination TEXT NOT NULL,
            departure TEXT NOT NULL,
            arrival TEXT NOT NULL
        )
    ''')
    
    # Route table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS Route (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            train_no TEXT NOT NULL,
            station_name TEXT NOT NULL,
            arrival TEXT NOT NULL,
            departure TEXT NOT NULL,
            stop_number INTEGER NOT NULL,
            FOREIGN KEY(train_no) REFERENCES Train(train_no)
        )
    ''')
    
    # SeatAvailability table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS SeatAvailability (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            train_no TEXT NOT NULL,
            date TEXT NOT NULL,
            sleeper INTEGER NOT NULL,
            ac3 INTEGER NOT NULL,
            ac2 INTEGER NOT NULL,
            ac1 INTEGER NOT NULL,
            FOREIGN KEY(train_no) REFERENCES Train(train_no)
        )
    ''')
    
    conn.commit()
    print("✓ Tables created")
    return conn


def import_trains(conn, dataset_path):
    """Import train data from CSV."""
    print("\nImporting trains...")
    
    # Look for CSV files in dataset
    csv_files = list(Path(dataset_path).glob("*.csv"))
    print(f"Found {len(csv_files)} CSV files")
    
    for csv_file in csv_files:
        print(f"  - {csv_file.name}")
    
    if not csv_files:
        print("✗ No CSV files found in dataset")
        return
    
    # Try to find and load the main trains file
    train_file = None
    for f in csv_files:
        if 'train' in f.name.lower():
            train_file = f
            break
    
    if not train_file:
        train_file = csv_files[0]  # Fall back to first CSV
    
    print(f"\nLoading: {train_file.name}")
    
    try:
        df = pd.read_csv(train_file)
        print(f"DataFrame shape: {df.shape}")
        print(f"Columns: {list(df.columns)}")
        
        # Map CSV columns to database columns (adjust based on actual CSV)
        # Common column names: train_number, train_name, from_station, to_station, departure, arrival
        
        cursor = conn.cursor()
        inserted = 0
        
        for idx, row in df.iterrows():
            try:
                # Extract values (adjust keys based on actual CSV columns)
                train_no = str(row.get('train_number') or row.get('Train_Number') or row.get('train_no') or '')
                train_name = str(row.get('train_name') or row.get('Train_Name') or '')
                source = str(row.get('from_station') or row.get('source') or '')
                dest = str(row.get('to_station') or row.get('destination') or '')
                departure = str(row.get('departure_time') or row.get('departure') or '00:00')
                arrival = str(row.get('arrival_time') or row.get('arrival') or '00:00')
                
                if not train_no or not train_name:
                    continue
                
                cursor.execute('''
                    INSERT INTO Train (train_no, train_name, source, destination, departure, arrival)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (train_no, train_name, source, dest, departure, arrival))
                inserted += 1
                
            except sqlite3.IntegrityError:
                # Train already exists
                pass
            except Exception as e:
                print(f"    Warning: Row {idx} skipped: {e}")
        
        conn.commit()
        print(f"✓ Inserted {inserted} trains")
        
    except Exception as e:
        print(f"✗ Error loading CSV: {e}")
        print(f"Please check CSV format in: {train_file}")
        return False
    
    return True


def add_sample_routes(conn):
    """Add sample route data for imported trains."""
    print("\nAdding route data...")
    
    cursor = conn.cursor()
    
    # Get all trains
    cursor.execute("SELECT train_no, source, destination FROM Train")
    trains = cursor.fetchall()
    
    added = 0
    for train_no, source, dest in trains:
        try:
            # Add 3-4 stops per train: source → intermediate → destination
            stops = [
                (train_no, source, "START", "10:00", 1),
                (train_no, "Intermediate Station", "12:00", "12:15", 2),
                (train_no, dest, "14:00", "END", 3),
            ]
            
            for stop in stops:
                cursor.execute('''
                    INSERT INTO Route (train_no, station_name, arrival, departure, stop_number)
                    VALUES (?, ?, ?, ?, ?)
                ''', stop)
                added += 1
        except sqlite3.IntegrityError:
            pass
    
    conn.commit()
    print(f"✓ Added {added} route stops")


def add_seat_availability(conn):
    """Add sample seat availability for next 5 days."""
    print("\nAdding seat availability...")
    
    from datetime import datetime, timedelta
    
    cursor = conn.cursor()
    cursor.execute("SELECT train_no FROM Train")
    trains = cursor.fetchall()
    
    # Generate for next 5 days
    base_date = datetime.now().date()
    dates = [(base_date + timedelta(days=i)).strftime("%Y-%m-%d") for i in range(5)]
    
    added = 0
    for (train_no,) in trains:
        for date in dates:
            try:
                # Random realistic seat counts
                cursor.execute('''
                    INSERT INTO SeatAvailability (train_no, date, sleeper, ac3, ac2, ac1)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (train_no, date, 85, 55, 30, 10))
                added += 1
            except sqlite3.IntegrityError:
                pass
    
    conn.commit()
    print(f"✓ Added {added} seat availability records")


def main():
    """Main workflow."""
    print("=" * 60)
    print("Indian Railways Dataset → SQLite Importer")
    print("=" * 60)
    
    # Paths
    dataset_path = download_dataset()
    
    db_path = Path(__file__).parent / "train_data.db"
    
    # Remove old database if exists
    if db_path.exists():
        db_path.unlink()
        print(f"Removed old database")
    
    # Create and populate database
    conn = create_database(db_path)
    
    if import_trains(conn, dataset_path):
        add_sample_routes(conn)
        add_seat_availability(conn)
    
    conn.close()
    
    print("\n" + "=" * 60)
    print(f"✓ Success! Database created: {db_path}")
    print("=" * 60)
    print("\nNext steps:")
    print(f"1. Copy {db_path} to lib/assets/")
    print("2. Update lib/database/database_helper.dart to use this database")
    print("3. Run: flutter run -d VKTGV4BIGAVGR8QS")


if __name__ == "__main__":
    main()
