import os

source_file = r'd:\HDIGITAL\ANDROID ANTIGRAVITY\SOLVABLE.LOGERSN\logersenegal\views.py'
dest_file = r'd:\HDIGITAL\ANDROID ANTIGRAVITY\SOLVABLE.LOGERSN\solvable\views.py'
urls_file = r'd:\HDIGITAL\ANDROID ANTIGRAVITY\SOLVABLE.LOGERSN\logersenegal\urls.py'

functions_to_move = [
    'filiation_details_view',
    'report_incident_view',
    'update_incident_status_view',
    'record_payment_view',
    'mediation_room_view',
    'download_receipt_view',
    'apply_to_property_view',
    'start_filiation_view',
    'approve_filiation_view',
    'terminate_filiation_view',
    'update_application_status_view'
]

with open(source_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_source_lines = []
extracted_code = []

inside_function = False
current_func = None
decorators = []

for line in lines:
    if line.startswith('@'):
        decorators.append(line)
        continue

    if line.startswith('def '):
        func_name = line.split('def ')[1].split('(')[0]
        if func_name in functions_to_move:
            inside_function = True
            current_func = func_name
            extracted_code.extend(decorators)
            extracted_code.append(line)
            decorators = []
            continue
        else:
            # Not a function to move, flush decorators to source
            new_source_lines.extend(decorators)
            new_source_lines.append(line)
            decorators = []
            inside_function = False
            continue

    if inside_function:
        if line.startswith('def ') or line.startswith('class '):
            # This shouldn't happen based on above logic, but just in case
            pass
        elif line.startswith('@'):
            # decorator of NEXT function
            decorators.append(line)
            inside_function = False
        elif line.strip() == '' and (not extracted_code or extracted_code[-1].strip() == ''):
            extracted_code.append(line)
        elif not line.startswith(' ') and not line.startswith('\t') and line.strip() != '':
            # Found some top level code like an import?
            if line.startswith('from ') or line.startswith('import '):
                 extracted_code.append(line)
            else:
                 inside_function = False
                 new_source_lines.append(line)
        else:
            extracted_code.append(line)
    else:
        new_source_lines.extend(decorators)
        decorators = []
        new_source_lines.append(line)

# Add flush handling for decorators at end of file if any
new_source_lines.extend(decorators)

# Now write them back
with open(source_file, 'w', encoding='utf-8') as f:
    f.writelines(new_source_lines)

# Write to dest file
imports_for_solvable = """from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.utils import timezone
from django.http import HttpResponse

"""

with open(dest_file, 'r', encoding='utf-8') as f:
    existing_dest = f.read()

with open(dest_file, 'w', encoding='utf-8') as f:
    f.write(imports_for_solvable)
    f.write(existing_dest)
    f.write('\n\n')
    f.write("".join(extracted_code))

with open(urls_file, 'r', encoding='utf-8') as f:
    urls_content = f.read()

# Try to find exactly where to add imports
if 'from solvable.views import' not in urls_content:
    urls_content = urls_content.replace(
        "from logersenegal.views import",
        "from solvable.views import (" + ", ".join(functions_to_move) + ")\nfrom logersenegal.views import"
    )

with open(urls_file, 'w', encoding='utf-8') as f:
    f.write(urls_content)

print(f"Extracted {len(extracted_code)} lines of code.")
