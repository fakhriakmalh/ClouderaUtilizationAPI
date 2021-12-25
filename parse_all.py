import json
import sys


def mean(numbers):
    return sum(numbers) / max(len(numbers), 1)

def count_avg_max(filejson) : 

  # Open the orders.json file
  with open("./jsonresults/{}".format(filejson)) as file:
    # Load its content and make a new dictionary
    data = json.load(file)
    # Delete the "client" key-value pair from each order
    data_parse = data["items"][0]["timeSeries"]
    data_dict = {}
    info_avg = []
    for item in range(len(data_parse)) :
      data_dict["data_{}".format(item)] = data_parse[item]["data"]
    for info in data_dict :
      for index in range(len(data_dict[info])) :
        info_avg.append(data_dict[info][index]["value"])  
    
    if filejson == 'memImpalaCoord.json' or filejson == 'memImpalaExec.json' : 
      val_avg = "{} GB".format(round(mean(info_avg)/1024/1024/1024,2))
      val_max = "{} GB".format(round(max(info_avg)/1024/1024/1024,2))
    
    elif filejson == 'memYARN.json' : 
      val_avg = round(mean(info_avg)/1024,2)
      val_max = round(max(info_avg)/1024,2)
      if val_avg < 1000 :
        val_avg = "{0:.1f} GB".format(val_avg)
      else :
        val_avg = val_avg/1000
        val_avg = "{0:.1f} TB".format(val_avg)

      if val_max < 1000 :
        val_max = "{0:.1f} GB".format(val_max)
      else :
        val_max = val_max/1000
        val_max = "{0:.1f} TB".format(val_max)
    
    elif filejson == 'cpuVcore.json' :
      val_avg = "{} Vcore".format(round(mean(info_avg),2))
      val_max = "{} Vcore".format(round(max(info_avg),2))

    else :
      val_avg = "{} %".format(round(mean(info_avg),2))
      val_max = "{} %".format(round(max(info_avg),2))
    return val_avg, val_max

item_resource_all = ['cpuUsage','cpuVcore','impalaCpuUsage','memImpalaCoord','memImpalaExec','memYARN']

avg_all, max_all = {} , {}
for item in range(len(item_resource_all)) : 
  avg_all["average_{}".format(item_resource_all[item])] = count_avg_max("{}.json".format(item_resource_all[item]))[0]
  max_all["max_{}".format(item_resource_all[item])] = count_avg_max("{}.json".format(item_resource_all[item]))[1]

list_avg_all = list(avg_all.values())
list_max_all = list(max_all.values())

item_ra = ['Worker node CPU ', 'YARN vCore', 'Impala CPU','Impala Coordinator','Impala Executor','YARN Memory']

item_string = {'cpuUsage':'Worker node CPU ', 
            'cpuVcore':'YARN vCore',
            'impalaCpuUsage':'Impala CPU',
            'memImpalaCoord':'Impala Coordinator',
            'memImpalaExec':'Impala Executor',
            'memYARN':'YARN Memory'}

print("\nCPU Usage")
print("- Worker node CPU Usage avg {} on Peak {}".format(avg_all['average_cpuUsage'],max_all['max_cpuUsage']))
print("- YARN vCore Usage avg {} on Peak {}".format(avg_all['average_cpuVcore'],max_all['max_cpuVcore']))
print("- Impala CPU Usage avg {} on Peak {}".format(avg_all['average_impalaCpuUsage'],max_all['max_impalaCpuUsage']))
print("\nMemory Usage")
print("- Impala Coordinator Usage avg {} on Peak {}".format(avg_all['average_memImpalaCoord'],max_all['max_memImpalaCoord']))
print("- Impala Executor Usage avg {} on Peak {}".format(avg_all['average_memImpalaExec'],max_all['max_memImpalaExec']))
print("- YARN Memory Usage avg {} on Peak {}".format(avg_all['average_memYARN'],max_all['max_memYARN']))
