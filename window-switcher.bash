#!/bin/bash
# Copyright © 2020  Magnus Maynard

if [ "$1" == "-h" ] || [ "$1" == "--help" ]
then
    echo "Switch focus to the nearest window in a given direction."
    echo "Usage: `basename $0` [direction]"
    echo "  -h  print help and exit"
    echo "  -l  switch window left"
    echo "  -r  switch window right"
    echo "  -u  switch window up"
    echo "  -d  switch window down"
    exit 0
fi

function get_window {
    local result=$(echo "$WINDOW_INFO" | awk '{print $1}' | cut -c 8-)
    echo "$result"
}

function get_pos_x {
    local result=$(echo "$WINDOW_INFO" | awk '{print $2}' | cut -c 3-)
    echo "$result"
}

function get_pos_y {
    local result=$(echo "$WINDOW_INFO" | awk '{print $3}' | cut -c 3-)
    echo "$result"
}

function get_width {
    local result=$(echo "$WINDOW_INFO" | awk '{print $4}' | cut -c 7-)
    echo "$result"
}

function get_height {
    local result=$(echo "$WINDOW_INFO" | awk '{print $5}' | cut -c 8-)
    echo "$result"
}

# Get active virtual desktop.
DESKTOP=$(xdotool get_desktop)
WINDOW_INFO=$(xdotool getactivewindow getwindowgeometry --shell | pr -6ats' ')

ACTIVE_WINDOW=$(get_window $WINDOW_INFO)
ACTIVE_POS_X=$(get_pos_x $WINDOW_INFO)
ACTIVE_POS_Y=$(get_pos_y $WINDOW_INFO)
ACTIVE_WIDTH=$(get_width $WINDOW_INFO)
ACTIVE_HEIGHT=$(get_height $WINDOW_INFO)
ACTIVE_CENTRE_X=$(($ACTIVE_POS_X+$ACTIVE_WIDTH/2))
ACTIVE_CENTRE_Y=$(($ACTIVE_POS_Y+$ACTIVE_HEIGHT/2))

CANDIDATE_WINDOW=$ACTIVE_WINDOW
CANDIDATE_DISTANCE=9999999

# Iterate through all open windows in desktop.
while read -r WINDOW_INFO
do
    WINDOW=$(get_window $WINDOW_INFO)

    # Do not use active window.
    if [ $ACTIVE_WINDOW != $WINDOW ]
    then
        POS_X=$(get_pos_x $WINDOW_INFO)
        POS_Y=$(get_pos_y $WINDOW_INFO)
        WIDTH=$(get_width $WINDOW_INFO)
        HEIGHT=$(get_height $WINDOW_INFO)
        CENTRE_Y=$(($POS_Y+$HEIGHT/2))
        CENTRE_X=$(($POS_X+$WIDTH/2))
        DIR_X=$(($CENTRE_X-$ACTIVE_CENTRE_X))
        DIR_Y=$(($CENTRE_Y-$ACTIVE_CENTRE_Y))
        DISTANCE=$(echo "sqrt($DIR_X*$DIR_X+$DIR_Y*$DIR_Y)" | bc)
        ABS_DIR_X=$(echo $DIR_X | bc | tr -d -)
        ABS_DIR_Y=$(echo $DIR_Y | bc | tr -d -)

        # Use closest window.
        if [ $DISTANCE -lt $CANDIDATE_DISTANCE ]
        then
            # Switching left and window direction is mostly left.
            if ([ "$1" = "-l" ] && [ $DIR_X -lt 0 ] && [ $ABS_DIR_X -gt $ABS_DIR_Y ]) ||
            # Switching right and window direction is mostly right.
            ([ "$1" = "-r" ] && [ $DIR_X -gt 0 ] && [ $ABS_DIR_X -gt $ABS_DIR_Y ]) ||
            # Switching up and window direction is mostly up.
            ([ "$1" = "-u" ] && [ $DIR_Y -lt 0 ] && [ $ABS_DIR_X -lt $ABS_DIR_Y ]) ||
            # Switching down and window direction is mostly down.
            ([ "$1" = "-d" ] && [ $DIR_Y -gt 0 ] && [ $ABS_DIR_X -lt $ABS_DIR_Y ])
            then
                # Select candidate window
                CANDIDATE_WINDOW=$WINDOW
                CANDIDATE_DISTANCE=$DISTANCE
            fi
        fi
    fi

done <<< $(xdotool search --onlyvisible --desktop $DESKTOP --class "" getwindowgeometry --shell %@ | pr -6ats' ')

# Switch to the candidate window
xdotool windowactivate $CANDIDATE_WINDOW
