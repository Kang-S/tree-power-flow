#!/usr/bin/python
import sys
import re

if (len(sys.argv) == 2):
    f = open(sys.argv[1])
    outf = open(sys.argv[1] + ".neato", 'w')
    print >>outf, "graph G {"
    #print >>outf, "\tnode [shape=point, height=.2, width=.2, fontsize=12];"
    line = ""
    root = '1'

    while line.find("mpc.bus = [") == -1:
        line = f.readline()
        if line == "": break
    while line.find("];") == -1:
        line = f.readline()
        m = re.search(r'(\d+)\s+(\d+)', line)
        if m and m.group(2) == '3':
            root = m.group(1)
            print >>outf, ("\t" + root + " [style=bold, color=red];")

    while line.find("mpc.gen = [") == -1:
        line = f.readline()
        if line == "": break
    while line.find("];") == -1:
        line = f.readline()
        m = re.search(r'\d+', line)
        if m and m.group() != root: print >>outf, ("\t" + m.group() + " [style=bold, color=green];")

    while line.find("mpc.branch = [") == -1:
        line = f.readline()
        if line == "": break
    while line.find("];") == -1:
        line = f.readline()
        m = re.search(r'(\d+)\s+(\d+)', line)
        if m:
            print >>outf, ("\t" + m.group(1) + " -- " + m.group(2) + ";")

    print >>outf, "}"

else:
    print "enter case file"
