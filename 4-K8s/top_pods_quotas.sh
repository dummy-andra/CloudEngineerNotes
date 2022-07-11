#!/bin/sh
echo "Report for "$1" "
echo "---"
echo "---"
kubectl top pods -n "$1" | grep mongodb | awk '{sum+=$2} END {print "mongodb_CPU " sum "m"}'
kubectl top pods -n "$1" | grep mongodb | awk '{sum+=$3} END {print "mongodb_Mem " sum "Mi"}'
echo "---"
kubectl top pods -n "$1" | grep mysql | awk '{sum+=$2} END {print "mysql_CPU " sum "m"}'
kubectl top pods -n "$1" | grep mysql | awk '{sum+=$3} END {print "mysql_Mem " sum "Mi"}'
echo "---"
kubectl top pods -n "$1" | grep redis | awk '{sum+=$2} END {print "redis_CPU " sum "m"}'
kubectl top pods -n "$1" | grep redis | awk '{sum+=$3} END {print "redis_Mem " sum "Mi"}'
echo "---"
kubectl top pods -n "$1" | grep rabbitmq | awk '{sum+=$2} END {print "rabbitmq_CPU " sum "m"}'
kubectl top pods -n "$1" | grep rabbitmq | awk '{sum+=$3} END {print "rabbitmq_Mem " sum "Mi"}'
echo "---"
kubectl top pods -n "$1" | awk '{sum+=$2} END {print "TOTAL_CPU " sum "m"}'
kubectl top pods -n "$1" | awk '{sum+=$3} END {print "TOTAL_Mem " sum "Mi"}'
