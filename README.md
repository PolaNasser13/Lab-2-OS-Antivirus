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
├── cron.log             Bonus 1: output of the cron job (made by cron)
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

`antivirus-cron.sh` does the same scan as `antivirusd.sh`, but it runs **one
time and stops** (no `while true`, no `sleep` loop). Cron starts it again every
minute.

```
./antivirus-cron.sh dir malicious_dir
```

### What each `*` means

A crontab line has 5 time fields, then the command. Each `*` means "every value".

```
* * * * *  command
│ │ │ │ │
│ │ │ │ └── 5th: day of week   (0-7, Friday = 5)
│ │ │ └──── 4th: month         (1-12)
│ │ └────── 3rd: day of month  (1-31)
│ └──────── 2nd: hour          (0-23)
└────────── 1st: minute        (0-59)
```

So `* * * * *` = every minute, of every hour, of every day, of every month,
on every week day. In short: **every minute**.

In the 3rd Friday line `31 0 15-21 * *`:

| Field | Value | Meaning |
|---|---|---|
| minute | `31` | minute 31 |
| hour | `0` | hour 0 (12 AM) |
| day of month | `15-21` | only the 15th to the 21st |
| month | `*` | every month |
| day of week | `*` | any day (Friday is checked inside the command) |

### The first line of the script: `cd "$(dirname "$0")" || exit 1`

- `$0` = the path used to start the script.
- `dirname` = keeps only the folder part of that path.
- `$( ... )` = runs the command and uses its result.
- `cd` = goes into that folder.
- `|| exit 1` = if `cd` fails, stop the script with an error.

Why: cron starts the script from another folder (your home), but the script uses
the relative files `directory-info.new`, `directory-info.last` and
`whitelist.txt`. With the `cd`, it always works inside the project folder.
Because of this, always give the script **full paths** as arguments.

### Prerequisites

1. cron installed and running:
   ```
   sudo apt update
   sudo apt install cron
   sudo systemctl enable --now cron
   systemctl status cron
   ```
   You must see `active (running)`. Press `q` to leave the screen.
2. Script is executable: `chmod +x antivirus-cron.sh`
3. Folders exist: `mkdir -p test_dir quarantine`
   (if `test_dir` is missing, `cron.log` shows `is not a folder`)
4. Full path of the project: run `pwd`. Mine is
   `/home/pola-nasser13/Desktop/OS Antivirus`. The name has a **space**, so
   every path in the crontab line is between quotes `" "`.
5. Stop `make` (`Ctrl + C`) first. Do not run it with cron together.

### Steps

1. Go to the project folder and make test files:
   ```
   cd "$HOME/Desktop/OS Antivirus"
   mkdir -p test_dir quarantine
   echo "hello" > test_dir/safe.txt
   echo "this is a virus" > test_dir/bad.txt
   touch test_dir/game.exe
   ```
2. Test the script by hand first:
   ```
   ./antivirus-cron.sh "$PWD/test_dir" "$PWD/quarantine"
   ls test_dir quarantine
   ```
   `bad.txt` and `game.exe` must move to `quarantine`.
3. Open the crontab:
   ```
   crontab -e
   ```
   First time: type `1` (nano) and press `Enter`.
4. Go to the last line with the `Down` arrow key and paste this **one line**
   (`Ctrl + Shift + V`). Change the path to yours:
   ```
   * * * * * sleep 23; "/home/pola-nasser13/Desktop/OS Antivirus/antivirus-cron.sh" "/home/pola-nasser13/Desktop/OS Antivirus/test_dir" "/home/pola-nasser13/Desktop/OS Antivirus/quarantine" >> "/home/pola-nasser13/Desktop/OS Antivirus/cron.log" 2>&1
   ```
5. Save and exit: `Ctrl + O`, then `Enter`, then `Ctrl + X`.
   You must see `crontab: installing new crontab`.
6. Check it is saved: `crontab -l`
7. Test it:
   ```
   echo "this is a trojan" > test_dir/cron_test.txt
   tail -f cron.log
   ```
   Wait up to about a minute and a half. You will see
   `cron_test.txt is malicious and it is DELETED`. Press `Ctrl + C` to leave
   `tail`. The file must now be in `quarantine`.
8. Stop the job when you finish (or it keeps running every minute):
   ```
   crontab -l | grep -v "antivirus-cron.sh" | crontab -
   ```
   (or `crontab -e`, move to the line, `Ctrl + K` to cut it, then save.)

### Why `sleep 23` (run at second 23)

Cron cannot run at a second. Its smallest unit is **one minute**. So:

- `* * * * *` starts the line every minute (at second 0),
- `sleep 23;` waits 23 seconds,
- then the script runs, so it runs at second 23.

```
14:07:00  cron starts the line, sleep 23 starts
14:07:23  the script runs
14:08:00  cron starts the line again
```

The rest of the line: `"…/antivirus-cron.sh"` is the script, `"…/test_dir"` and
`"…/quarantine"` are its two arguments, `>> "…/cron.log"` saves the output in a
file (cron has no screen), and `2>&1` saves the errors in the same file.

Check the second (it can be 24 or 25, because cron may start a second or two
late after the minute begins):
```
echo "a virus" > test_dir/t1.txt
sleep 75
ls -l --time-style=full-iso quarantine/t1.txt
```

### Cron expression: every 3rd Friday of the month at 12:31 AM

```
31 0 15-21 * * [ "$(date +\%u)" -eq 5 ] && "/home/pola-nasser13/Desktop/OS Antivirus/antivirus-cron.sh" "/home/pola-nasser13/Desktop/OS Antivirus/test_dir" "/home/pola-nasser13/Desktop/OS Antivirus/quarantine"
```

- `31 0` = 12:31 AM.
- `15-21`: the 3rd Friday is always between the 15th and the 21st (1st Friday:
  days 1-7, 2nd: 8-14, 3rd: 15-21).
- `date +%u` gives the week day number (Monday = 1, Friday = 5). The check
  `-eq 5` keeps only Friday, and `&&` runs the script only if it is Friday.
- `\%` instead of `%`, because `%` has a special meaning in a crontab.
- Not `31 0 15-21 * 5`, because when both the day of month and the day of week
  are set, cron runs when **either one** matches (OR). It would run on every
  Friday and on every day from the 15th to the 21st.

To use it, put it in the crontab **instead of** the every-minute line.

Test the idea (you cannot wait a month). This prints 12 dates, one Friday for
each month of 2026:
```
for m in $(seq 1 12); do for d in $(seq 15 21); do [ "$(date -d "2026-$m-$d" +%u)" -eq 5 ] && echo "2026-$m-$d"; done; done
```

### Quick tests and problems

- No change in `test_dir` = no scan. `wc -l cron.log` stays the same after 2
  minutes.
- Safe files stay in `test_dir`. Bad ones (`.exe .bat .vbs .scr .ps1`, or the
  words `virus trojan malware worm ransomware`) go to `quarantine`.

| Problem | Fix |
|---|---|
| Nothing happens | `systemctl status cron` and `crontab -l` |
| `Permission denied` in `cron.log` | `chmod +x antivirus-cron.sh` |
| `No such file or directory` | use full paths with quotes |
| `is not a folder` | `mkdir -p test_dir quarantine` |
| Works by hand, not in cron | read `cron.log`, the error is there |

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