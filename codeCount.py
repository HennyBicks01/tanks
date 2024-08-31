import os
import re

def count_lines_in_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()
    
    # Remove empty lines and comments
    code_lines = [line.strip() for line in lines if line.strip() and not line.strip().startswith('#')]
    return len(code_lines)

def count_lines_in_scenes_folder(folder_path):
    total_lines = 0
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            if file.endswith(('.gd', '.tscn')):  # Include both .gd and .tscn files
                file_path = os.path.join(root, file)
                lines = count_lines_in_file(file_path)
                total_lines += lines
                print(f"{file}: {lines} lines")
    
    print(f"\nTotal lines of code in scenes folder: {total_lines}")

if __name__ == "__main__":
    scenes_folder = "scenes"  # Update this path if your scenes folder is located elsewhere
    count_lines_in_scenes_folder(scenes_folder)