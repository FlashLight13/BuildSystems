LIBS="libs"
BUILD_TOOLS="/Users/antonpotapov/Library/Android/sdk/build-tools"



libs_res=""
libs_classes=""
for filename in $(ls $LIBS);
do
	echo "unpacking $filename"
	DESTINATION=$LIBS_OUT_DIR/$filename
	unzip -o -q $LIBS/$filename -d $DESTINATION
	libs_res="$libs_res -S $DESTINATION/res"
	libs_classes="$libs_classes:$DESTINATION/classes.jar"
done

$BUILD_TOOLS/aapt package -f -m \
	-J $GEN_DIR \
	-M $PROJ/AndroidManifest.xml \
	-S $PROJ/res \
	$libs_res \
	-I $ANDROID_JAR --auto-add-overlay

compiledKotlin=$KOTLIN_OUT_DIR/compiled.jar
kotlinc $PROJ/java $GEN_DIR -include-runtime \
	-cp "$ANDROID_JAR$libs_classes"\
	-d $compiledKotlin

dex=$DEX_OUT_DIR/classes.dex
$BUILD_TOOLS/dx --dex --output=$dex $compiledKotlin

unaligned_apk=$OUT_DIR/unaligned.apk
$BUILD_TOOLS/aapt package -f -m \
	-F $unaligned_apk \
	-M $PROJ/AndroidManifest.xml \
	-S $PROJ/res \
	$libs_res \
	-I $ANDROID_JAR --auto-add-overlay
cp $dex .
$BUILD_TOOLS/aapt add $unaligned_apk classes.dex
rm classes.dex

aligned_apk=$OUT_DIR/aligned.apk
$BUILD_TOOLS/zipalign -f 4 $unaligned_apk $aligned_apk

$BUILD_TOOLS/apksigner sign --ks $DEBUG_KEYSTORE $aligned_apk