import sys
import random
import optparse
import collections

def nameGenes(MIPfile,geneNameFile):
    input1 = open(MIPfile)
    input2 = open(geneNameFile)
    txttopython = []
    geneNames ={}
    newNames = []
    for line in input1:
        txttopython.append(line.rstrip('\n').split('\t'))
    for line in input2:
        temp = line.rstrip('\n').split('\t')
        if temp[1] not in geneNames.keys():
            geneNames.update({temp[1]:temp[0]})
    input1.close()
    input2.close()
    uniqueGenes=collections.defaultdict(list)
    for line in txttopython[1:]:
        regions = line[-1].split(';')
        for region in regions:
            name=region.split('_')
            if len(name)>6:
                name[3]=str(int(name[3])+1)
                test = name[0]+'_'+name[1]
                if len(regions)==1:
                    if name[-1].isdigit()==True:
                        name[-1]=str(int(name[-1]))
                        forOrRev=name[-2]
                    else:
                        name[-1]= str(int(name[-3]))+name[-1]
                        forOrRev=name[-4]
                    if test+'_'+forOrRev not in uniqueGenes.keys():
                        uniqueGenes.update({test+'_'+forOrRev:[name[-1]+':'+name[2]+'_'+name[3]]})
                    else:
                        uniqueGenes[test+'_'+forOrRev].append(name[-1]+':'+name[2]+'_'+name[3])
                elif len(regions)>1:
                    if region == regions[0]:
                        temphold=[]
                        temphold.append(name[2]+'_'+name[3])
                    elif region == regions[-1]:
                        if name[-1].isdigit()==True:
                            name[-1]=str(int(name[-1]))
                            forOrRev=name[-2]
                        else:
                            name[-1]= str(int(name[-3]))+name[-1]
                            forOrRev=name[-4]
                        temphold.append(name[2]+'_'+name[3])
                        if test+'_'+forOrRev not in uniqueGenes.keys():
                            uniqueGenes.update({test+'_'+forOrRev:[name[-1]+':'+temphold[0]]})
                            for temp in temphold[1:]:
                                uniqueGenes[test+'_'+forOrRev].append(name[-1]+':'+temp)
                        else:
                            for temp in temphold:
                                uniqueGenes[test+'_'+forOrRev].append(name[-1]+':'+temp)
                    else:
                        temphold.append(name[2]+'_'+name[3])
            elif len(name)>2:
                test = name[0]+'_'+name[1]
                if len(regions)==1:
                    if name[-1].isdigit()==True:
                        name[-1]=str(int(name[-1]))
                    else:
                        name[-1]= str(int(name[-3]))+name[-1]
                    if test not in uniqueGenes.keys():
                        uniqueGenes.update({test:[name[-1]+':'+'Int']})
                    else:
                        uniqueGenes[test].append(name[-1]+':Int')
                elif len(regions)>1:
                    if region == regions[-1]:
                        temphold=[]
                        temphold.append('Int')
                    elif region == regions[-1]:
                        if name[-1].isdigit()==True:
                            name[-1]=str(int(name[-1]))

                        else:
                            name[-1]= str(int(name[-3]))+name[-1]
                        temphold.append('Int')
                        if test not in uniqueGenes.keys():
                            uniqueGenes.update({test:[name[-1]+':'+temohold[0]]})
                            for temp in temphold[1:]:
                                uniqueGenes[test].append(name[-1]+':'+temp)
                        else:
                            for temp in temphold[1:]:
                                uniqueGenes[test].append(name[-1]+':'+temp)
                    else:
                        temphold.append('Int')
                    
                    
    for key in uniqueGenes.keys():
        name=key.split('_')
        practicalname=''
        test=name[0]+'_'+name[1]
        if test in geneNames.keys():
            practicalname=geneNames[test]
        if name[-1] == 'f':
            mipNumberlist = collections.defaultdict(list)
            for mip in uniqueGenes[key]:
                splitVal=mip.split(':')
                if splitVal[0] not in mipNumberlist.keys():
                    mipNumberlist.update({splitVal[0]:[splitVal[1]]})
                else:
                    mipNumberlist[splitVal[0]].append(splitVal[1])
            for key in mipNumberlist.keys():
                temp=practicalname
                for item in mipNumberlist[key]:
                    superSplitVal = item.split('_')
                    if superSplitVal[0]=='cds':
                        superSplitVal[0] = 'Ex'
                    elif superSplitVal[0] == 'utr3' or superSplitVal[0] =='utr5':
                        superSplitVal[0]+='_'
                    temp+='_'+superSplitVal[0]+superSplitVal[1]
                newNames.append(temp+'_MIP_'+key)
        elif name[-1] == 'r':
            highestVal = 0
            mipNumberlist = collections.defaultdict(list)
            for mip in uniqueGenes[key]:
                splitVal=mip.split(':')
                superSplitVal=splitVal[1].split('_')
                if int(superSplitVal[1])>highestVal:
                    highestVal=int(superSplitVal[1])
                if splitVal[0] not in mipNumberlist.keys():
                    mipNumberlist.update({splitVal[0]:[splitVal[1]]})
                else:
                    mipNumberlist[splitVal[0]].append(splitVal[1])
            highestVal+=1
            for key in mipNumberlist.keys():
                temp=practicalname
                for item in mipNumberlist[key]:
                    superSplitVal = item.split('_')
                    if superSplitVal[0]=='cds':
                        superSplitVal[0]='Ex'
                    elif superSplitVal[0] == 'utr3' or superSplitVal[0] =='utr5':
                        superSplitVal[0]+='_'
                    temp+='_'+superSplitVal[0]+str(highestVal-int(superSplitVal[1]))
                newNames.append(temp+'_MIP_'+key)
        else:
            mipNumberlist = collections.defaultdict(list)
            for mip in uniqueGenes[key]:
                splitVal=mip.split(':')
                if splitVal[0] not in mipNumberlist.keys():
                    mipNumberlist.update({splitVal[0]:[splitVal[1]]})
                else:
                    mipNumberlist[splitVal[0]].append(splitVal[1])
            for key in mipNumberlist.keys():
                temp=practicalname
                for item in mipNumberlist[key]:
                    temp+='_'+item
                newNames.append(temp+'_MIP_'+key)
    for x in range(len(txttopython)-1):
        name1=txttopython[x+1][-1].split('_')
        if name1[-1].isdigit()==True:
            name1[-1]=str(int(name1[-1]))
        else:
            name1[-1]= str(int(name1[-3]))+name1[-1]
        for item in newNames:
            name2=item.split('_')
            if name2[-1]==name1[-1]:
                txttopython[x+1][-1]=item
    removeExtension=MIPfile.replace('.txt','')
    newExtension=removeExtension+'.ConcName.txt'
    output = open(newExtension,'w')
    for line in txttopython:
        for member in line:
            if member != line[-1]:
                output.write(member+'\t')
            else:
                output.write(member+'\n')
    output.close()

