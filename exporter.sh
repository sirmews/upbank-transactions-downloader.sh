#!/bin/bash

load_env() {
    if [ -f .env ]; then
        export $(grep -v '^#' .env | xargs)
    fi
}

load_env

# Check that jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq could not be found, please install it"
    exit 1
fi

# Read an .env file and then read in the start and end dates
AUTH_TOKEN=$AUTH_TOKEN
START_DATE=$START_DATE
END_DATE=$END_DATE

# Convert to timestamps for comparison (macOS)
START_TIMESTAMP=$(date -j -f "%Y-%m-%d" "$START_DATE" "+%s")
END_TIMESTAMP=$(date -j -f "%Y-%m-%d" "$END_DATE" "+%s")

# Current date starts at the beginning
CURRENT_DATE="$START_DATE"

# Loop through each month
while [ $(date -j -f "%Y-%m-%d" "$CURRENT_DATE" "+%s") -lt $END_TIMESTAMP ]; do
    # Format current date with UTC time
    SINCE_DATE="${CURRENT_DATE}T00:00:00Z"
    
    # Calculate next month date
    NEXT_DATE=$(date -j -v+1m -f "%Y-%m-%d" "$CURRENT_DATE" "+%Y-%m-%d")
    UNTIL_DATE="${NEXT_DATE}T00:00:00Z"
    
    # URL encode the colons in the dates
    SINCE_ENCODED=$(echo "$SINCE_DATE" | sed 's/:/%3A/g')
    UNTIL_ENCODED=$(echo "$UNTIL_DATE" | sed 's/:/%3A/g')
    
    echo "Fetching transactions from $SINCE_DATE to $UNTIL_DATE..."
    
    # Initialize page counter
    PAGE=1
    
    # Initial URL
    URL="https://api.up.com.au/api/v1/transactions?page[size]=100&filter[since]=$SINCE_ENCODED&filter[until]=$UNTIL_ENCODED"
    
    # Fetch all pages for this month
    while true; do
        # Make the curl request
        curl --location --globoff "$URL" \
            --header 'Accept: application/json' \
            --header "Authorization: Bearer $AUTH_TOKEN" \
            -o "transactions_${CURRENT_DATE}_page${PAGE}.json"
        
        echo "Saved to transactions_${CURRENT_DATE}_page${PAGE}.json"
        
        # Check if there's a next page
        NEXT_URL=$(jq -r '.links.next' "transactions_${CURRENT_DATE}_page${PAGE}.json")
        
        if [ "$NEXT_URL" == "null" ] || [ -z "$NEXT_URL" ]; then
            echo "No more pages for this month"
            break
        fi
        
        # Update URL for next page
        URL="$NEXT_URL"
        PAGE=$((PAGE + 1))
        
        # Add a small delay to avoid rate limiting
        sleep 2
    done
    
    # Combine all pages for this month into a single file
    if [ $PAGE -gt 1 ]; then
        echo "Combining pages for ${CURRENT_DATE}..."
        
        # Use jq to combine all pages
        jq -s '{
            data: map(.data[]) | flatten,
            links: .[0].links,
            meta: .[0].meta
        }' transactions_${CURRENT_DATE}_page*.json > "transactions_${CURRENT_DATE}_complete.json"
        
        # Remove individual page files
        rm transactions_${CURRENT_DATE}_page*.json
        
        echo "Combined file saved to transactions_${CURRENT_DATE}_complete.json"
    else
        # If only one page, just rename it
        mv "transactions_${CURRENT_DATE}_page1.json" "transactions_${CURRENT_DATE}_complete.json"
    fi
    
    echo "-------------------"
    
    # Move to next month
    CURRENT_DATE="$NEXT_DATE"
    
    # Add a delay before moving to next month. Again, this is to avoid rate limiting
    sleep 10
done

echo "All transactions downloaded!"