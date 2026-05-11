#!/bin/bash

#case ${1,,} in
read -p "Username: " user

case ${user,,} in
      bezos | admin)
         echo "BOSS status!"
         ;;
      help)
         echo "Enter you username..."
         ;;
      *)
         echo "Unauthorized access."
esac
