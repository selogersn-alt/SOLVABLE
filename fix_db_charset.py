import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')
django.setup()

from django.db import connection

def convert_to_utf8mb4():
    with connection.cursor() as cursor:
        db_name = 'gaak4328_loger_app'
        print(f"Altering database {db_name} to utf8mb4...")
        cursor.execute(f"ALTER DATABASE `{db_name}` CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;")
        
        cursor.execute("SHOW TABLES;")
        tables = cursor.fetchall()
        
        for table_row in tables:
            table = table_row[0]
            print(f"Converting table {table} to utf8mb4...")
            try:
                cursor.execute(f"ALTER TABLE `{table}` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
                print(f" - Success for {table}")
            except Exception as e:
                print(f" - Error converting {table}: {e}")

if __name__ == '__main__':
    convert_to_utf8mb4()
    print("Database encoding update complete.")
