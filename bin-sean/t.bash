#!/bin/bash



  # Assume $remote_server, $my_user_id, $my_password, and $my_command were read in earlier
  # in the script.
  # Open a telnet session to a remote server, and wait for a username prompt.
  spawn telnet lb4b19-ts-01.ste.atl.lab.test 10025
  expect "Login:"
  # Send the username, and then wait for a password prompt.
  send "$my_user_id\r"
  expect "Password:"
  # Send the password, and then wait for a shell prompt.
  send "$my_password\r"
  expect "%"
  # Send the prebuilt command, and then wait for another shell prompt.
  send "$my_command\r"
  expect "%"
  # Capture the results of the command into a variable. This can be displayed, or written to disk.
  set results $expect_out(buffer)
  # Exit the telnet session, and wait for a special end-of-file character.
  send "exit\r"
  expect eof


telnet lb4b19-ts-01.ste.atl.lab.test 10025
echo "broadcom"
echo "broadcom"
echo "REM"
