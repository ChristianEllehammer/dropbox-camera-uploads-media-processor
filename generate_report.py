#!/usr/bin/env python3

import os
import re
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication

# Configuration
LOG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logs")
REPORT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "reports")
EMAIL_CONFIG = {
    "smtp_server": "smtp.gmail.com",
    "smtp_port": 587,
    "sender_email": "christian.ellehammer@gmail.com",  # Update this
    "sender_password": "mtsl ckxc lypo gugg",  # Update this
    "recipient_email": "christian.ellehammer@gmail.com"  # Update this
}

def parse_optimizer_log(log_file):
    data = []
    current_file = None
    current_data = {}
    
    with open(log_file, 'r') as f:
        for line in f:
            if "Processing files:" in line:
                if current_file and current_data:
                    data.append(current_data)
                current_file = line.split("Processing files:")[1].strip()
                current_data = {"filename": current_file}
            elif "Original size:" in line:
                size_str = line.split("Original size:")[1].strip()
                current_data["original_size"] = float(size_str.split()[0])
                current_data["original_size_unit"] = size_str.split()[1]
            elif "New size:" in line and "bytes" in line:
                size_str = line.split("New size:")[1].strip()
                current_data["new_size"] = float(size_str.split()[0])
                current_data["new_size_unit"] = size_str.split()[1]
            elif "Space saved:" in line:
                saved_str = line.split("Space saved:")[1].strip()
                current_data["space_saved"] = float(saved_str.split()[0])
                current_data["space_saved_unit"] = saved_str.split()[1]
                current_data["savings_percent"] = float(saved_str.split("(")[1].strip("%)"))
    
    if current_file and current_data:
        data.append(current_data)
    
    return pd.DataFrame(data)

def parse_size(size_str):
    # Convert size string (e.g., "1.5 MB (1572864 bytes)") to bytes
    match = re.search(r"([\d.]+)\s+(\w+)\s+\((\d+)\s+bytes\)", size_str)
    if match:
        return int(match.group(3))
    return 0

def generate_visualizations(df, report_dir):
    # Create visualizations directory
    viz_dir = os.path.join(report_dir, "visualizations")
    os.makedirs(viz_dir, exist_ok=True)
    
    # 1. Space Savings Over Time
    plt.figure(figsize=(12, 6))
    plt.bar(range(len(df)), df["space_saved"])
    plt.title("Space Savings per File")
    plt.xlabel("File Index")
    plt.ylabel("Space Saved (KB)")
    plt.xticks(range(len(df)), df["filename"].apply(lambda x: os.path.basename(x)), rotation=45)
    plt.tight_layout()
    plt.savefig(os.path.join(viz_dir, "space_savings.png"))
    plt.close()
    
    # 2. Optimization Percentage Distribution
    plt.figure(figsize=(10, 6))
    plt.hist(df["savings_percent"], bins=20)
    plt.title("Distribution of Optimization Percentages")
    plt.xlabel("Optimization Percentage")
    plt.ylabel("Number of Files")
    plt.tight_layout()
    plt.savefig(os.path.join(viz_dir, "optimization_distribution.png"))
    plt.close()
    
    # 3. Original vs New Size Comparison
    plt.figure(figsize=(12, 6))
    x = range(len(df))
    width = 0.35
    plt.bar([i - width/2 for i in x], df["original_size"], width, label="Original Size")
    plt.bar([i + width/2 for i in x], df["new_size"], width, label="New Size")
    plt.title("Original vs New File Sizes")
    plt.xlabel("File Index")
    plt.ylabel("Size (KB)")
    plt.xticks(x, df["filename"].apply(lambda x: os.path.basename(x)), rotation=45)
    plt.legend()
    plt.tight_layout()
    plt.savefig(os.path.join(viz_dir, "size_comparison.png"))
    plt.close()

