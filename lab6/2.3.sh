#!/bin/bash
gcc -std=c17 ~/lab6/2.3.c -o ~/lab6/2.3 && ~/lab6/2.3 & pstree | grep lab3
