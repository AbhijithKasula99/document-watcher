# archive_file() {
#    mv "$1" archive/
#}

#touch tester.txt

#archive_file tester.txt

discover_files() {
	find "$1" -type f
}

#discover_files "incoming" | while read -r file ; do
#	echo "Found: $file"
#done


SUCCESS_COUNT=0

while read -r file; do
    ((++SUCCESS_COUNT))
    echo "Inside loop: $SUCCESS_COUNT"
done < <(discover_files "incoming")

echo "Outside loop: $SUCCESS_COUNT"
