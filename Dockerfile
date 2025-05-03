# ---------- Stage 1: Builder ----------
    FROM ubuntu:22.04 AS builder

    ENV DEBIAN_FRONTEND=noninteractive \
        LANG=en_US.UTF-8 \
        LANGUAGE=en_US.UTF-8 \
        LC_ALL=en_US.UTF-8 \
        TERM=xterm \
        TZ=:/etc/localtime \
        GO_VERSION=1.23.8
    
    # Install build dependencies
    RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates build-essential \
        && rm -rf /var/lib/apt/lists/*
    
    # Install Go
    RUN curl -fsSL https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz -o go.tar.gz \
        && echo "45b87381172a58d62c977f27c4683c8681ef36580abecd14fd124d24ca306d3f  go.tar.gz" | sha256sum -c - \
        && tar -C /usr/local -xzf go.tar.gz \
        && rm go.tar.gz
    
    ENV PATH=/usr/local/go/bin:$PATH \
        GOPATH=/go \
        GOBIN=/go/bin \
        APP=/go/src/smugmug-backup
    
    # Copy source code
    ADD . $APP
    WORKDIR $APP
    
    # Build the binary
    RUN /usr/local/go/bin/go build -mod=vendor -v -o /go/bin/smugmug-backup ./cmd/smugmug-backup
    
    # ---------- Stage 2: Runtime ----------
    FROM debian:bookworm-slim
    
    # Install minimal runtime dependencies
    RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*
    
    # Copy binary from builder
    COPY --from=builder /go/bin/smugmug-backup /usr/local/bin/smugmug-backup
    
    # Set entrypoint
    ENTRYPOINT ["smugmug-backup"]
    