def calcGC(MIPfile):
    input1 = open(MIPfile)
    txttopython = []
    for line in input1:
        txttopython.append(line.rstrip('\n').split('\t'))
    input1.close()
    counter = 0
    for line in txttopython:
        GCcounter = 0
        for let in line[13]:
            if let == 'G' or let == 'C':
                GCcounter+=1
        GCcontent = round(GCcounter*100.0/len(line[13]),2)
        txttopython[counter].append(str(GCcontent))
        counter+=1
    removeExtension=MIPfile.replace('.txt','')
    newExtension=removeExtension+'.GCcont.txt'
    output=open(newExtension,'w')
    txttopython[0][-1] = 'GC_Content (%)'
    for line in txttopython:
        for member in line:
            if member != line[-1]:
                output.write(member +'\t')
            else:
                output.write(member +'\n')
    output.close()

def generateUCSCtrack(infile,color):
    colors = {'purple':'106,90,205', 'green':'85,107,47', 'red':'205,92,92', 'gold':'218,165,32', 'blue':'65,105,225', 'orange':'255,69,0', 'pink':'255,105,180', 'brown':'139,69,19', 'snow':'205,203,20'}
    available_colors = colors.keys()
    if len(color)>0:
            pluscolor = color[0]
    else:
            pluscolor = random.choice(available_colors)
            available_colors.remove(pluscolor)
    if len(color)>1:
            minuscolor = color[1]
    else:
            minuscolor = random.choice(available_colors)

    plus_strand_lines = []
    minus_strand_lines = []

    fin = open(infile)
    fin.readline()
    for line in fin:
            values = line.strip().split('\t')
            if (len(values) > 9 and values[5] != 'NA' and values[4].isdigit()):
                    name = values[19] + "_%.3f" %(float(values[1]))
                    chromosome = values[2]
                    ext_probe_start = int(values[3])
                    ext_probe_stop = int(values[4])
                    lig_probe_start = int(values[7])
                    lig_probe_stop = int(values[8])
                    strand = values[17]
                    start_stop = [ext_probe_start, ext_probe_stop, lig_probe_start, lig_probe_stop]
                    start_stop.sort()
                    start_val = start_stop[0]-1
                    thick_start = start_stop[1]
                    thick_end = start_stop[2]-1
                    end_val = start_stop[3]
                    if strand==('+'):
                            plus_strand_lines.append('chr' + chromosome + '\t' + str(start_val) + '\t' + str(end_val) + '\t' + name + '\t' + '1\t' + strand + '\t' + str(thick_start) + '\t' + str(thick_end) + '\t' + colors[pluscolor] + '\n')
                    else:
                            minus_strand_lines.append('chr' + chromosome + '\t' + str(start_val) + '\t' + str(end_val) + '\t' + name + '\t' + '1\t' + strand + '\t' + str(thick_start) + '\t' + str(thick_end) + '\t' + colors[minuscolor] + '\n')
    fin.close()
    removeExtension = infile.replace('.txt','')
    fout = open(removeExtension + ".ucsc_track.bed", 'w')
    fout.write(
    'track name=' + removeExtension + '_plus' + ' itemRgb=on\n')
    for entry in plus_strand_lines:
            fout.write(entry)

    fout.write('\n')
    fout.write(
    'track name=' + removeExtension + '_minus' + ' itemRgb=on\n')
    for entry in minus_strand_lines:
            fout.write(entry)
    fout.close()

