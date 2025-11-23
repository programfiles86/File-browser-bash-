#!/bin/bash

VERSION="2.0"
CURRENT_DIR="$HOME"
SELECTED_FILE=""
CLIPBOARD=""
CLIPBOARD_OP=""
SEARCH_RESULTS=()
SEARCH_INDEX=0

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m'

clear_screen() {
    clear
}

show_header() {
    echo -e "${CYAN}┌────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│           TERMUX FILE MANAGER           │${NC}"
    echo -e "${CYAN}│                   v$VERSION                │${NC}"
    echo -e "${CYAN}└────────────────────────────────────────┘${NC}"
    echo -e "${YELLOW}Location: $CURRENT_DIR${NC}"
    if [ ${#SEARCH_RESULTS[@]} -gt 0 ]; then
        echo -e "${MAGENTA}Search: ${#SEARCH_RESULTS[@]} results found${NC}"
    fi
    echo
}

list_files() {
    local i=0
    echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│ ../  Parent directory                  │${NC}"
    
    if [ ${#SEARCH_RESULTS[@]} -gt 0 ]; then
        for item in "${SEARCH_RESULTS[@]}"; do
            ((i++))
            local name=$(basename "$item")
            local size=$(du -sh "$item" 2>/dev/null | cut -f1)
            if [[ -d "$item" ]]; then
                if [[ "$item" == "$SELECTED_FILE" ]]; then
                    printf "${BLUE}│${GREEN} ▷ [%-28s] ${BLUE}│${NC}\n" "$name"
                else
                    printf "${BLUE}│   [%-28s]   ${BLUE}│${NC}\n" "$name"
                fi
            else
                if [[ "$item" == "$SELECTED_FILE" ]]; then
                    printf "${BLUE}│${GREEN} ▷ %-25s %8s ${BLUE}│${NC}\n" "$name" "$size"
                else
                    printf "${BLUE}│   %-25s %8s ${BLUE}│${NC}\n" "$name" "$size"
                fi
            fi
        done
    else
        for item in "$CURRENT_DIR"/*; do
            if [[ -e "$item" ]]; then
                ((i++))
                local name=$(basename "$item")
                local size=$(du -sh "$item" 2>/dev/null | cut -f1)
                if [[ -d "$item" ]]; then
                    if [[ "$item" == "$SELECTED_FILE" ]]; then
                        printf "${BLUE}│${GREEN} ▷ [%-28s] ${BLUE}│${NC}\n" "$name"
                    else
                        printf "${BLUE}│   [%-28s]   ${BLUE}│${NC}\n" "$name"
                    fi
                else
                    if [[ "$item" == "$SELECTED_FILE" ]]; then
                        printf "${BLUE}│${GREEN} ▷ %-25s %8s ${BLUE}│${NC}\n" "$name" "$size"
                    else
                        printf "${BLUE}│   %-25s %8s ${BLUE}│${NC}\n" "$name" "$size"
                    fi
                fi
            fi
        done
    fi
    
    if [[ $i -eq 0 ]]; then
        echo -e "${BLUE}│           No files found              │${NC}"
    fi
    echo -e "${BLUE}└────────────────────────────────────────┘${NC}"
}

show_menu() {
    echo
    echo -e "${YELLOW}┌────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│                 MENU                   │${NC}"
    echo -e "${YELLOW}├────────────────────────────────────────┤${NC}"
    echo -e "${YELLOW}│  1 Open       2 New File   3 New Dir   │${NC}"
    echo -e "${YELLOW}│  4 Copy       5 Cut        6 Paste     │${NC}"
    echo -e "${YELLOW}│  7 Delete     8 Rename     9 Properties│${NC}"
    echo -e "${YELLOW}│  s Select     f Find       n Next      │${NC}"
    echo -e "${YELLOW}│  e Edit       v View       c Clear     │${NC}"
    echo -e "${YELLOW}│  0 Exit                                │${NC}"
    
    if [[ -n "$CLIPBOARD" ]]; then
        local op="COPY"
        [[ "$CLIPBOARD_OP" == "cut" ]] && op="MOVE"
        echo -e "${YELLOW}├────────────────────────────────────────┤${NC}"
        echo -e "${YELLOW}│  ${GREEN}$op: $(basename "$CLIPBOARD")${YELLOW}                   │${NC}"
    fi
    
    if [ ${#SEARCH_RESULTS[@]} -gt 0 ]; then
        echo -e "${YELLOW}├────────────────────────────────────────┤${NC}"
        echo -e "${YELLOW}│  ${MAGENTA}SEARCH: $((SEARCH_INDEX + 1))/${#SEARCH_RESULTS[@]} results${YELLOW}     │${NC}"
    fi
    
    echo -e "${YELLOW}└────────────────────────────────────────┘${NC}"
    echo
    echo -n "Choose option: "
}

get_input() {
    echo -ne "${GREEN}$1${NC}"
    read -r input
    echo "$input"
}

show_msg() {
    echo
    echo -e "${GREEN}┌────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│               MESSAGE                  │${NC}"
    echo -e "${GREEN}├────────────────────────────────────────┤${NC}"
    echo -e "${GREEN}│   $1${NC}"
    echo -e "${GREEN}└────────────────────────────────────────┘${NC}"
    echo
    echo "Press Enter..."
    read -r
}

show_error() {
    echo
    echo -e "${RED}┌────────────────────────────────────────┐${NC}"
    echo -e "${RED}│                 ERROR                  │${NC}"
    echo -e "${RED}├────────────────────────────────────────┤${NC}"
    echo -e "${RED}│   $1${NC}"
    echo -e "${RED}└────────────────────────────────────────┘${NC}"
    echo
    echo "Press Enter..."
    read -r
}

open_item() {
    if [[ -z "$SELECTED_FILE" ]]; then
        show_error "Nothing selected"
        return
    fi
    
    if [[ "$SELECTED_FILE" == "$CURRENT_DIR/.." ]]; then
        CURRENT_DIR=$(dirname "$CURRENT_DIR")
        SELECTED_FILE=""
        SEARCH_RESULTS=()
        return
    fi
    
    if [[ -d "$SELECTED_FILE" ]]; then
        CURRENT_DIR="$SELECTED_FILE"
        SELECTED_FILE=""
        SEARCH_RESULTS=()
    else
        if command -v termux-open >/dev/null 2>&1; then
            termux-open "$SELECTED_FILE"
            show_msg "Opening: $(basename "$SELECTED_FILE")"
        else
            show_msg "File: $(basename "$SELECTED_FILE")"
        fi
    fi
}

create_file() {
    local name=$(get_input "File name: ")
    if [[ -z "$name" ]]; then
        show_error "Need a name"
        return
    fi
    
    local file_path="$CURRENT_DIR/$name"
    if touch "$file_path" 2>/dev/null; then
        show_msg "Created file: $name"
        SELECTED_FILE="$file_path"
    else
        show_error "Cannot create: $name"
    fi
}

create_dir() {
    local name=$(get_input "Directory name: ")
    if [[ -z "$name" ]]; then
        show_error "Need a name"
        return
    fi
    
    local dir_path="$CURRENT_DIR/$name"
    if mkdir "$dir_path" 2>/dev/null; then
        show_msg "Created directory: $name"
        SELECTED_FILE="$dir_path"
    else
        show_error "Cannot create: $name"
    fi
}

copy_file() {
    if [[ -z "$SELECTED_FILE" ]]; then
        show_error "Nothing selected"
        return
    fi
    
    if [[ "$SELECTED_FILE" == "$CURRENT_DIR/.." ]]; then
        show_error "Cannot copy parent directory"
        return
    fi
    
    CLIPBOARD="$SELECTED_FILE"
    CLIPBOARD_OP="copy"
    show_msg "Copied: $(basename "$SELECTED_FILE")"
}

cut_file() {
    if [[ -z "$SELECTED_FILE" ]]; then
        show_error "Nothing selected"
        return
    fi
    
    if [[ "$SELECTED_FILE" == "$CURRENT_DIR/.." ]]; then
        show_error "Cannot cut parent directory"
        return
    fi
    
    CLIPBOARD="$SELECTED_FILE"
    CLIPBOARD_OP="cut"
    show_msg "Cut: $(basename "$SELECTED_FILE")"
}

paste_file() {
    if [[ -z "$CLIPBOARD" ]]; then
        show_error "Clipboard empty"
        return
    fi
    
    local source="$CLIPBOARD"
    local destination="$CURRENT_DIR/$(basename "$CLIPBOARD")"
    
    if [[ "$source" == "$destination" ]]; then
        show_error "Cannot paste to same location"
        return
    fi
    
    if [[ "$CLIPBOARD_OP" == "copy" ]]; then
        if cp -r "$source" "$destination" 2>/dev/null; then
            show_msg "Pasted: $(basename "$CLIPBOARD")"
            SELECTED_FILE="$destination"
        else
            show_error "Paste failed"
        fi
    elif [[ "$CLIPBOARD_OP" == "cut" ]]; then
        if mv "$source" "$destination" 2>/dev/null; then
            show_msg "Moved: $(basename "$CLIPBOARD")"
            SELECTED_FILE="$destination"
            CLIPBOARD=""
            CLIPBOARD_OP=""
        else
            show_error "Move failed"
        fi
    fi
}

delete_file() {
    if [[ -z "$SELECTED_FILE" ]]; then
        show_error "Nothing selected"
        return
    fi
    
    if [[ "$SELECTED_FILE" == "$CURRENT_DIR/.." ]]; then
        show_error "Cannot delete parent directory"
        return
    fi
    
    local name=$(basename "$SELECTED_FILE")
    echo -ne "${RED}Delete '$name'? (y/N): ${NC}"
    read -r confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        if rm -rf "$SELECTED_FILE" 2>/dev/null; then
            show_msg "Deleted: $name"
            SELECTED_FILE=""
        else
            show_error "Delete failed: $name"
        fi
    fi
}

rename_file() {
    if [[ -z "$SELECTED_FILE" ]]; then
        show_error "Nothing selected"
        return
    fi
    
    if [[ "$SELECTED_FILE" == "$CURRENT_DIR/.." ]]; then
        show_error "Cannot rename parent directory"
        return
    fi
    
    local old_name=$(basename "$SELECTED_FILE")
    local new_name=$(get_input "Rename '$old_name' to: ")
    
    if [[ -z "$new_name" ]]; then
        show_error "Need a new name"
        return
    fi
    
    local new_path="$CURRENT_DIR/$new_name"
    if mv "$SELECTED_FILE" "$new_path" 2>/dev/null; then
        show_msg "Renamed: $old_name → $new_name"
        SELECTED_FILE="$new_path"
    else
        show_error "Rename failed"
    fi
}

show_properties() {
    if [[ -z "$SELECTED_FILE" ]]; then
        show_error "Nothing selected"
        return
    fi
    
    local name=$(basename "$SELECTED_FILE")
    local size=$(du -sh "$SELECTED_FILE" 2>/dev/null | cut -f1)
    local type="File"
    [[ -d "$SELECTED_FILE" ]] && type="Directory"
    local perms=$(stat -c "%A" "$SELECTED_FILE" 2>/dev/null || ls -ld "$SELECTED_FILE" | cut -d' ' -f1)
    
    echo
    echo -e "${CYAN}┌────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│               PROPERTIES               │${NC}"
    echo -e "${CYAN}├────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│   Name: $name${NC}"
    echo -e "${CYAN}│   Type: $type${NC}"
    echo -e "${CYAN}│   Size: $size${NC}"
    echo -e "${CYAN}│   Perm: $perms${NC}"
    echo -e "${CYAN}│   Path: $SELECTED_FILE${NC}"
    echo -e "${CYAN}└────────────────────────────────────────┘${NC}"
    echo
    echo "Press Enter..."
    read -r
}

select_file() {
    local items=()
    items+=("..")
    
    for item in "$CURRENT_DIR"/*; do
        if [[ -e "$item" ]]; then
            items+=("$(basename "$item")")
        fi
    done
    
    echo
    echo -e "${YELLOW}Choose file:${NC}"
    echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
    
    for ((i=0; i<${#items[@]}; i++)); do
        local item="${items[$i]}"
        local full_path="$CURRENT_DIR/$item"
        local display_name="$item"
        
        if [[ -d "$full_path" && "$item" != ".." ]]; then
            display_name="[$item]"
        fi
        
        if [[ "$full_path" == "$SELECTED_FILE" ]]; then
            printf "${BLUE}│${GREEN} %2d ▷ %-30s ${BLUE}│${NC}\n" $i "$display_name"
        else
            printf "${BLUE}│  %2d   %-30s ${BLUE}│${NC}\n" $i "$display_name"
        fi
    done
    
    echo -e "${BLUE}└────────────────────────────────────────┘${NC}"
    echo
    echo -n "Enter number (or Enter to cancel): "
    read -r choice
    
    if [[ -n "$choice" && "$choice" =~ ^[0-9]+$ ]]; then
        if [[ $choice -lt ${#items[@]} ]]; then
            local selected="${items[$choice]}"
            if [[ "$selected" == ".." ]]; then
                SELECTED_FILE="$CURRENT_DIR/.."
            else
                SELECTED_FILE="$CURRENT_DIR/$selected"
            fi
            show_msg "Selected: $(basename "$SELECTED_FILE")"
        else
            show_error "Invalid number"
        fi
    fi
}

find_files() {
    local pattern=$(get_input "Search for: ")
    if [[ -z "$pattern" ]]; then
        SEARCH_RESULTS=()
        SEARCH_INDEX=0
        return
    fi
    
    SEARCH_RESULTS=()
    SEARCH_INDEX=0
    
    while IFS= read -r -d '' result; do
        SEARCH_RESULTS+=("$result")
    done < <(find "$CURRENT_DIR" -name "*$pattern*" -print0 2>/dev/null)
    
    if [ ${#SEARCH_RESULTS[@]} -gt 0 ]; then
        SELECTED_FILE="${SEARCH_RESULTS[0]}"
        show_msg "Found ${#SEARCH_RESULTS[@]} results"
    else
        show_error "No matches found"
    fi
}

next_result() {
    if [ ${#SEARCH_RESULTS[@]} -eq 0 ]; then
        show_error "No search results"
        return
    fi
    
    SEARCH_INDEX=$(( (SEARCH_INDEX + 1) % ${#SEARCH_RESULTS[@]} ))
    SELECTED_FILE="${SEARCH_RESULTS[$SEARCH_INDEX]}"
    show_msg "Result $((SEARCH_INDEX + 1))/${#SEARCH_RESULTS[@]}"
}

view_file() {
    if [[ -z "$SELECTED_FILE" ]]; then
        show_error "Nothing selected"
        return
    fi
    
    if [[ -d "$SELECTED_FILE" ]]; then
        show_error "Cannot view directory"
        return
    fi
    
    if [[ ! -r "$SELECTED_FILE" ]]; then
        show_error "Cannot read file"
        return
    fi
    
    local size=$(stat -c %s "$SELECTED_FILE" 2>/dev/null || du -b "$SELECTED_FILE" | cut -f1)
    if [[ $size -gt 10000 ]]; then
        echo -ne "${YELLOW}File is large ($((size/1024)) KB). View anyway? (y/N): ${NC}"
        read -r confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            return
        fi
    fi
    
    echo
    echo -e "${CYAN}┌────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│            VIEW: $(basename "$SELECTED_FILE")${NC}"
    echo -e "${CYAN}└────────────────────────────────────────┘${NC}"
    echo
    if command -v bat >/dev/null 2>&1; then
        bat --paging=never "$SELECTED_FILE"
    elif command -v less >/dev/null 2>&1; then
        less "$SELECTED_FILE"
    else
        head -100 "$SELECTED_FILE"
    fi
    echo
    echo "Press Enter..."
    read -r
}

edit_file() {
    if [[ -z "$SELECTED_FILE" ]]; then
        show_error "Nothing selected"
        return
    fi
    
    if [[ -d "$SELECTED_FILE" ]]; then
        show_error "Cannot edit directory"
        return
    fi
    
    if [[ ! -w "$SELECTED_FILE" ]]; then
        show_error "Cannot write to file"
        return
    fi
    
    if command -v nano >/dev/null 2>&1; then
        nano "$SELECTED_FILE"
    elif command -v vim >/dev/null 2>&1; then
        vim "$SELECTED_FILE"
    elif command -v vi >/dev/null 2>&1; then
        vi "$SELECTED_FILE"
    else
        show_error "No editor found (install nano or vim)"
    fi
}

clear_search() {
    SEARCH_RESULTS=()
    SEARCH_INDEX=0
    show_msg "Search cleared"
}

main() {
    while true; do
        clear_screen
        show_header
        list_files
        show_menu
        
        read -r option
        case $option in
            1) open_item ;;
            2) create_file ;;
            3) create_dir ;;
            4) copy_file ;;
            5) cut_file ;;
            6) paste_file ;;
            7) delete_file ;;
            8) rename_file ;;
            9) show_properties ;;
            s|S) select_file ;;
            f|F) find_files ;;
            n|N) next_result ;;
            v|V) view_file ;;
            e|E) edit_file ;;
            c|C) clear_search ;;
            0) 
                echo "Goodbye!"
                exit 0
                ;;
            *)
                show_error "Invalid choice"
                ;;
        esac
    done
}

if [[ ! -d "/data/data/com.termux/files/usr" ]]; then
    echo "Running in non-Termux environment"
    sleep 1
fi

main
