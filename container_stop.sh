#!/bin/bash

echo "--> Stopping ARK server gracefully..."
tmux send-keys C-c
