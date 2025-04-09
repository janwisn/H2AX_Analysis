// Jan Wisniewski, EIB/NCI/NIH, Bethesda, MD

print("H2AX Analysis\nJan Wisniewski, Experimental Immunology Branch\nNational Cancer Institute, NIH, Bethesda, Maryland");
print("version 2025-03-12");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print("");
print("run: ", month+1, "/", dayOfMonth, "/", year, "   at ", hour, ":", minute);
print("");

showMessage("* Activate Bio-Formats(Windowless) import option\n     prior to runing this Macro for the first time\n \n* Images for analysis need to be in a separate folder,\n     without any other files of subfolders inside.\n \n* Store results in a different folder");

//  specify folders
res=getDirectory("Choose/create Results Folder");
input=getDirectory("Select Source Folder");
NAMES=getFileList(input); 

lei=endsWith(NAMES[0], ".lif");
if(lei==1) {// convert Leica images to tif
setBatchMode(true);
myDir5 = res + "Tiffs" + File.separator;
File.makeDirectory(myDir5);

dwn=getDirectory("downloads");
dest=dwn+"X.lif";			

for (k = 0; k < NAMES.length; k++) {showProgress(k/NAMES.length);
File.copy(input + NAMES[k], dwn + "X.lif");
run("Bio-Formats", "open=[dest] autoscale color_mode=Default open_all_series rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");

lclst=getList("image.titles");
for (u = 0; u < lclst.length; u++) {selectWindow(lclst[u]);
			saveAs("Tif", myDir5 + NAMES[k]+"_"+u+1); 
			close();		} 		}			
setBatchMode(false);
input=myDir5;
NAMES=getFileList(input); 		}

//set measured parameters
run("Set Measurements...", "area mean min bounding integrated median display redirect=None decimal=2");

//create custom table
title1 = "Analysis Table"; 
title2 = "["+title1+"]"; 
f=title2; 
run("New... ", "name="+title2+" type=Table"); 
print(f,"\\Headings:Image\tID#\tArea(um2)\t#_of_Spots\tTotal_Intensity"); 

//channel setup
open(input+NAMES[0]);
ttl=File.nameWithoutExtension;
getPixelSize(unit, pixelWidth, pixelHeight);
pxum2=1/(pixelWidth*pixelHeight);
print("pixel size=",pixelWidth, "x", pixelHeight, unit, "   ", pxum2, "pixels/um2");
getDimensions(width, height, channels, slices, frames);
wdt=width;
hgt=height;
nc=channels;

rename("x");
run("Split Channels");
run("Tile");

for (i = 0; i < nc; i++) {selectWindow("C"+i+1+"-x");
run("Enhance Contrast", "saturated=0.35");	}

Dialog.create("Channel selection");
items=newArray("C1-x", "C2-x", "C3-x", "C4-x");
itemz=newArray("Grays", "Blue", "Cyan", "Green", "Yellow" ,"Red", "Magenta");
Dialog.addRadioButtonGroup("Nuclei are visible in channel:", items, 1, 3, "C1-x");
Dialog.addString("Name the mask:", "nuclei");
Dialog.addChoice("Display as:", itemz, "Cyan");
Dialog.addMessage("     *     *     *     *     *     *     *     *     *     *");
Dialog.addRadioButtonGroup("Count spots in channel:", items, 1, 3, "C2-x");
Dialog.addString("Name the measured structure:", "spots");
Dialog.addChoice("Display as:", itemz, "Red");
Dialog.show();

MCh=Dialog.getRadioButton();
MNm=Dialog.getString();
MCo=Dialog.getChoice();
PCh=Dialog.getRadioButton();
PNm=Dialog.getString();
PCo=Dialog.getChoice();

print("setup image:", ttl);
print(MNm, MCh, MCo);
print(PNm, PCh, PCo);
run("Cascade");

//thresholds for nuclei detection
selectWindow(MCh);
run(MCo);
run("Duplicate...", "title=nuclei");

run("Median...", "radius=2");
setAutoThreshold("Default dark");
run("Threshold...");
setThreshold(0, 65535);
waitForUser("Adjust threshold to select nuclei.\nClick on the uppermost bar to rise minimum a few steps.");
getThreshold(lower, upper);
thrlow=lower;
thrup=upper;
setOption("BlackBackground", true);
run("Convert to Mask");
	run("Grays");
	run("Options...", "iterations=8 count=3 pad do=Open");
	run("Invert");
	run("Fill Holes");
	close("Threshold");
	run("Invert");
	run("Minimum...", "radius=2");
print("Nucleus segmentation thresholds:", thrlow, "-", thrup);
nprom=100;
print("nuclei detection limit (prominence):", nprom);

setTool("Wand");
waitForUser("Click on the smallest nucleus to include in analysis...");
smll=round(getValue("RawIntDen")/(pxum2*255));
waitForUser("and on the largest one.");
lrg=round(getValue("RawIntDen")/(pxum2*255));

Dialog.create(" ");
Dialog.addNumber("Confirm/adjust size range of nuclei to analyze:", smll);
Dialog.addToSameRow();
Dialog.addNumber(" - ", lrg);
Dialog.addToSameRow();
Dialog.addMessage("um2");
Dialog.show();
smln=Dialog.getNumber();
lrgn=Dialog.getNumber();

