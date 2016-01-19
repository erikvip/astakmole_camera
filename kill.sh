#!/bin/bash
for i in $(pgrep motiondetected && pgrep wget); do sudo kill -9 $i; done
