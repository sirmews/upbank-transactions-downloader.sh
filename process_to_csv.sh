#!/bin/bash

# Create CSV header with the desired column order
echo "date,total,category,attachments,notes" > all_transactions.csv

# Loop through all JSON files
for file in transactions_*.json; do
    echo "Processing $file..."
    
    # Extract data, filter out specified terms, and convert to CSV format
    jq -r '
        # Define array of terms to filter out
        def filter_terms: ["round up"];
        
        .data[].attributes | 
        select(
            ([.description, .rawText, .message] | 
            map(if . != null then (ascii_downcase | contains(filter_terms[]) | not) else true end) | 
            all)
        ) |
        [
            # date - using settledAt as the primary date
            .settledAt,
            
            # total - using amount.value
            .amount.value,
            
            # category - using description or rawText as category
            (.description // .rawText),
            
            # attachments - placeholder (empty for now as not in source data)
            "",
            
            # notes - using message field
            .message
        ] | @csv' "$file" >> all_transactions.csv
done

echo "All transactions exported to all_transactions.csv (filtered transactions excluded)"