print("valid nucleus size range:", smln, "-", lrgn, "um2"); 
close("nuclei");

//threshold for dots
selectWindow(PCh);
run(PCo);
run("Duplicate...", "title=bck");
run("Gaussian Blur...", "sigma=5");
imageCalculator("Subtract create", PCh,"bck");
rename("spots");
run("Enhance Contrast", "saturated=0.35");
run("Median...", "radius=2");

//run("Point Tool...", "type=Dot color=Yellow size=Small label counter=0");
waitForUser("Activate Preview in the next Dialog Window and adjust Prominence until points select correctly!\n \nEnter that value in the next Dialog box.");
run("Find Maxima...", "prominence=100 strict exclude output=[Point Selection]");
run("Select None");
run("Find Maxima...");
Dialog.create("Spot detection threshold");
Dialog.addNumber("Enter Prominence value from the previous step:", 50);
Dialog.show();
prom=Dialog.getNumber();
print("spot detection limit (prominence):", prom);
close("spots");
close("bck"); 

nim=nImages;
for (i = 0; i < nim; i++) {close();			}

//proces images
for (i=0; i<NAMES.length; i++) {h=i+1;
	showProgress(h/(NAMES.length+1));	
setBatchMode(true); 
open(input+NAMES[i]);
ttx=File.nameWithoutExtension;

selectWindow("Analysis Table");
wait(500);
print(f, ttx);
rename("x");
run("Split Channels");

selectWindow(PCh);
rename(PNm);
run("Enhance Contrast", "saturated=0.35");
	run("Duplicate...", " ");
run("Gaussian Blur...", "sigma=5");
imageCalculator("Subtract create", PNm,PNm+"-1");
rename("spts");
run("Enhance Contrast", "saturated=0.35");
run("Median...", "radius=1");
run("Point Tool...", "type=Dot color=Yellow size=Small label counter=0");
run("Find Maxima...", "prominence=prom strict exclude output=[Single Points]");
run("Grays");
rename("points");
close(PNm+"-1");
close("spts");

selectWindow(MCh);
rename(MNm);
run("Enhance Contrast", "saturated=0.35");
run("Duplicate...", "title=nucs");
run("Median...", "radius=2");
run("Threshold...");
setThreshold(thrlow, thrup);
run("Convert to Mask");
run("Fill Holes");
run("Options...", "iterations=8 count=3 pad do=Open");
run("Grays");
run("Point Tool...", "type=Dot color=Red size=[Extra Large] label counter=0");
run("Find Maxima...", "prominence=100 strict exclude output=List");
selectWindow("Results");
rs=Table.size(); 
if(rs>0) {Table.sort("X"); 
Table.rename("X_Y_list");
rs=Table.size(); 
for (q = 0; q < rs; q++) {selectWindow("X_Y_list");
xs=Table.get("X", q);
ys=Table.get("Y", q);
doWand(xs, ys);
narum=round(getValue("RawIntDen")/(pxum2*255));
if(narum<smln) {run("Clear", "slice");		}
else {if(narum>lrgn) {run("Clear", "slice");		}
else {roiManager("Add");		}		}		}
run("Select None");
close("X_Y_list");

selectImage("spots");
bcg=getValue("Median");

for (jk = 0; jk < roiManager("count"); jk++) {selectImage("nucs");
roiManager("select", jk);
nar=getValue("RawIntDen")/255;
narum2=round(nar/(pxum2));
selectImage("points");
roiManager("select", jk);
pts=getValue("RawIntDen")/255;
selectImage("spots");
roiManager("select", jk);
intn=getValue("RawIntDen")-nar*bcg;
print(f," " + "\t" + jk+1 + "\t" + narum2 + "\t" + pts + "\t" + intn);		}
if(i==0) {waitForUser("Set label size to >20 in ROI Manger > More > Labels");		} 
close("nucs");

run("Colors...", "foreground=white background=black selection=white");
selectImage("points");
roiManager("show none");
run("Select None");
run("Yellow");
run("Gaussian Blur...", "sigma=2");
resetMinAndMax;
run("Enhance Contrast", "saturated=0.35");
run("RGB Color");
roiManager("Show All");
run("Flatten");
close("points");
selectImage("spots");
roiManager("show none");
run("Select None");
run(PCo);
resetMinAndMax;
run("Enhance Contrast", "saturated=0.35");
run("RGB Color");
roiManager("Show All");
run("Flatten");
close("spots");
selectImage("nuclei");
roiManager("show none");
run("Select None");
run(MCo);
resetMinAndMax;
run("Enhance Contrast", "saturated=0.35");
run("RGB Color");
roiManager("Show All with labels");
run("Flatten");
close("nuclei");
run("Images to Stack", "use");
run("Reverse");
run("Make Montage...", "columns=3 rows=1 scale=1");
saveAs("Jpeg", res + ttx + "_map");	
roiManager("deselect");
roiManager("delete");		 }
nim=nImages;
for (ii = 0; ii < nim; ii++) {close();		}		}

selectWindow("Analysis Table");
saveAs("Text", res+"Analysis_Results.csv");
close("Analysis Table");
selectWindow("Log");
saveAs("Text", res+"Log");
close("Log");
close("Threshold");
close("B&C");
close("ROI Manager");
exit("RUN COMPLETED!");

