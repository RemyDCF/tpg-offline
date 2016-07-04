#!/usr/bin/env bash

set -e

xcodebuild -workspace "iOS/tpg offline.xcworkspace" -scheme "tpg offline Travis CI" -destination "platform=iOS Simulator,name=iPhone 6" test | xcpretty -c
xcodebuild -workspace "iOS/tpg offline.xcworkspace" -scheme "tpg offline Travis CI" -destination "platform=iOS Simulator,name=iPhone 4s" test | xcpretty -c