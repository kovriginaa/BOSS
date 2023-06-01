#!/bin/bash
gcc -std=c17 ~/lab6/2.2.c -o ~/lab6/2.2 && ~/lab6/2.2 & pstree | grep lab3
