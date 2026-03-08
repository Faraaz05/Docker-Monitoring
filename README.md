# Docker Container Monitoring Stack

A production-grade containerized monitoring solution implementing comprehensive observability for distributed microservices using the Grafana stack. This project demonstrates real-time metrics collection, log aggregation, and performance visualization for containerized applications.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Monitoring Capabilities](#monitoring-capabilities)
- [Testing](#testing)
- [Project Structure](#project-structure)
- [Performance Considerations](#performance-considerations)
- [Troubleshooting](#troubleshooting)
- [Contact](#contact)

## Overview

This project implements a full-stack monitoring solution for Docker containers, providing real-time insights into application performance, resource utilization, and system health. The stack combines industry-standard observability tools to deliver comprehensive monitoring capabilities suitable for development, staging, and production environments.

The implementation features two Node.js microservices (app1 and app2) behind an Nginx reverse proxy, with telemetry data collected through Prometheus and Loki, visualized in Grafana dashboards.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Monitoring Infrastructure                    │
│                                                                  │
│  ┌──────────┐       ┌──────────┐       ┌──────────┐            │
│  │   App1   │       │   App2   │       │  Nginx   │            │
│  │ (Node.js)│       │ (Node.js)│       │ (Proxy)  │            │
│  └────┬─────┘       └────┬─────┘       └────┬─────┘            │
│       │                   │                  │                  │
│       └───────────────────┴──────────────────┘                  │
│                           │                                     │
│       ┌───────────────────┴─────────────────────┐               │
│       ↓                                         ↓               │
│  ┌─────────┐                               ┌─────────┐          │
│  │ cAdvisor│──────── Container Metrics ────→Prometheus│          │
│  └─────────┘                               └────┬────┘          │
│                                                  │               │
│  ┌─────────┐                                    │               │
│  │Promtail │────── Application Logs ──────→ Loki│               │
│  └─────────┘                               └────┬────┘          │
│       ↑                                         │               │
│       │                                         │               │
│   Nginx Logs                                    ↓               │
│                                            ┌─────────┐           │
│                                            │ Grafana │           │
│                                            │(Dashbrd)│           │
│                                            └─────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Metrics Collection**: cAdvisor scrapes container-level metrics (CPU, memory, network, disk I/O)
2. **Metrics Storage**: Prometheus stores time-series metrics data with 5-second scrape intervals
3. **Log Collection**: Promtail tails application logs and Nginx access/error logs
4. **Log Aggregation**: Loki aggregates and indexes logs with 168-hour retention
5. **Visualization**: Grafana queries both Prometheus and Loki for unified observability

## Technology Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| **Docker Compose** | v2+ | Container orchestration |
| **Nginx** | latest | Reverse proxy and load balancer |
| **Node.js** | 18+ | Application runtime (Express.js) |
| **Prometheus** | latest | Time-series metrics database |
| **cAdvisor** | latest | Container metrics exporter |
| **Grafana** | latest | Metrics visualization and dashboards |
| **Loki** | 3.0.0 | Log aggregation system |
| **Promtail** | 3.0.0 | Log collection agent |

## Features

### Monitoring Capabilities

- **Real-time Metrics**: Sub-second granularity for container resource utilization
- **Centralized Logging**: Aggregated logs from all services with structured JSON formatting
- **Performance Analysis**: Request/response times, throughput, and latency tracking
- **Resource Tracking**: CPU, memory, network, and disk I/O monitoring
- **Error Detection**: Automatic detection and alerting for errors and crashes
- **Custom Dashboards**: Pre-configured Grafana dashboards for various metrics

### Application Features

- **Structured Logging**: JSON-formatted logs with request IDs for distributed tracing
- **Request Tracking**: UUID-based request correlation across services
- **Performance Simulation**: Endpoints simulating various failure scenarios:
  - CPU-intensive operations
  - Memory leaks
  - Slow responses (I/O delays)
  - Disk operations
  - Service crashes

### Infrastructure Features

- **High Availability**: Container restart policies for fault tolerance
- **Load Balancing**: Nginx upstream configuration for traffic distribution
- **Data Persistence**: Docker volumes for Grafana and Loki data
- **Network Isolation**: Custom Docker network for service communication

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+
- 4GB RAM minimum (8GB recommended)
- 10GB free disk space
- Linux, macOS, or Windows with WSL2

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd container-monitoring
```

### 2. Verify Directory Structure

Ensure the following directories exist:

```bash
mkdir -p log/nginx logs/nginx loki-data monitoring grafana-dashboards
```

### 3. Deploy the Stack

```bash
docker compose up -d
```

### 4. Verify Service Health

```bash
docker compose ps
```

All services should show status as "Up" or "healthy".

### 5. Access Web Interfaces

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3001 | admin / admin |
| Prometheus | http://localhost:9090 | N/A |
| cAdvisor | http://localhost:8080 | N/A |
| Applications | http://localhost:80 | N/A |

## Configuration

### Prometheus Configuration

File: `monitoring/prometheus.yml`

- **Scrape Interval**: 5 seconds
- **Targets**: Prometheus self-monitoring, cAdvisor, Docker daemon
- **Jobs**: Configurable scrape configurations for each service

### Loki Configuration

File: `monitoring/loki-config.yml`

- **Storage**: Filesystem-based (TSDB)
- **Retention**: 168 hours (7 days)
- **Ingestion Rate**: 4MB/s standard, 6MB/s burst
- **Schema**: v13 with 24-hour index periods

### Promtail Configuration

File: `monitoring/promtail-config.yml`

- **Log Sources**: Docker containers, Nginx access/error logs
- **Pipeline Stages**: JSON parsing, regex extraction, timestamp processing
- **Labels**: Dynamic labeling by container, stream, and log level

### Nginx Configuration

File: `nginx/nginx.conf`

- **Load Balancing**: Round-robin across backend services
- **Logging**: Structured JSON access logs with upstream information
- **Timeouts**: 
  - Read: 15s
  - Connect: 3s
  - Send: 10s

## Usage

### Starting the Stack

```bash
docker compose up -d
```

### Viewing Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f app1
docker compose logs -f nginx
```

### Accessing Application Endpoints

#### App1 Endpoints

```bash
curl http://localhost:80/app1/
curl http://localhost:80/app1/ping
curl http://localhost:80/app1/data
```

#### App2 Endpoints (Stress Testing)

```bash
# Normal endpoints
curl http://localhost:80/app2/
curl http://localhost:80/app2/ping

# Performance testing endpoints
curl http://localhost:80/app2/cpu        # CPU spike (5s computation)
curl http://localhost:80/app2/slow       # 3s delay
curl http://localhost:80/app2/leak       # Memory leak (2MB allocation)
curl http://localhost:80/app2/crash      # Controlled crash
```

### Configuring Grafana

1. Navigate to http://localhost:3001
2. Login with `admin` / `admin`
3. Add Prometheus data source:
   - URL: `http://prometheus:9090`
   - Access: Server (default)
4. Add Loki data source:
   - URL: `http://loki:3100`
   - Access: Server (default)
5. Import pre-configured dashboards from `grafana-dashboards/`

### Stopping the Stack

```bash
# Stop containers (preserve data)
docker compose stop

# Stop and remove containers
docker compose down

# Stop and remove all data
docker compose down -v
```

## Monitoring Capabilities

### Container Metrics

- **CPU Usage**: Per-container CPU utilization and throttling
- **Memory**: Working set, RSS, cache, swap usage
- **Network**: RX/TX bytes, packets, errors, drops
- **Disk I/O**: Read/write operations and throughput
- **File System**: Usage by mount point

### Application Metrics

- **Request Rate**: Requests per second per service
- **Response Time**: Latency percentiles (p50, p95, p99)
- **Error Rate**: HTTP 4xx/5xx error tracking
- **Throughput**: Bytes transferred per endpoint

### Log Analysis

- **Structured Logs**: JSON-formatted with consistent schema
- **Request Tracing**: Correlation via request ID
- **Error Detection**: Automatic severity-based filtering
- **Performance Tracking**: Request duration logging

## Testing

### Automated Traffic Simulation

The project includes traffic simulation scripts for load testing.

#### Local Traffic Script

```bash
chmod +x simulate-traffic.sh
./simulate-traffic.sh
```

**Configuration** (editable in script):
- `MAX_CONCURRENCY`: 10 concurrent requests
- `MIN_REQUESTS`: 10 minimum per batch
- `MAX_REQUESTS`: 40 maximum per batch
- `SLEEP_BETWEEN`: 5 seconds between batches

**Traffic Distribution**:
- 78% Safe routes (low resource usage)
- 20% Heavy routes (moderate stress)
- 2% Very heavy routes (extreme stress)

#### Remote Traffic Script

```bash
chmod +x simulate-remote-traffic.sh
./simulate-remote-traffic.sh
```

Use this for testing from external systems or simulating distributed load.

### Manual Testing

#### Baseline Performance

```bash
# Test normal operation
for i in {1..100}; do curl http://localhost:80/app1/ping; done
```

#### Stress Testing

```bash
# Trigger CPU spike
for i in {1..5}; do curl http://localhost:80/app2/cpu & done

# Induce memory leak
for i in {1..20}; do curl http://localhost:80/app2/leak; done

# Test slow response handling
curl http://localhost:80/app2/slow
```

## Project Structure

```
container-monitoring/
├── backend/
│   ├── app1/                      # Service 1 (stable)
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── server.js
│   └── app2/                      # Service 2 (stress testing)
│       ├── Dockerfile
│       ├── package.json
│       └── server.js
├── monitoring/
│   ├── prometheus.yml             # Prometheus configuration
│   ├── loki-config.yml            # Loki configuration
│   └── promtail-config.yml        # Promtail configuration
├── nginx/
│   └── nginx.conf                 # Reverse proxy configuration
├── grafana-dashboards/            # Pre-configured dashboards
│   ├── DOCKER LOGS-*.json
│   ├── Monitoring-*.json
│   ├── NGINX-*.json
│   └── Route Performance-*.json
├── log/nginx/                     # Nginx access/error logs
├── loki-data/                     # Loki persistent storage
├── docker-compose.yml             # Service orchestration
├── simulate-traffic.sh            # Local load testing script
├── simulate-remote-traffic.sh     # Remote load testing script
└── README.md
```

## Performance Considerations

### Resource Requirements

**Minimum**:
- 4GB RAM
- 2 CPU cores
- 10GB disk space

**Recommended**:
- 8GB RAM
- 4 CPU cores
- 20GB disk space (with log retention)

### Optimization Tips

1. **Log Retention**: Adjust `retention_period` in `loki-config.yml` based on disk availability
2. **Scrape Interval**: Increase `scrape_interval` in `prometheus.yml` for lower CPU usage
3. **Concurrent Requests**: Modify `MAX_CONCURRENCY` in traffic scripts to match system capacity
4. **Docker Resources**: Set memory/CPU limits in `docker-compose.yml` for production deployments

### Production Recommendations

- Enable Prometheus alerting rules
- Implement metric-based auto-scaling
- Configure persistent storage for Prometheus TSDB
- Set up Grafana SMTP for alert notifications
- Implement authentication for all web interfaces
- Use external storage for Loki (S3, GCS, etc.)
- Enable HTTPS with valid certificates

## Troubleshooting

### Services Not Starting

```bash
# Check service status
docker compose ps

# View detailed logs
docker compose logs <service-name>

# Restart specific service
docker compose restart <service-name>
```

### Prometheus Not Scraping Metrics

```bash
# Verify targets in Prometheus UI
# Navigate to: http://localhost:9090/targets

# Check network connectivity
docker compose exec prometheus wget -O- http://cadvisor:8080/metrics
```

### Grafana Cannot Connect to Data Sources

- Ensure Prometheus and Loki containers are running
- Verify data source URLs use container names (not localhost)
- Check Docker network connectivity: `docker network inspect container-monitoring_backend`

### Loki Not Receiving Logs

```bash
# Verify Promtail is running
docker compose logs promtail

# Check Loki ingestion
curl http://localhost:3100/ready
curl http://localhost:3100/metrics
```

### High Resource Usage

```bash
# Check container resource consumption
docker stats

# Reduce scrape frequency in prometheus.yml
# Reduce log ingestion rate in loki-config.yml
# Stop traffic simulation scripts
```

## Contact

**Project Maintainer**: [Faraaz-Bhojawala]

**Email**: [bhojawalafaraaz@gmail.com]

**LinkedIn**: [https://www.linkedin.com/in/faraaz-bhojawala/](https://www.linkedin.com/in/faraaz-bhojawala/)

**GitHub**: [https://github.com/Faraaz05](https://github.com/Faraaz05)

---

Built with passion for observability and monitoring excellence.
