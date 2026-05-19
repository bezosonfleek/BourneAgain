#!/bin/bash
read -p "Desired file name: " OUTPUT_FILE

# Function to generate the HTML skeleton and pull data from monitoring tools
generate_report() {
    cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>System Status Report</title>
    <style>
        body { font-family: sans-serif; margin: 30px; background-color: #f4f6f9; color: #333; }
        h1 { color: #2c3e50; border-bottom: 2px solid #2c3e50; padding-bottom: 10px; }
        h2 { color: #16a085; margin-top: 30px; }
        pre { background: #2c3e50; color: #ecf0f1; padding: 15px; border-radius: 5px; overflow-x: auto; font-size: 14px; }
        .date { font-style: italic; color: #7f8c8d; }
    </style>
</head>
<body>
    <h1>System Status Report</h1>
    <p class="date">Generated on: $(date +"%Y-%m-%d %H:%M:%S")</p>

    <h2>System Uptime</h2>
    <pre>$(uptime)</pre>

    <h2>Filesystem Space</h2>
    <pre>$(df -h)</pre>

    <h2>Home Directory Space by User</h2>
    <pre>Bytes       Directory
$(du -sh /home/* 2>/dev/null | sort -hr)</pre>
</body>
</html>
EOF
}

# Run the function and save the entire output directly into your file
generate_report > "$OUTPUT_FILE"

echo "Report successfully generated at: $OUTPUT_FILE"
