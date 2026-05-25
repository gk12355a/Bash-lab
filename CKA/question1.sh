# 1-Create a new Horizontal PodAutoscale (HPA) named apache-server in the autoscale namesapce. 
# 2-This HPA must target the existing Deployment called apacheserver in the autoscale namespace. 
# 3-Set the HPA to aim for 50% CPU Usage per pod. Configure it to have at least 1 pod and no more than 4 Pods. Also, Set the downscale stabilization window to 30 Seconds. 
cat << EOF >> hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
 name: apache-server
 namespace: autuscale
spec:
 scaleTargetRef:
  apiVersion: app/v1
  kind: Deployment
  name: apacheserver
 minReplicas: 1
 maxReplicas: 4
 metrics:
  - type: Resource
    resource: 
     name: cpu
     target: 
      type: Utilization
      averageUtilization: 50
 behavior:
  scaleDown: 
   stablizationWindowSeconds: 300
EOF
kubectl apply -f hpa.yaml 