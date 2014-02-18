#!/usr/bin/python
import sys
import re

#attacked_lines = [6, 8, 10, 19]
attacked_lines = [];

if (len(sys.argv) == 2):
    f = open(sys.argv[1])
    outf = open(sys.argv[1] + ".neato", 'w')
    print >>outf, "graph G {"
    #print >>outf, "\tnode [shape=point, height=.2, width=.2, fontsize=12];"
    line = ""

    while line.find("mpc.gen = [") == -1:
        line = f.readline()
        if line == "": break
    while line.find("];") == -1:
        line = f.readline()
        m = re.search(r'\d+', line)
        if m: print >>outf, ("\t" + m.group() + " [style=bold, color=green];")

    while line.find("mpc.branch = [") == -1:
        line = f.readline()
        if line == "": break
    i=1;
    while line.find("];") == -1:
        line = f.readline()
        m = re.search(r'(\d+)\s+(\d+)', line)
        if m:
            if i in attacked_lines: print >>outf, ("\t" + m.group(1) + " -- " + m.group(2) + " [color=red, penwidth=5];")
            else: print >>outf, ("\t" + m.group(1) + " -- " + m.group(2) + ";")
        i = i+1

    print >>outf, "}"

else:
    print "enter case file"
