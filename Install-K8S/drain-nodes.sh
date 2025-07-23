#!/bin/bash
kubectl drain --ignore-daemonsets --force npd-worker1
kubectl delete node npd-worker1
kubectl cordon npd-worker1
kubectl drain --ignore-daemonsets --force npd-worker2
kubectl delete node npd-worker2
kubectl cordon npd-worker2
kubectl get nodes