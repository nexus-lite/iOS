rm -rf build

xcodebuild -project STATRTracker.xcodeproj -target "STATRTracker" -sdk "iphonesimulator" -configuration "Release" clean build
xcodebuild -project STATRTracker.xcodeproj -target "STATRTracker" -sdk "iphoneos" -configuration "Release" clean build

lipo -create -output "build/libSTATRTracker.a" "build/Release-iphoneos/libSTATRTracker.a" "build/Release-iphonesimulator/libSTATRTracker.a"

cp build/Release-iphoneos/include/STATRTracker/*.h build

rm -rf build/Release-iphoneos
rm -rf build/Release-iphonesimulator
rm -rf build/STATRTracker.build
