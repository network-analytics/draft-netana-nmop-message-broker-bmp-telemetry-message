#!/usr/bin/env bash
# Bump the revision date of this draft's YANG modules (single revision
# statement per module): renames yang/<module>@<old>.yang, updates the
# revision statement, yang/yang-lib-bmptm.xml, the sourcecode name and
# include path in the latest draft XML and the draft <date>, then runs
# ./validate.sh, refreshes the <!-- src: FILE --> marked CDATA blocks
# from the YANG/example files and regenerates the draft .txt with xml2rfc.
#
# Usage: ./bump-revision.sh [-d YYYY-MM-DD] [module ...]
#   -d       new revision date (default: today)
#   module   module names, e.g. ietf-bmp-tlv (default: all yang/ietf-*.yang)
set -euo pipefail
cd "$(dirname "$0")"

YANG_DIR="yang"
YANG_LIB="${YANG_DIR}/yang-lib-bmptm.xml"
DRAFT_XML=$(ls draft-*-[0-9][0-9].xml | sort | tail -1)
NEW=$(date +%F)

while getopts "d:" opt; do
  case "$opt" in
    d) NEW="$OPTARG" ;;
    *) echo "Usage: $0 [-d YYYY-MM-DD] [module ...]" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

[[ "$NEW" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { echo "Bad date: $NEW" >&2; exit 1; }

if [[ $# -eq 0 ]]; then
  mapfile -t MODULES < <(ls "${YANG_DIR}"/ietf-*@*.yang | xargs -n1 basename | sed 's/@.*//' | sort -u)
else
  MODULES=("$@")
fi

for mod in "${MODULES[@]}"; do
  files=("${YANG_DIR}/${mod}"@*.yang)
  [[ -e "${files[0]}" ]] || { echo "No file for ${mod}" >&2; exit 1; }
  [[ ${#files[@]} -eq 1 ]] || { echo "Multiple files for ${mod}: ${files[*]}" >&2; exit 1; }
  old_file="${files[0]}"
  old=$(basename "$old_file" .yang); old="${old#*@}"
  new_file="${YANG_DIR}/${mod}@${NEW}.yang"

  if [[ "$old" == "$NEW" ]]; then
    echo "  ${mod}: already ${NEW}"
    continue
  fi

  if git ls-files --error-unmatch "$old_file" >/dev/null 2>&1; then
    git mv "$old_file" "$new_file"
  else
    mv "$old_file" "$new_file"
  fi
  sed -i "s/^\(\s*revision\s\+\)${old}\(\s*{\)/\1${NEW}\2/" "$new_file"

  # <name>mod</name> followed by <revision>old</revision>
  perl -0pi -e "s|(<name>\Q${mod}\E</name>\s*<revision>)\Q${old}\E(</revision>)|\${1}${NEW}\${2}|" "$YANG_LIB"

  # sourcecode name="mod@old.yang" and <!-- src: yang/mod@old.yang -->
  sed -i "s#\([\"/]\)${mod}@${old}\.yang\([\" ]\)#\1${mod}@${NEW}.yang\2#g" "$DRAFT_XML"

  echo "  ${mod}: ${old} -> ${NEW}"
done

MONTHS=(January February March April May June July August September
        October November December)
year=${NEW:0:4}; month=${MONTHS[$((10#${NEW:5:2} - 1))]}; day=$((10#${NEW:8:2}))
perl -pi -e "s|<date day=\"\d+\" month=\"\w+\" year=\"\d{4}\" />|<date day=\"${day}\" month=\"${month}\" year=\"${year}\" />|" "$DRAFT_XML"
echo "  draft date: ${day} ${month} ${year}"

./validate.sh

# Refresh each CDATA block preceded by <!-- src: FILE --> with FILE's content
perl -0pi -e '
  sub slurp {
    open my $f, "<", $_[0] or die "$_[0]: $!\n"; local $/; my $c = <$f>;
    die "$_[0] contains ]]>\n" if $c =~ /\]\]>/;
    $c .= "\n" unless $c =~ /\n\z/;
    $c;
  }
  s{(<!-- src: (\S+) -->\s*<sourcecode[^>]*><!\[CDATA\[\n).*?(\]\]></sourcecode>)}{$1 . slurp($2) . $3}gse;
' "$DRAFT_XML"
echo "  synced CDATA blocks: $(grep -c '<!-- src: ' "$DRAFT_XML")"

xml2rfc --allow-local-file-access --text "$DRAFT_XML"
echo "Updated ${YANG_LIB}, ${DRAFT_XML} and ${DRAFT_XML%.xml}.txt"
