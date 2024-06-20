oc new-project secureroute

podman pull quay.io/redhattraining/hello-world-nginx

podman build --platform linux/amd64  -t nginx-ssl .

podman tag localhost/nginx-ssl quay.io/danielpenagos/nginx-ssl

podman push quay.io/danielpenagos/nginx-ssl

oc new-app --image=quay.io/danielpenagos/nginx-ssl


oc annotate service nginx-ssl service.beta.openshift.io/serving-cert-secret-name=server-secret-ssl

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

oc create route passthrough route-passthrough --service=nginx-ssl --port=8443


openssl verify -CAfile ca-chain-bundle.cert.pem clientdaniel.cert.pem 

openssl x509 -in clientdaniel.cert.pem  -text -noout

oc create route reencrypt route-reencrypt --service=nginx-ssl --port=8443 --hostname test.aws.bblatamtest.online --key clientdaniel.key.pem --cert clientdaniel.cert.pem

