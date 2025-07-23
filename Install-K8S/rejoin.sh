#!/bin/bash
# Trên master
sudo swapoff -a
sudo mount -a
free -h
kubectl get nodes -owide

# Trên worker nodes
sudo swapoff -a
sudo mount -a
free -h
