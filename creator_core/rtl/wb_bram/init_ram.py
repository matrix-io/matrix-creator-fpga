import os,random

f = open('image.ram', 'w')
# f.write("{")
for i in range(0,1024):
  line = i+20*i+i*5+20
  f.write("%04x\n" % line)

#f.write("{")
f.close();
