#!/bin/bash
#
# Copyright 2015 - Dirk Groenen

declare -i VERBOSE=0

# Get current dir
CURDIR=$PWD
TMPDIR="/tmp/gwc-$(date +"%s")"

DESKTOP_TEMPLATE="gnome-wallpaper-changer.desktop"
APP_FILE="gnome-wallpaper-changer"

SYSPATH=/usr/bin

ACTION="install"

# Used for creating bold and normal output
bold=$(tput bold)
normal=$(tput sgr0)

# Default local path
DEFAULT_LOCALPATH="/home/$USER/Pictures"

function ask_user_source {
    print_info "At the moment the Gnome Wallpaper Changer can read from your filesystem or get a random featured image from Unsplash. Which one do you want to use?"
    read -p "Choose source [${bold}local${normal}/unsplash]: " SOURCE

    SOURCE="${SOURCE:-local}"
}

function ask_user_local_directory {
    print_info "Please enter the directory containing your wallpapers."
    read -p "Enter path [${bold}$DEFAULT_LOCALPATH${normal}]: " LOCALPATH

    LOCALPATH="${LOCALPATH:-$DEFAULT_LOCALPATH}"

    while [ ! -d "$LOCALPATH" ]; do
        print_info "Directory doesn't exist. Please re-enter your directory."
        ask_user_local_directory
    done
}

function create_desktop_entry_file {
    write_log "Copying desktop entry template to '$TMPDIR/$DESKTOP_TEMPLATE'"

    # Copy file to tmp directory
    cp "$CURDIR/$DESKTOP_TEMPLATE" "$TMPDIR/$DESKTOP_TEMPLATE"

    check_exit_status

    # Build execute based on provided info
    EXECUTE="$SYSPATH/$APP_FILE --source $SOURCE --path $LOCALPATH"

    # Change executable line
    sed -i "s#Exec=.*#Exec=${EXECUTE}#g" "$TMPDIR/$DESKTOP_TEMPLATE"

    check_exit_status
    write_log "Replaced executable line to '$EXECUTE'"
}

function create_tmp_installation_directory {
    write_log "Creating temporary directory $TMPDIR"

    mkdir $TMPDIR
    check_exit_status "Not able to create to temporary directory"
}

function remove_tmp_installation_directory {
    write_log "Removing temporary directory $TMPDIR"

    rm -r $TMPDIR
    check_exit_status "Not able to remove the temporary directory"
}

function move_application_scripts {
    write_log "Moving application file to $SYSPATH/$APP_FILE"

    # Copy main file and make it executable
    sudo cp "$CURDIR/$APP_FILE" "$SYSPATH/$APP_FILE"
    sudo chmod +x "$SYSPATH/$APP_FILE"

    check_exit_status "Not able to copy the application file."

    write_log "Moving desktop entry file to '/home/$USER/.config/autostart/$DESKTOP_TEMPLATE'"

    # Copy desktop template
    cp "$TMPDIR/$DESKTOP_TEMPLATE" "/home/$USER/.config/autostart/$DESKTOP_TEMPLATE"

    check_exit_status "Not able to copy the desktop file."

    write_log "Succesfully moved application and desktop files."
}

function remove_application_scripts {
    rm "/home/$USER/.config/autostart/$DESKTOP_TEMPLATE"

    check_exit_status "Couldn't remove desktop template"

    sudo rm "$SYSPATH/$APP_FILE"

    check_exit_status "Couldn't remove application file"
}

# ---------------------
# Helper functions
# ---------------------

# Simple info printer
function print_info {
    printf "\n$1\n"
}

# Simple error printer
function print_error_and_die {
    if [ $VERBOSE -eq 0 ]; then
        echo -e "\e[31mfatal: $1 \e[0m" >&2
    else
        write_log "fatal: $1"
    fi
    exit 9
}

# Checks if last command was successful
function check_exit_status {
    if [ $? -ne 0 ]; then
        print_error_and_die "$1, exiting..." "$2"
    fi
}

function write_log {
    if [ $VERBOSE -eq 1 ]; then
        echo "$(date): $1"
    else
        if [ -n "$LOG_CACHE" ]; then
            LOG_CACHE="$LOG_CACHE\n$(date): $1"
        else
            LOG_CACHE="$(date): $1"
        fi
    fi
}


# ---------------------
# Action functions
# ---------------------


# Start installation
function start_install {

    ask_user_source

    if [[ "$SOURCE" = "local" ]]; then
        ask_user_local_directory
    fi

    create_tmp_installation_directory

    create_desktop_entry_file
    move_application_scripts

    remove_tmp_installation_directory

    print_info "Succesfully installed Gnome Wallpaper Changer with your preferences. You can remove this directory."
}

# Start removing
function start_remove {

    remove_application_scripts

    print_info "Succesfully removed Gnome Wallpaper Changer."
}

function handle_action {
    case "$ACTION" in
        install)
            start_install
            ;;
        remove)
            start_remove
            ;;
    esac
}


# Test the given paramaters for matches
while test $# != 0
do
    case "$1" in
        -R|--remove)
            ACTION="remove"
            ;;
        -V|--verbose)
            VERBOSE=1
            ;;
    esac
    shift
done

handle_action