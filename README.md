# ClouderaUtilizationAPI
what i've done in my current job to get cloudera utilization automatically with timerange as the input parameter

Example script to run the script

1. make sure that you are on this directory in your current terminal. 
2. run *./get_usage.sh (start range datetime) (finish range datetime)* ex : ./get_usage.sh 20211225T08:00:00 20211225T10:00:00
3. you will see the result after running the script, and it will be saved in the *result* directory

This script will need an enhancement in python side as the result of API will be aggregated after a few days. 
For example, if you need the result from a week ago, etc

Thanks
