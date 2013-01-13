#!/bin/bash
#
# wmov - switch workspace in ubuntu 12.10
#

#
# SOME CONTEXT
#
# Ubuntu 12.10 represents the different workspace as chuncks of a very large
# virtual screen. Instead of using the standard "desktop" concept used by
# wmctrl, Unity switches desktop by changing the coordinates of the viewport.
#
# If you have 4 workspace arranged in a square (which is the default, you need
# some kind of settings tweaker to change that), this means that:
#
# - 0,0                 is the top left corner of the top left workspace (1)
# - <width>,0           is the top left corner of the top right workspace (2)
# - 0,<height>          is the top left corner of the bottom left workspace (3)
# - <width>,<height>    is the top left corner of the bottom right workspace (4)
#
# Where <width>x<height> is the resolution of your (physical) screen.
#
# USAGE
#
# wmov <num>
#
#   Switch to the designated desktop. The workspaces are numbered from left to
#   right, then from top to bottom, starting at 1.
#
# wmov left|right|up|down|here
#
#   Switch to the desktop in the indicated direction, if any.
#
# wmov mov <title> <num>
#
#   Moves a window whose title contains the substring <title> (case insensitive)
#   to the desktop designated by <num>.nn
#
# wmov mov <title> left|right|up|down|here
#
#   Moves a window whose title contains the substring <title> (case insensitive)
#   to the desktop in the indicated direction, if any.
#

# screen dimensions (resolution)
SWIDTH=`xrandr | grep Screen | awk '{ print $8 }'`
SHEIGHT=`xrandr | grep Screen | awk '{ print $10 }'  | cut -d ',' -f1`
# echo dw: $SWIDTH -- dh: $SHEIGHT

# total dimensions (of the virtual screen)
TWIDTH=`wmctrl -d | awk '{ print $4 }' | cut -d 'x' -f1`
THEIGHT=`wmctrl -d | awk '{ print $4 }' | cut -d 'x' -f2`
# echo tw: $TWIDTH -- th: $THEIGHT

# number of rows/columns of desktops
NX=$(( $TWIDTH / $SWIDTH ))
NY=$(( $THEIGHT / $SHEIGHT ))
# echo nx: $NX -- ny: $NY

# viewport coordinates
VPX=`wmctrl -d | awk '{ print $6 }' | cut -d ',' -f1`
VPY=`wmctrl -d | awk '{ print $6 }' | cut -d ',' -f2`
# echo vpx: $VPX -- vpy: $VPY

function get_coord_num()
{
    X=$(( ($1 - 1) % $NX ))
    Y=$(( ($1 - 1) / $NX ))

    echo $(( $X * $SWIDTH )),$(( $Y * $SHEIGHT ))
}

function get_coord_dir()
{
    case $1 in
        right)  echo $(( $VPX + $SWIDTH )),$VPY  ;;
        left)   echo $(( $VPX - $SWIDTH )),$VPY  ;;
        up)     echo $VPX,$(( $VPY - $SHEIGHT )) ;;
        down)   echo $VPX,$(( $VPY + $SHEIGHT )) ;;
        here)   echo $VPX,$VPY                   ;;
        *)      echo error                       ;;
    esac
}

function get_coord()
{
    case $1 in
        [1-9])  echo `get_coord_num $1` ;;
        *)      echo `get_coord_dir $1` ;;
    esac
}

function move_window()
{
    [[ "$2" == "error" ]] && {
        echo "Bad argument."
        exit 0
    }

    # target coordinates
    CX=$(( (`echo $2 | cut -d ',' -f1` - $VPX + $TWIDTH)  % $TWIDTH  ))
    CY=$(( (`echo $2 | cut -d ',' -f2` - $VPY + $THEIGHT) % $THEIGHT ))
    # echo cx: $CX -- cy: $CY

    wmctrl -r $1 -e 0,$CX,$CY,-1,-1
}

function switch_workspace()
{
    [[ "$1" == "error" ]] && {
        echo "Bad argument."
        exit 0
    }
    wmctrl -o $1
}

case $1 in
    mov)    move_window $2 `get_coord $3`   ;;
    *)      switch_workspace `get_coord $1` ;;
esac
