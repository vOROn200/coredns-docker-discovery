# coredns-docker-discovery

**Docker Discovery Plugin for CoreDNS**

[![Docker Pulls](https://img.shields.io/docker/pulls/voron200/coredns-docker-discovery)](https://hub.docker.com/r/voron200/coredns-docker-discovery)

## Description

`coredns-docker-discovery` is a CoreDNS plugin that automatically manages DNS records for your Docker containers. It dynamically adds and removes DNS entries as containers are started and stopped, making service discovery within Docker environments seamless.

This plugin allows you to resolve Docker containers by:

* **Container Name:**  Using the container's `--name` as a subdomain.
* **Hostname:** Using the container's `--hostname` as a subdomain.
* **Docker Compose Project & Service Names:** For containers managed by Docker Compose.
* **Network Aliases:** Leveraging Docker network aliases for resolution within a specific network.
* **Labels:**  Resolving containers based on custom labels.

## Getting Started - Docker Usage

The easiest way to use `coredns-docker-discovery` is by running the pre-built Docker image. This eliminates the need to build CoreDNS and the plugin manually.

**1. Pull the Docker Image:**

```bash
docker pull voron200/coredns-docker-discovery:latest
```

**2. Create a Corefile:**

You'll need a Corefile to configure CoreDNS and the `dockerdiscovery` plugin.  Here's a basic example that listens on port 15353 and uses `dockerdiscovery` for the `loc` domain:

```
# Corefile
.:15353 {
    docker {
        domain docker.loc
    }
    log
}
```

**3. Run the CoreDNS Docker Container:**

Mount your Corefile and the Docker socket into the container.  Make sure to expose the desired port (e.g., 15353/UDP) for DNS queries.

```bash
docker run -d \
  --name coredns-docker-discovery \
  -v ${PWD}/Corefile:/etc/Corefile \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p 15353:15353/udp \
  voron200/coredns-docker-discovery -conf /etc/Corefile
```

**Explanation:**

* `-d`: Runs the container in detached mode (background).
* `--name coredns-docker-discovery`: Assigns a name to the container.
* `-v ${PWD}/Corefile:/etc/Corefile`: Mounts your local `Corefile` to `/etc/Corefile` inside the container.
* `-v /var/run/docker.sock:/var/run/docker.sock`:  Mounts the Docker socket, allowing CoreDNS to communicate with the Docker daemon. **This is crucial for Docker discovery to work.**
* `-p 15353:15353/udp`:  Maps port 15353 on the host to port 15353 (UDP) in the container.  This is the port CoreDNS will listen on for DNS queries.
* `voron200/coredns-docker-discovery -conf /etc/Corefile`: Specifies the Docker image to use and tells CoreDNS to use the Corefile at `/etc/Corefile`.

## Configuration - Corefile Syntax

Within your Corefile, use the `docker` plugin block to configure Docker discovery:

```
docker [DOCKER_ENDPOINT] {
    domain DOMAIN_NAME
    hostname_domain HOSTNAME_DOMAIN_NAME
    network_aliases DOCKER_NETWORK
    label LABEL
    compose_domain COMPOSE_DOMAIN_NAME
}
```

**Parameters:**

* **`DOCKER_ENDPOINT` (Optional):**
    - Path to the Docker socket. Defaults to `unix:///var/run/docker.sock`.
    - Can also be a TCP socket (e.g., `tcp://127.0.0.1:999`).
    - **When running CoreDNS inside Docker, you typically mount `/var/run/docker.sock` and can omit this parameter, using the default.**

* **`domain DOMAIN_NAME` (Required):**
    - The base domain for container names.
    - Example: `domain docker.loc` will resolve containers named `my-nginx` as `my-nginx.docker.loc`.

* **`hostname_domain HOSTNAME_DOMAIN_NAME` (Optional):**
    - The base domain for container hostnames.
    - Example: `hostname_domain docker-host.loc` will resolve containers with hostname `alpine` as `alpine.docker-host.loc`.

* **`compose_domain COMPOSE_DOMAIN_NAME` (Optional):**
    - The base domain for Docker Compose projects and services.
    - For a Compose project named "internal" and service "nginx", with `compose_domain compose.loc`, the FQDN will be `nginx.internal.compose.loc`.

* **`network_aliases DOCKER_NETWORK` (Optional):**
    - The name of a Docker network.
    - Resolves containers directly using Docker network aliases within the specified network.

* **`label LABEL` (Optional):**
    - Container label used for resolution.
    - Defaults to `coredns.dockerdiscovery.host`.
    - If defined, containers with this label will be resolved using the label's value as the hostname within the configured domain.

## Example Usage

**1. Corefile (e.g., `Corefile` ):**

```
.:15353 {
    docker {
        domain docker.loc
    }
    log
}
```

**2. Start CoreDNS (using the Docker image as described in "Getting Started - Docker Usage").**

**3. Start a Docker Container (with a name and hostname):**

```bash
docker run -d --name my-alpine --hostname alpine alpine sleep 1000
```

**4. Resolve the Container:**

Use `dig` or `nslookup` to query CoreDNS (running at `localhost:15353` in this example):

```bash
dig @localhost -p 15353 my-alpine.docker.loc
dig @localhost -p 15353 alpine.docker-host.loc
```

You should see an `ANSWER SECTION` in the `dig` output containing the container's IP address.

**5. Docker Compose Example:**

Assume you have a Docker Compose project named "my-project" and a service called "web". With the `compose_domain compose.loc` configured, you can resolve the service as `web.my-project.compose.loc` .

**6. Label-based Resolution:**

Start a container with a label:

```bash
docker run -d --label=coredns.dockerdiscovery.host=nginx.web.loc nginx
```

With the default label configuration, you can now resolve this container as `nginx.web.loc` .

## Building from Source (Optional)

If you wish to build the plugin from source (for development or customization):

**Prerequisites:**

* Go (version specified in CoreDNS documentation)
* Git
* Docker (for building the Docker image)

**Steps:**

1. **Clone CoreDNS:**
   

```bash
   git clone https://github.com/coredns/coredns --depth=1 ./go/src/github.com/coredns/coredns
   ```

2. **Navigate to CoreDNS directory:**
   

```bash
   cd go/src/github.com/coredns/coredns
   ```

3. **Add plugin to `plugin.cfg`:**
   

```bash
   echo "docker:github.com/vOROn200/coredns-docker-discovery" >> plugin.cfg
   ```

4. **Generate plugin code:**
   

```bash
   go generate
   ```

5. **Build CoreDNS:**
   

```bash
   CGO_ENABLED=1 make gen all
   ```

**Running Tests:**

```bash
go test -v github.com/vOROn200/coredns-docker-discovery
```

## Acknowledgements

This plugin is based on and inspired by [github.com/kevinjqiu/coredns-dockerdiscovery](https://github.com/kevinjqiu/coredns-dockerdiscovery.git). We thank the original authors for their valuable work.
