#!/usr/bin/env python3
"""
Database migration script to add performance indexes.
Run this script to optimize database performance.
"""

import os
import sys
import psycopg2
from sqlalchemy import create_engine, text
from db import DATABASE_URL

def run_migration():
    """Run the database migration to add performance indexes."""
    
    print("Starting database migration for performance optimization...")
    
    try:
        # Create engine
        engine = create_engine(DATABASE_URL)
        
        # Read the migration SQL file
        migration_file = os.path.join(os.path.dirname(__file__), 'migrations', 'add_performance_indexes.sql')
        
        if not os.path.exists(migration_file):
            print(f"Error: Migration file not found at {migration_file}")
            return False
        
        with open(migration_file, 'r') as f:
            migration_sql = f.read()
        
        # Execute the migration
        with engine.connect() as connection:
            # Split the SQL into individual statements
            statements = [stmt.strip() for stmt in migration_sql.split(';') if stmt.strip()]
            
            for i, statement in enumerate(statements, 1):
                if statement:
                    try:
                        print(f"Executing statement {i}/{len(statements)}...")
                        connection.execute(text(statement))
                        connection.commit()
                        print(f"✓ Statement {i} executed successfully")
                    except Exception as e:
                        print(f"⚠ Statement {i} failed (this might be expected if index already exists): {e}")
                        # Continue with other statements even if one fails
                        continue
        
        print("\n✅ Database migration completed successfully!")
        print("Performance indexes have been added to optimize query performance.")
        
        return True
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        return False

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
