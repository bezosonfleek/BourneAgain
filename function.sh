#!/bin/bash

up="beforce"
since="function"
echo $up
echo $since

showuptime(){
         local up=$(uptime -p | cut -c4- )
         local since=$(uptime -s)
         cat << EOF 
-------------------------------------------
Machine has been up for ${up}
Has been running since ${since}
-------------------------------------------
EOF
}
showuptime
echo $up
echo $since
