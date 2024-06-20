
# How to create secure routes in OpenShift

## Passthrough
Prepare your workload. In my case I will use nginx.
```
podman pull quay.io/redhattraining/hello-world-nginx

podman build --platform linux/amd64  -t nginx-ssl .

podman tag localhost/nginx-ssl quay.io/danielpenagos/nginx-ssl

podman push quay.io/danielpenagos/nginx-ssl
```

Create your project:
```
oc new-project secureroute

oc new-app --image=quay.io/danielpenagos/nginx-ssl
```
At this time, we need to create the certificate and key. We will use the openshift feature to generate ssl crypto-material.

```
oc annotate service nginx-ssl service.beta.openshift.io/serving-cert-secret-name=server-secret-ssl
```
Once you executed this annotation, you will see a new secret created.
''include image''

You need to inject this crypto material into your container.
```
cat <<EOF >> secretpatch.yaml
spec:
  template:
    spec:
      containers:
        - name: nginx-ssl
          volumeMounts:
            - name: server-secret-ssl
              mountPath: /etc/pki/nginx/
      volumes:
        - name: server-secret-ssl
          secret:
            defaultMode: 420 
            secretName: server-secret-ssl 
            items:
              - key: tls.crt
                path: server.crt 
              - key: tls.key
                path: private/server.key
EOF

oc patch deployment nginx-ssl --patch-file secretpatch.yaml
```
The deployment is now working and the application is deployed.

![route-passthrough](https://github.com/danielpenagos/custom-secure-route/blob/main/podworking.png?raw=true)

Create your route pointing the target port 8443 and test.
```
oc create route passthrough route-passthrough --service=nginx-ssl --port=8443
```
![route-passthrough](https://github.com/danielpenagos/custom-secure-route/blob/main/route-passthrough.png?raw=true)


## Reencrypt

In a reencrypt strategy, the route has its own TLS, and then it creates another communication against the secured service configured in the previous step.

Here, you need to use your own certificates. In my case I use I created for *.aws.bblatamtest.online 

```
openssl verify -CAfile ca-chain-bundle.cert.pem clientdaniel.cert.pem 

openssl x509 -in clientdaniel.cert.pem  -text -noout
```
![route-passthrough](https://github.com/danielpenagos/custom-secure-route/blob/main/custom-certificate.png?raw=true)

Finally you need to create the new route with the custom domain using proper certificates.
```
oc create route reencrypt route-reencrypt --service=nginx-ssl --port=8443 --hostname test.aws.bblatamtest.online --key clientdaniel.key.pem --cert clientdaniel.cert.pem
```

You can see your routes this way. To test the reencrypt route don't forget to configure the name resolution(DNS or my case /etc/hosts).

![etchosts](https://github.com/danielpenagos/custom-secure-route/blob/main/etchosts.png?raw=true)
![routes](https://github.com/danielpenagos/custom-secure-route/blob/main/routes.png?raw=true)

![route-reencrypt](https://github.com/danielpenagos/custom-secure-route/blob/main/route-reencrypt.png?raw=true)
