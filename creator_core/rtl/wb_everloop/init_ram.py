import os,random

f = open('image.ram', 'w')
# f.write("{")


for j in range(0,2048/4):
  RGB=[0,0,0,0]
     
  for i in range(0,4):
    line = RGB[i]
    f.write("%02x\n" % line)

#f.write("{")
f.close();
