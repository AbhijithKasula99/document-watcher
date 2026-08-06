get_file_type() {
    case "$1" in
        *.pdf) echo "PDF" ;;
        *.png) echo "PNG" ;;
        *.txt) echo "TXT" ;;
        *)     echo "UNKNOWN" ;;
    esac
}

get_file_type 1.pdf
get_file_type 2.png
get_file_type 3.txt
get_file_type 4.zip
