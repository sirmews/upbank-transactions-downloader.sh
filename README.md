# Up Bank transactions downloader

Download transactions between two dates. Useful for getting a historical list when navigating the app is too troublesome.

In order to use it:

- Copy .env.example into a .env
- Add your `AUTH_TOKEN`, `START_DATE` and `END_DATE`
- run `./downloader.sh` to start downloading transactions.
- (optional) run `./process_to_csv.sh` to turn it into a csv file

Note:
- This doesn't download per specified account
- The CSV process function strips out `round ups` and provides a simpler output that works specifically for me. Fork it and adjust for yourself.
- This doesn't do any post processing (though I'm open to PRs with suggestions)

## Where do I find my API key?

[Official page](https://api.up.com.au/getting_started)

## What if I mess it up?

There's no ability to make a transaction, you're fine. Worst that can happen is you run the script too often and get rate limited.
There's far worse things like knowing you have to do taxes again in a year.

## Is this vibe coded?

No, but I did ask Claude's AI for assistance. Specifically to help with `jq`, date formatting and suggestions on how to best deal with the 100 max size limit.
If you want assistance from an AI, there's a prompt that can assist you.