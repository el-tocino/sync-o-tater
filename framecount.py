#!python

import sys
import numpy as nm
import cv2

print ("First argument: %s" % str(sys.argv[1]))
cap = cv2.VideoCapture(sys.argv[1])
frc = cap.get(7)
print ("%s\tTotal frames" % (frc) )
