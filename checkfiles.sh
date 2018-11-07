# check all the g4dirt files have corresponding wcsim files
NUMFILES=`ls -l /pnfs/annie/persistent/users/moflaher/g4dirt/ | wc -l`
let NUMFILES=${NUMFILES}/2
let NUMFILES=${NUMFILES}-1	# account for the presence of '.' and '..' entries
echo "looping over ${NUMFILES} files in /pnfs/annie/persistent/users/moflaher/g4dirt/"
for i in `seq 1 ${NUMFILES}`
do
	THENUM=`less /pnfs/annie/scratch/users/moflaher/filenums.txt | sed -n ${i},${i}p`
	if [ $? -ne 0 ]; then echo "no line $i in filenums.txt?"; exit 1; fi
#	echo "ls /pnfs/annie/persistent/users/moflaher/wcsim/wcsim_0.${THENUM}.root"
	ls /pnfs/annie/persistent/users/moflaher/wcsim/wcsim_0.${THENUM}.root 1> /dev/null 2>&1
	if [ $? -ne 0 ]; then echo "file wcsim_0.${THENUM}.root not found"; fi
done

# check ... that there aren't any extraneous wcsim files?
#NUMFILES=`ls -l /pnfs/annie/persistent/users/moflaher/wcsim/ | wc -l`
#let NUMFILES=${NUMFILES}-1      # account for the presence of '.' and '..' entries
#echo "looping over ${NUMFILES} files in /pnfs/annie/persistent/users/moflaher/wcsim/"
#for i in `seq 1 ${NUMFILES}`
#do
#        THENUM=`less /pnfs/annie/scratch/users/moflaher/filenums.txt | sed -n ${i},${i}p`
#        if [ $? -ne 0 ]; then echo "no line $i in filenums.txt?"; exit 1; fi
#        ls /pnfs/annie/persistent/users/moflaher/wcsim/wcsim_0.${THENUM}.root 1> /dev/null 2>&1
#        if [ $? -ne 0 ]; then echo "file wcsim_0.${THENUM}.root not found"; fi
#done

