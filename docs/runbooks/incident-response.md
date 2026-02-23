# Incident Response Runbook

## Overview

This runbook provides step-by-step procedures for handling common incidents affecting the Task Manager API.

## Severity Levels

| Level | Description | Response Time | Examples |
|-------|-------------|---------------|----------|
| SEV-1 | Complete service outage | 15 minutes | All pods down, database unreachable |
| SEV-2 | Significant degradation | 30 minutes | High error rate, elevated latency |
| SEV-3 | Minor impact | 2 hours | Single pod crash, non-critical feature |
| SEV-4 | No user impact | Next business day | Monitoring alert, capacity warning |

## On-Call Checklist

1. Acknowledge the alert
2. Assess severity level
3. Start incident communication channel
4. Follow relevant runbook section
5. Document actions taken
6. Write post-mortem for SEV-1/SEV-2

---

## Incident: High Error Rate (5xx > 5%)

### Symptoms
- Alert: `HighErrorRate` firing
- Grafana shows spike in 5xx responses
- User reports of failures

### Diagnosis Steps

```bash
# 1. Check pod status
kubectl get pods -n task-manager -o wide

# 2. Check recent pod events
kubectl describe pods -n task-manager

# 3. View application logs (last 100 lines)
kubectl logs -n task-manager -l app=task-manager --tail=100

# 4. Check for OOMKilled or CrashLoopBackOff
kubectl get pods -n task-manager -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].state}{"\n"}{end}'

# 5. Check database connectivity
kubectl exec -n task-manager -it deploy/task-manager -- python -c "from app.db.session import engine; engine.connect()"
```

### Common Causes and Fixes

#### Database Connection Issues
```bash
# Check database pod/service
kubectl get svc -n task-manager

# Test database connection
kubectl run -n task-manager debug --rm -it --image=postgres:15 -- psql postgresql://postgres:***@db:5432/taskmanager

# If using managed DB, check cloud console for:
# - Connection limits
# - CPU/Memory usage
# - Storage space
```

#### Application OOM
```bash
# Check resource usage
kubectl top pods -n task-manager

# Increase memory limit if needed
kubectl patch deployment task-manager -n task-manager -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-manager","resources":{"limits":{"memory":"1Gi"}}}]}}}}'
```

#### Bad Deployment
```bash
# Check rollout history
kubectl rollout history deployment/task-manager -n task-manager

# Rollback to previous version
kubectl rollout undo deployment/task-manager -n task-manager

# Verify rollback
kubectl rollout status deployment/task-manager -n task-manager
```

---

## Incident: High Latency (p95 > 500ms)

### Symptoms
- Alert: `HighLatency` firing
- Slow API responses
- Grafana shows latency spike

### Diagnosis Steps

```bash
# 1. Check pod resource usage
kubectl top pods -n task-manager

# 2. Check HPA status
kubectl get hpa -n task-manager

# 3. Check if pods are being throttled
kubectl describe pods -n task-manager | grep -A5 "Limits"

# 4. Check database query performance
kubectl logs -n task-manager -l app=task-manager | grep "slow_query"
```

### Common Causes and Fixes

#### CPU Throttling
```bash
# Increase CPU limit
kubectl patch deployment task-manager -n task-manager -p '{"spec":{"template":{"spec":{"containers":[{"name":"task-manager","resources":{"limits":{"cpu":"1000m"}}}]}}}}'
```

#### Not Enough Replicas
```bash
# Scale up manually
kubectl scale deployment/task-manager --replicas=5 -n task-manager

# Or adjust HPA
kubectl patch hpa task-manager -n task-manager -p '{"spec":{"minReplicas":3}}'
```

#### Database Slow Queries
```bash
# Check active queries (if using port-forward to DB)
psql -c "SELECT pid, now() - pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE state = 'active';"

# Consider adding missing indexes
# Check EXPLAIN ANALYZE for slow queries
```

---

## Incident: Pod CrashLoopBackOff

### Symptoms
- Pods repeatedly restarting
- `kubectl get pods` shows `CrashLoopBackOff`

### Diagnosis Steps

```bash
# 1. Get crash details
kubectl describe pod -n task-manager <pod-name>

# 2. Check logs from crashed container
kubectl logs -n task-manager <pod-name> --previous

# 3. Check events
kubectl get events -n task-manager --sort-by='.lastTimestamp'
```

### Common Causes and Fixes

#### Missing Environment Variables
```bash
# Check ConfigMap/Secret mounting
kubectl get configmap -n task-manager -o yaml
kubectl get secret -n task-manager -o yaml

# Verify env vars in deployment
kubectl get deployment task-manager -n task-manager -o jsonpath='{.spec.template.spec.containers[0].env}'
```

