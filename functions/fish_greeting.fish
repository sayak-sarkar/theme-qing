# Set global color styles, for example:
#
# function cyan_error
#   set_color -o red
# end
#
# function cyan_normal
#   set_color normal
#

function fish_greeting -d "what's up, fish?"
    if test "$LINES -ge 20 && $COLUMNS -ge 80" > /dev/null
        bash (dirname (status -f))/fedora_new.sh
    end
end
