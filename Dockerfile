# ====== Stage 1: Builder ======
ARG GOLANG_VERS=1.23
ARG ALPINE_VERS=3.21

FROM golang:${GOLANG_VERS}-alpine${ALPINE_VERS} AS builder

# Set environment variables
ENV CGO_ENABLED=1 \
    PLUGIN_PRIO=50 \
    COREDNS_VERS=1.12.0

# Install build dependencies
RUN apk update && apk add --no-cache build-base git make binutils

# Clone the CoreDNS repository
RUN git clone --branch v${COREDNS_VERS} https://github.com/coredns/coredns.git --depth=1 /go/src/github.com/coredns/coredns

# Change to the CoreDNS directory
WORKDIR /go/src/github.com/coredns/coredns

# Add the plugin configuration file
ADD plugin.cfg plugin.cfg

# Generate code and build CoreDNS
RUN make gen all

# Install binutils to use 'strip' for reducing binary size and strip the binary
RUN apk add --no-cache binutils && \
    strip -v /usr/local/bin/coredns

# ====== Stage 2: Final Image ======
FROM alpine:${ALPINE_VERS}

# Install CA certificates for HTTPS support
RUN apk --no-cache add ca-certificates

# Copy the CoreDNS binary from the builder stage
COPY --from=builder /usr/local/bin/coredns /usr/local/bin/coredns

# Install libcap2-bin to set capabilities and allow binding to low ports
RUN apk add --no-cache libcap2-bin && \
    setcap cap_net_bind_service=+ep /usr/local/bin/coredns

# Switch to non-root user for security
USER nonroot:nonroot

# Set the working directory
WORKDIR /

# Expose DNS ports
EXPOSE 53 53/udp

# Set the entrypoint to the CoreDNS binary
ENTRYPOINT ["/usr/local/bin/coredns"]
