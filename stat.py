f = open('file3.txt', 'r')
data = f.read()
data=data.split('\n')
data.remove('')

## Making a good format of the txt file which is being read into a list.. 


dict1, results={},[]
for row in data:
  row=row[1:-1]
  row=row.split(':')
  row[1]=row[1].split(',')
  results.append([(row[0],int(row[1][0].strip()[:-1])) , (row[1][1].strip(), int(row[2].lstrip())) ])

## Collecting the TotalBuffer waiting time for each switch...

Totalbuffer1, Totalbuffer2, Totalbuffer3=0,0,0
for res in results:
  if res[1][1]==1: # for switch id 1
    Totalbuffer1+=res[0][1]
  elif res[1][1]==2:
    Totalbuffer2+=res[0][1]
  else:
    Totalbuffer3+=res[0][1]


## Saving the Statistics to a new text file..

temp_dict={'Total Buffer Waiting Time at Switch1': Totalbuffer1,
 'Total Buffer Waiting Time at Switch2': Totalbuffer2,
 'Total Buffer Waiting Time at Switch3': Totalbuffer3}
f=open('new_file.txt', 'a')
f.write(str(temp_dict.copy())+"\n")
f.close()

## Printing the collected statistics..

#print f'Total Buffer Waiting Time at Switch1 {Totalbuffer1}\n'
#, f'Total Buffer Waiting Time at Switch2 {Totalbuffer2}\n', f'Total Buffer Waiting Time at Switch3 {Totalbuffer3}\n'

print "Total Buffer Waiting Time at Switch1",Totalbuffer1,"Total Buffer Waiting Time at Switch2",Totalbuffer2,"Total Buffer Waiting Time at Switch3",Totalbuffer3