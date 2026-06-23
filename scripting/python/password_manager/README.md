# Password Vault

## Description

A small command-line password manager written in Python. You enter a master password once, and the tool stores every other password you give it inside a single encrypted file.

You can later ask it for "email" or "bank" or "github" etc. and it hands the password back.

Everything's local. No web, cloud or browser extension. It also has ```list```, ```delete```, ```gen```(generate strong random password), and ```change-password```(rotate the master password).
