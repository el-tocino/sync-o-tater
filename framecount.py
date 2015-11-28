#!/usr/bin/env python

import sys
import cv2

cap = cv2.VideoCapture(sys.argv[1])
frc = cap.get(7)
frt = cap.get(5)
print ("%4.0f\t%3.2f" % (frc,frt) )