def generate_html_report(df, report_dir):
    total_files = len(df)
    total_original_size = df["original_size"].sum()
    total_new_size = df["new_size"].sum()
    total_saved = df["space_saved"].sum()
    avg_savings_percent = df["savings_percent"].mean()
    
    html_content = f"""
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 20px; }}
            .summary {{ background-color: #f5f5f5; padding: 20px; border-radius: 5px; }}
            .visualization {{ margin: 20px 0; }}
            table {{ border-collapse: collapse; width: 100%; }}
            th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
            th {{ background-color: #f2f2f2; }}
        </style>
    </head>
    <body>
        <h1>Monthly Image Optimization Report</h1>
        <div class="summary">
            <h2>Summary</h2>
            <p>Total Files Processed: {total_files}</p>
            <p>Total Original Size: {total_original_size:.2f} KB</p>
            <p>Total New Size: {total_new_size:.2f} KB</p>
            <p>Total Space Saved: {total_saved:.2f} KB</p>
            <p>Average Savings: {avg_savings_percent:.1f}%</p>
        </div>
        
        <div class="visualization">
            <h2>Space Savings Over Time</h2>
            <img src="visualizations/space_savings.png" alt="Space Savings">
        </div>
        
        <div class="visualization">
            <h2>Optimization Distribution</h2>
            <img src="visualizations/optimization_distribution.png" alt="Optimization Distribution">
        </div>
        
        <div class="visualization">
            <h2>Size Comparison</h2>
            <img src="visualizations/size_comparison.png" alt="Size Comparison">
        </div>
        
        <h2>Detailed Results</h2>
        <table>
            <tr>
                <th>Filename</th>
                <th>Original Size (KB)</th>
                <th>New Size (KB)</th>
                <th>Space Saved (KB)</th>
                <th>Savings %</th>
            </tr>
            {df.to_html(classes='table', index=False, columns=['filename', 'original_size', 'new_size', 'space_saved', 'savings_percent'])}
        </table>
    </body>
    </html>
    """
    
    with open(os.path.join(report_dir, "report.html"), "w") as f:
        f.write(html_content)

def send_email_report(report_dir):
    msg = MIMEMultipart()
    msg['From'] = EMAIL_CONFIG['sender_email']
    msg['To'] = EMAIL_CONFIG['recipient_email']
    msg['Subject'] = f"Image Optimization Report - {datetime.now().strftime('%B %Y')}"
    
    # Attach HTML report
    with open(os.path.join(report_dir, "report.html"), "r") as f:
        html_content = f.read()
    msg.attach(MIMEText(html_content, 'html'))
    
    # Attach visualizations
    for viz_file in os.listdir(os.path.join(report_dir, "visualizations")):
        with open(os.path.join(report_dir, "visualizations", viz_file), "rb") as f:
            attachment = MIMEApplication(f.read(), _subtype="png")
            attachment.add_header('Content-Disposition', 'attachment', filename=viz_file)
            msg.attach(attachment)
    
    # Send email
    with smtplib.SMTP(EMAIL_CONFIG['smtp_server'], EMAIL_CONFIG['smtp_port']) as server:
        server.starttls()
        server.login(EMAIL_CONFIG['sender_email'], EMAIL_CONFIG['sender_password'])
        server.send_message(msg)

def main():
    # Get current month's data
    current_date = datetime.now()
    # For testing, use 202506 to match the log file
    year_month = "202506"  # Hardcoded for live test
    
    # Create report directory
    report_dir = os.path.join(REPORT_DIR, year_month)
    os.makedirs(report_dir, exist_ok=True)
    
    # Process optimizer logs
    optimizer_log = os.path.join(LOG_DIR, f"optimizer_log_{year_month}.txt")
    if not os.path.exists(optimizer_log):
        print(f"No data found for {current_date.strftime('%Y-%m')}.")
        return
    
    df = parse_optimizer_log(optimizer_log)
    if df.empty:
        print(f"No optimization data found for {current_date.strftime('%Y-%m')}.")
        return
    
    # Generate report
    generate_visualizations(df, report_dir)
    generate_html_report(df, report_dir)
    
    # Send email
    try:
        send_email_report(report_dir)
        print(f"Report generated and sent for {current_date.strftime('%Y-%m')}.")
    except Exception as e:
        print(f"Error sending email: {str(e)}")

if __name__ == "__main__":
    main() 