#### Health Check Failure
```bash
# Test health endpoint manually
kubectl port-forward -n task-manager svc/task-manager 8000:8000
curl http://localhost:8000/health

# Check probe configuration
kubectl get deployment task-manager -n task-manager -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}'
```

---

## Incident: Database Connection Pool Exhausted

### Symptoms
- Error logs: "too many connections" or "connection pool exhausted"
- New requests failing intermittently

### Diagnosis Steps

```bash
# Check current connections (from psql)
SELECT count(*) FROM pg_stat_activity;
SELECT max_conn FROM pg_settings WHERE name = 'max_connections';

# Check application pool settings
kubectl exec -n task-manager -it deploy/task-manager -- env | grep -i pool
```

### Fixes

```bash
# 1. Reduce pool size per pod if too many replicas
# Update SQLALCHEMY_POOL_SIZE in ConfigMap

# 2. Increase database max_connections (managed DB console)

# 3. Check for connection leaks in application
# Look for queries not being committed/closed
```

---

## Incident: Certificate Expiration

### Symptoms
- TLS errors in browser
- Alert: `CertificateExpiringSoon`

### Fixes

```bash
# Check certificate expiry
kubectl get certificate -n task-manager
kubectl describe certificate -n task-manager

# If using cert-manager, trigger renewal
kubectl delete certificate <cert-name> -n task-manager
# cert-manager will automatically recreate

# Manual certificate update
kubectl create secret tls task-manager-tls \
  --cert=new-cert.pem \
  --key=new-key.pem \
  -n task-manager \
  --dry-run=client -o yaml | kubectl apply -f -
```

---

## Incident: Disk Space Full (Database)

### Symptoms
- Database write failures
- Alert: `DatabaseDiskSpaceLow`

### Fixes

```bash
# 1. Check what's using space
SELECT pg_size_pretty(pg_database_size('taskmanager'));

# 2. Find large tables
SELECT tablename, pg_size_pretty(pg_total_relation_size(tablename::regclass)) 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY pg_total_relation_size(tablename::regclass) DESC;

# 3. Clean up if applicable
VACUUM FULL;
REINDEX DATABASE taskmanager;

# 4. For managed DB: increase storage allocation via cloud console
```

---

## Recovery Procedures

### Database Restore from Backup

```bash
# 1. List available backups (AWS RDS example)
aws rds describe-db-snapshots --db-instance-identifier task-manager-db

# 2. Restore to new instance
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier task-manager-db-restored \
  --db-snapshot-identifier <snapshot-id>

# 3. Update application to point to new database
kubectl edit configmap task-manager-config -n task-manager
# Update DATABASE_URL

# 4. Restart pods
kubectl rollout restart deployment/task-manager -n task-manager
```

### Full Cluster Recovery

```bash
# 1. Ensure infrastructure exists (Terraform)
cd infra/terraform/envs/prod
terraform plan
terraform apply

# 2. Deploy base manifests
kubectl apply -k deploy/k8s/overlays/prod/

# 3. Restore database from latest backup

# 4. Verify deployment
kubectl get pods -n task-manager
curl https://api.example.com/health
```

---

## Post-Incident

### Required for SEV-1/SEV-2

1. **Incident Summary**: What happened, impact, duration
2. **Timeline**: Chronological events with timestamps
3. **Root Cause**: Deep analysis of underlying cause
4. **Action Items**: Preventive measures with owners and deadlines
5. **Lessons Learned**: What worked, what didn't

### Post-Mortem Template

```markdown
# Incident Post-Mortem: [Title]

**Date**: YYYY-MM-DD
**Duration**: X hours Y minutes
**Severity**: SEV-X
**Author**: [Name]

## Summary
Brief description of what happened and user impact.

## Timeline (UTC)
- HH:MM - Alert fired
- HH:MM - On-call acknowledged
- HH:MM - Root cause identified
- HH:MM - Fix deployed
- HH:MM - Monitoring confirmed resolution

## Root Cause
Detailed technical explanation.

## Resolution
What was done to fix the immediate issue.

## Action Items
| Action | Owner | Deadline | Status |
|--------|-------|----------|--------|
| Add monitoring for X | @engineer | 2024-01-20 | TODO |
| Increase resource limits | @platform | 2024-01-18 | DONE |

## Lessons Learned
- What went well
- What could be improved
```

---

## Contacts

| Role | Contact | Escalation |
|------|---------|------------|
| On-Call Engineer | PagerDuty | First response |
| Engineering Lead | \<CHANGE_ME\> | SEV-1/SEV-2 |
| Platform Team | #platform-oncall | Infrastructure issues |
| Database Admin | \<CHANGE_ME\> | Database emergencies |
