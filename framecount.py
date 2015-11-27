#!/usr/bin/env python

import sys
import cv2

cap = cv2.VideoCapture(sys.argv[1])
frc = cap.get(7)
print ("%4.0f\tTotal frames" % (frc) )
