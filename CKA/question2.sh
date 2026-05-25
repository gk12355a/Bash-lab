# Question 2:  
# 1- Create a new ingress resource as follows: 
# Name: echo 
# namespace: sound-repeater 
# Exposing Service schoserver-service on 
# http://example.org/echo using Service port 8080 
# The availability of service schoserver-service can be checked using the 
# following command which should return 200. 
cat << EOF >> ing.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
 name: echo
 namespace: sound-reapter
spec:
 rules:
  https: 
   http: example.org/echo
   paths:
    path: /
    pathType: Prefix
    backend:
     service:
      name: echoserver-service
      port:
       number: 8080
EOF
kubectl apply -f ing.yaml
