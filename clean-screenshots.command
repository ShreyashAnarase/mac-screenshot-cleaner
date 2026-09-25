#!/bin/zsh

# Review screenshot files on the Desktop and move selected ones to Trash.
# Files are never permanently deleted by this script.

set -u
setopt pipe_fail

desktop_dir="${1:-$HOME/Desktop}"

if [[ ! -d "$desktop_dir" ]]; then
  print -u2 "Folder not found: $desktop_dir"
  exit 1
fi

typeset -a screenshots
typeset -a marked_for_deletion

# Match both current ("Screenshot …") and older ("Screen Shot …") macOS names.
while IFS= read -r -d '' screenshot; do
  screenshots+=("$screenshot")
done < <(
  find "$desktop_dir" -maxdepth 1 -type f \
    \( -iname 'Screenshot *' -o -iname 'Screen Shot *' \) \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \
       -o -iname '*.heic' -o -iname '*.tif' -o -iname '*.tiff' \
       -o -iname '*.gif' -o -iname '*.webp' \) \
    -print0
)

total=${#screenshots[@]}

if (( total == 0 )); then
  print "No macOS screenshot files were found directly in:"
  print "  $desktop_dir"
  print
  print "This looks for files whose names begin with 'Screenshot ' or 'Screen Shot '."
  read -r "reply?Press Return to close."
  exit 0
fi

close_preview_document() {
  local target_path="$1"

  /usr/bin/osascript - "$target_path" >/dev/null 2>&1 <<'APPLESCRIPT'
on run argv
  set targetPath to item 1 of argv
  tell application "Preview"
    repeat with previewDocument in documents
      try
        if (path of previewDocument as text) is targetPath then
          close previewDocument saving no
          exit repeat
        end if
      end try
    end repeat
  end tell
end run
APPLESCRIPT
}

cleanup_current_preview() {
  if [[ -n "${current_file:-}" ]]; then
    close_preview_document "$current_file"
  fi
}

trap 'exit 130' INT TERM
trap cleanup_current_preview EXIT

print "Found $total screenshot(s)."
print "Preview will show each one. Return to this window to press a key."
print
read -r "reply?Press Return to begin."

index=1
for current_file in "${screenshots[@]}"; do
  /usr/bin/open -a Preview "$current_file"

  while true; do
    print
    print "[$index/$total] ${current_file:t}"
    read -r "choice?[k]eep  [d]elete later  [q]uit reviewing: "

    case "${choice:l}" in
      k|"")
        break
        ;;
      d)
        marked_for_deletion+=("$current_file")
        break
        ;;
      q)
        close_preview_document "$current_file"
        current_file=""
        break 2
        ;;
      *)
        print "Please enter k, d, or q."
        ;;
    esac
  done

  close_preview_document "$current_file"
  current_file=""
  (( index++ ))
done

current_file=""
trap - INT TERM EXIT

marked_total=${#marked_for_deletion[@]}

if (( marked_total == 0 )); then
  print
  print "Done. No screenshots were marked for deletion."
  read -r "reply?Press Return to close."
  exit 0
fi

print
print "$marked_total screenshot(s) marked for Trash:"
for screenshot in "${marked_for_deletion[@]}"; do
  print "  - ${screenshot:t}"
done

print
read -r "confirm?Move these files to Trash? [y/N]: "
if [[ "${confirm:l}" != "y" && "${confirm:l}" != "yes" ]]; then
  print "Cancelled. No files were moved."
  read -r "reply?Press Return to close."
  exit 0
fi

moved=0
failed=0
for screenshot in "${marked_for_deletion[@]}"; do
  if /usr/bin/osascript - "$screenshot" >/dev/null <<'APPLESCRIPT'
on run argv
  -- Resolve the POSIX path outside Finder's scope. Otherwise Finder tries to
  -- interpret "POSIX file" as one of its own objects and returns error -1728.
  set targetPath to item 1 of argv
  set targetFile to (POSIX file targetPath) as alias
  tell application "Finder" to delete targetFile
end run
APPLESCRIPT
  then
    (( moved++ ))
  else
    print -u2 "Could not move to Trash: ${screenshot:t}"
    (( failed++ ))
  fi
done

print
print "Moved $moved screenshot(s) to Trash."
if (( failed > 0 )); then
  print "$failed file(s) could not be moved."
fi
print "You can recover moved files from Trash until it is emptied."
read -r "reply?Press Return to close."
