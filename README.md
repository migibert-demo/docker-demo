# Using consul as a DNS server
Start consul server
```
sudo docker run -p 8400:8400 -p 8500:8500 -p 8600:53/udp -h consul-server --name consul-server progrium/consul -server -bootstrap -ui-dir /ui
```

## Without DNS servers
Run a busybox container
```
sudo docker run -it busybox
```

Check configured DNS servers
```
cat /etc/resolv.conf
```

For sure, this address will not be resolved!
```
ping node1.node.consul
```

## With an external DNS server
Find the consul server address with
```
export CONSUL_SERVER=$(sudo docker inspect -f '{{.NetworkSettings.IPAddress}}' consul-server)
```

Check it for fun
```
echo $CONSUL_SERVER
```

Run a container specifying a custom dns
```
sudo docker run -it --dns $CONSUL_SERVER busybox
```

Check DNS resolution works well
```
ping node1.node.consul
```

And see that docker replaced 8.8.8.8 and 8.8.4.4 nameservers by your custom dns server
```
cat /etc/resolv.conf
```

Note that docker allows multiple --dns flags to specify multiple nameserver

# Registering containers in consul at startup
```
sudo docker run -d --name client -h client progrium/consul -join $CONSUL_SERVER
```


# Logging policy
Logs drivers are part of docker engine and allow you to apply a centralized log policy on your container at runtime.

## Server
Run a fluentd server
```
sudo docker run -d --name fluentd-server -p 24224:24224 -v /tmp/fluentd:/fluentd/etc -e FLUENTD_CONF=test.conf fluent/fluentd:latest
```

Where test.conf contains:
```
<source>
  @type forward
</source>

<match docker.**>
  @type stdout
</match>
```

## Clients
Launch containers with fluentd log-driver. When address is not specified, this driver will automatically connect to localhost:24224.
You can customize server address with --log-opt fluentd-address=<server_address>

```
sudo docker run --log-driver=fluentd -d --name my-apache-app-1 -v "$PWD":/usr/local/apache2/htdocs/ -p 90:80 httpd:2
sudo docker run --log-driver=fluentd -d --name my-apache-app-2 -v "$PWD":/usr/local/apache2/htdocs/ -p 91:80 httpd:2
sudo docker run --log-driver=fluentd -d --name my-apache-app-3 -v "$PWD":/usr/local/apache2/htdocs/ -p 92:80 httpd:2
```

Docker logs from each container is centralized in fluentd server container.

## I want more logs!

The log driver policy is to forward the output of docker logs command to the log server.

If you run more than one application in one container, or interested by other logs that are not part of docker logs output, you will need more than the log driver, you will need a local agent with your custom configuration.


# migibert/base_image
Base image that contains:

- A local consul agent connected to the specified consul server. This allows containerized applications to register at startup and let peers know they are running and available to serve incoming requests. Consul HTTP client APIs exists for various languages (Java, Python, Ruby, PHP, Go, ...). Moreover, each container running along this image is known from peers and then can be monitored.

- A local fluentd agent with customisable configuration (volume). This agent will forward its tracked logs to $FLUENTD_SERVER if it is defined (with -e FLUENTD_SERVER = <fluentd server address>) or fluentd.service.consul if your fluentd server is registered in consul. As this container should be launched with --dns flag set to consul server address, it will resolve this kind of addresses.

- A local collectd agent with customisable configuration (volume). I recommand to let this agent act as a statd server in order to allow applications to publish business metrics which will be centralized.

## Sample
Here is a command set to run a sample container architecture with centralized logging and service discovery.

- Run the service discovery server : 
```
sudo docker run -p 8400:8400 -p 8500:8500 -p 8600:53/udp -h consul-server --name consul-server progrium/consul -server -bootstrap -ui-dir /ui
```

- Run the log database (Mongodb)
```
sudo docker run --name mongo -d -p 27017:27017 mongo:3.2
```

- Run the log server with the previously mentioned configuration :
```
sudo docker run -d --name fluentd-server -p 24224:24224 -v /tmp/fluentd:/fluentd/etc -e FLUENTD_CONF=test.conf fluent/fluentd:latest
```

With a configuration to output logs into mongodb:
```
<match mongo.**>
  type mongo
  host <mongo_container_ip>
  port 27017
  database fluentd
  collection logs

  # key name of timestamp
  time_key time

  # flush
  flush_interval 10s
</match>
```

And do not forget to replace mongo_container_ip using :
```
sudo docker inspect -f '{{.NetworkSettings.IPAddress}}' mongo
```

- Run the metrics database (InfluxDB)
```
sudo docker run -d -p 8083:8083 -p 8086:8086 tutum/influxdb
```

- Run dashboard (Grafana) 

- Run containerized applications based on migibert/base_image

