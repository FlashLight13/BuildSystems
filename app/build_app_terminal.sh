function preparedir() {
	rm -r -f $1
	mkdir $1
}

PROJ="src/main"

LIBS="libs"
LIBS_OUT_DIR="$LIBS/out"

BUILD_TOOLS="$ANDROID_HOME/build-tools/28.0.3"
ANDROID_JAR="$ANDROID_HOME/platforms/android-28/android.jar"
DEBUG_KEYSTORE="$(echo ~)/.android/debug.keystore"

GEN_DIR="build/generated"
KOTLIN_OUT_DIR="$GEN_DIR/kotlin"
DEX_OUT_DIR="$GEN_DIR/dex"

OUT_DIR="out"

libs_res=""
libs_classes=""


preparedir $LIBS_OUT_DIR
aars=$(ls -p $LIBS | grep -v /)
for filename in $aars;
do
	DESTINATION=$LIBS_OUT_DIR/${filename%.*}
	echo "unpacking $filename into $DESTINATION"

	unzip -o -q $LIBS/$filename -d $DESTINATION
	libs_res="$libs_res -S $DESTINATION/res"
	libs_classes="$libs_classes:$DESTINATION/classes.jar"
done

preparedir $GEN_DIR
$BUILD_TOOLS/aapt package -f -m \
	-J $GEN_DIR \
	-M $PROJ/AndroidManifest.xml \
	-S $PROJ/res \
	$libs_res \
	-I $ANDROID_JAR --auto-add-overlay


preparedir $KOTLIN_OUT_DIR
compiledKotlin=$KOTLIN_OUT_DIR/compiled.jar
kotlinc $PROJ/java $GEN_DIR -include-runtime \
	-cp "$ANDROID_JAR$libs_classes"\
	-d $compiledKotlin


preparedir $DEX_OUT_DIR
dex=$DEX_OUT_DIR/classes.dex
$BUILD_TOOLS/dx --dex --output=$dex $compiledKotlin


preparedir $OUT_DIR
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