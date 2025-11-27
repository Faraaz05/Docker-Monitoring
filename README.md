# Container Monitoring with Grafana

Monitor Docker containers in real-time and visualize metrics using Grafana.

## Overview

This project demonstrates comprehensive Docker container monitoring using:
- **Prometheus** - Metrics collection
- **Loki** - Log aggregation
- **Promtail** - Log shipping
- **cAdvisor** - Container metrics
- **Grafana** - Visualization dashboard
- **Nginx** - Load balancer and reverse proxy

## Architecture

```
[app1, app2] → [nginx] → [promtail] → [loki]
     ↓                                    ↓
[cAdvisor] → [prometheus] ← ← ← ← [grafana]
```

## Quick Start

1. **Start the stack:**
   ```bash
   docker compose up -d
   ```

2. **Access services:**
   - Grafana: http://localhost:3000
   - Prometheus: http://localhost:9090
   - cAdvisor: http://localhost:8080
   - Apps: http://localhost:80

3. **Simulate traffic:**
   ```bash
   chmod +x simulate-traffic.sh
   ./simulate-traffic.sh
   ```

## What Gets Monitored

- Container CPU, memory, network, disk usage
- Application logs (aggregated from all containers)
- HTTP request metrics and response times
- Error rates and crash events
- Resource leaks and performance degradation

## Configuration

- `docker-compose.yml` - Service definitions
- `monitoring/prometheus.yml` - Metrics scraping config
- `monitoring/loki-config.yml` - Log aggregation config
- `monitoring/promtail-config.yml` - Log collection config
- `nginx/nginx.conf` - Load balancer rules

## Test Endpoints

The `simulate-traffic.sh` script hits various endpoints:
- **Safe routes** (78%): `/app1/ping`, `/app1/data`, `/app2/ping`
- **Heavy routes** (20%): `/app2/slow`, `/app2/disk`, `/app2/leak`, `/app2/crash`
- **Very heavy routes** (2%): `/app2/cpu`

## Stopping

```bash
docker compose down
```

To remove volumes:
```bash
docker compose down -v
```
