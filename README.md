# Lab-2-OS-Antivirus
A small antivirus made with Bash scripts.
It watches a folder and moves bad files to a quarantine folder.

## Folder hierarchy

```
OS Antivirus/
├── antivirusd.sh        the antivirus (runs in a loop)
├── restore.sh           review the quarantine files
├── antivirus-cron.sh    Bonus 1: same scan, but runs once (for cron)
├── Makefile             make / make restore
├── README.md
├── test_dir/            watched folder (made automatically)
├── quarantine/          bad files go here (made automatically)
├── directory-info.last  old snapshot (made automatically)
├── directory-info.new   new snapshot (made automatically)
└── whitelist.txt        Bonus 2: safe files (made automatically)
```

## Prerequisites (Ubuntu)

```
sudo apt update
sudo apt install make cron
```

Then give the scripts permission to run:

```
chmod +x antivirusd.sh restore.sh antivirus-cron.sh
```

## Run the antivirus

1. Open a terminal in the project folder and type:
   ```
   make
   ```
   It creates the folders and checks `test_dir` every 5 seconds.
   To change the time: `make interval=2`

2. Open a second terminal in the same folder and add some files:
   ```
   echo "hello" > test_dir/safe.txt
   echo "this is a virus" > test_dir/bad.txt
   touch test_dir/game.exe
   ```

3. The first terminal prints:
   ```
   bad.txt is malicious and it is DELETED
   game.exe is malicious and it is DELETED
   ```

4. Check the folders:
   ```
   ls test_dir
   ls quarantine
   ```

5. Press `Ctrl + C` in the first terminal to stop it.

## Run the restore tool

Stop the antivirus first. Do not run both together.

```
make restore
```

1. It shows the files in quarantine with numbers.
2. Type the number of a file.
3. Then type:
   - `1` = restore the file back to `test_dir`
   - `2` = delete the file forever
   - `3` = leave it and go back to the list
4. Type `q` to quit.

If quarantine is empty, it prints `No malicious files to review.`

## Where the flagged lists are

In `antivirusd.sh`, near the top:

```
badFiles='\.(exe|bat|vbs|scr|ps1)$'
badWords='virus|trojan|malware|worm|ransomware'
```

- `badFiles` = flagged extensions
- `badWords` = flagged keywords

The same two lines are in `antivirus-cron.sh`.

## Bonus 1: Cron job

`antivirus-cron.sh` scans one time and stops. Cron runs it again every minute.

Usage:
```
./antivirus-cron.sh dir malicious_dir
```

### Before you start

1. Make sure cron is installed and running:
   ```
   sudo apt install cron
   sudo systemctl enable --now cron
   systemctl status cron
   ```
   It must say `active (running)`.
2. Make the script executable: `chmod +x antivirus-cron.sh`
3. Cron needs the full path. Get it with `pwd`.
   Mine is `/home/pola-nasser13/Desktop/OS Antivirus`.
   The folder name has a space, so every path is between quotes.

### Steps

1. Test the script by hand first:
   ```
   mkdir -p test_dir quarantine
   echo "virus" > test_dir/x.txt
   ./antivirus-cron.sh "$PWD/test_dir" "$PWD/quarantine"
   ```
2. Open the crontab:
   ```
   crontab -e
   ```
3. Add this line at the end (use your own path):
   ```
   * * * * * sleep 23; "/home/pola-nasser13/Desktop/OS Antivirus/antivirus-cron.sh" "/home/pola-nasser13/Desktop/OS Antivirus/test_dir" "/home/pola-nasser13/Desktop/OS Antivirus/quarantine" >> "/home/pola-nasser13/Desktop/OS Antivirus/cron.log" 2>&1
   ```
   Cron can only run every minute, not at a second.
   So it starts every minute and `sleep 23` waits until second 23.
   The output goes to `cron.log`.
4. Save and exit (in nano: `Ctrl+O`, `Enter`, `Ctrl+X`).
5. Check it is saved: `crontab -l`
6. Test it. Add a bad file and wait one minute:
   ```
   echo "trojan" > test_dir/cron_test.txt
   cat cron.log
   ```
7. To stop it: `crontab -e` and delete the line.

### Cron expression: every 3rd Friday of the month at 12:31 AM

```
31 0 15-21 * * [ "$(date +\%u)" -eq 5 ] && "/home/pola-nasser13/Desktop/OS Antivirus/antivirus-cron.sh" "/home/pola-nasser13/Desktop/OS Antivirus/test_dir" "/home/pola-nasser13/Desktop/OS Antivirus/quarantine"
```

- `31 0` = 12:31 AM
- `15-21` = the 3rd Friday is always between the 15th and the 21st
- `date +%u` gives 5 on Friday. In crontab `%` must be written `\%`.
- I did not write `31 0 15-21 * 5` because cron then runs when the day
  of the month OR the weekday matches. That would run on every Friday too.

## Bonus 2: Whitelist

**How a file is added:**
In `restore.sh`, when you choose `1` (restore), the file is moved back and
its name is added to `whitelist.txt`:
```
echo "$name" >> whitelist.txt
```

**How the daemon checks it:**
In the `scan` function of `antivirusd.sh`, before checking a file:
```
if cat whitelist.txt | grep -x -F -q -- "$name"; then
    continue
fi
```
If the name is in the list, the file is skipped, even if it has a bad
extension or a bad word.

`whitelist.txt` is a normal file, so it is still there when the antivirus is
stopped and started again.

Note: only the file name is saved. Run the scripts from the project folder so
they use the same `whitelist.txt`.