usage = "usage: %prog [options] arg"
parser = optparse.OptionParser(usage)
group=optparse.OptionGroup(parser,"Required for all Scripts\n","header.picked_mips.txt file required as input for all functions of this script")
group.add_option("-m","--MIPfile",dest="MIPfile",
                  help="Name of the MIP design file generated by Pipeline (Required for all Functions)",metavar="FILE")
parser.add_option_group(group)
group = optparse.OptionGroup(parser, "Create Concatenated Names\n","This list contains the necessary commands to create concatenated names")
group.add_option("-c","--concName",action="store_true",dest="concatName",default=False,
                  help="Creates New File with Concatenated Names (Command Input)")
group.add_option("-g","--geneFile",dest="genNameFile",
                  help="Name of the File with Gene Name and Refseq No. (Required only for concName)",metavar="FILE")
parser.add_option_group(group)
group = optparse.OptionGroup(parser,"Calculate GC Content of Target Region\n", "This list contains the necessary commands to calculate gc content")
group.add_option("-n","--GCcont",action="store_true",dest="GCcontent",default=False,
                  help="Creates New File with the GC Content of the Target Sequence (Command Input)")
parser.add_option_group(group)
group = optparse.OptionGroup(parser,"Generate UCSC Track\n","This list contains the necessary commands to generate a ucsc track")
group.add_option("-u","--UCSC",action="store_true",dest="UCSC",default=False,
                  help="Creates New File with the UCSC tracks for uploading into UCSC genome tracker (Command Input)")
group.add_option("-p","--color",default=[],type=str,dest='color',action='append',
                  help='Color Choices for UCSC track (Optional for UCSC Track Generation) Add up to 2 colors by using "-p color" for each one.  Available Colors: blue orange pink brown snow purple green red ')
parser.add_option_group(group)
(options, args) = parser.parse_args()

if (len(sys.argv)<5 and len(sys.argv)>7) or options.MIPfile == None:
    print '\nPlease input the necessary system arguments\n'
    parser.print_help()
else:
    if (options.GCcontent == True and options.concatName == True) or (options.UCSC==True and options.concatName==True):
        if options.genNameFile == None:
            print 'A file containing the gene name and respective refseq no. is necessary to concatenate names'
        if options.GCcontent==True:
            nameGenes(options.MIPfile,options.genNameFile)
            removeExtension=options.MIPfile.replace('.txt','')
            newExtension=removeExtension+'.ConcName.txt'
            calcGC(newExtension)
        if options.UCSC==True:
            nameGenes(options.MIPfile,options.genNameFile)
            removeExtension=options.MIPfile.replace('.txt','')
            newExtension=removeExtension+'.ConcName.txt'
            generateUCSCtrack(newExtension,options.color)
    elif options.concatName == True:
        if options.genNameFile == None:
            print 'A file containing the gene name and respective refseq no. is necessary to concatenate names'
        else:
            nameGenes(options.MIPfile,options.genNameFile)
    else:
        if options.GCcontent == True:
            calcGC(options.MIPfile)
        if options.UCSC == True:
            print options.color
            generateUCSCtrack(options.MIPfile,options.color)

