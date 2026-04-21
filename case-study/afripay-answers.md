# AfriPay Case Study — DevOps Strategy

---

## Q1 — Automated Deployments & Rollbacks

**Current state:** Manual SSH deployments across 6 markets = no audit trail, human error risk, no rollback path.

**Strategy:**
- GitHub Actions pipeline per market using environment-specific `.env` files (e.g. `env.kenya`, `env.ghana`)
- Each deployment tags the Docker image with the commit SHA: `btransact-api:abc1234`
- The previous tag is written to `.last_deployed_tag` on the server after every successful deploy
- Rollback in under 5 minutes: `./scripts/rollback.sh <previous-tag>` pulls and restarts the old container — no rebuild needed
- Blue/green option: run old container on port 3001, new on 3000, switch Nginx upstream only after health check passes

**Per-market config structure:**
```
config/
  kenya.env
  ghana.env
  nigeria.env
  tanzania.env
  uganda.env
  zambia.env
```

Each file holds market-specific `API_BASE_URL`, `DB_HOST`, `USSD_GATEWAY_URL` — never committed, stored in GitHub Secrets per environment.

---

## Q2 — Secrets Management

**Current risks:**
- Plaintext credentials on disk = any server breach exposes all markets simultaneously
- No audit trail — impossible to prove who accessed what (compliance failure under Bank of Kenya, CBN, etc.)
- Insider threat: any developer with SSH access can read all secrets
- Rotation is manual and error-prone — credentials rarely change

**Migration plan (HashiCorp Vault — works offline, cost-effective):**

1. Deploy Vault on a dedicated internal server or as a container
2. Migrate all secrets: `vault kv put secret/btransact/kenya db_password=xxx api_key=yyy`
3. Each app fetches secrets at runtime via Vault Agent or direct API call:
   ```bash
   export DB_PASSWORD=$(vault kv get -field=db_password secret/btransact/kenya)
   ```
4. Apps use short-lived tokens — secrets never touch disk
5. Enable audit logging: every secret read is logged with timestamp + identity

**AWS Secrets Manager alternative** (if already on AWS):
- Store per-market secrets: `btransact/kenya/db`, `btransact/ghana/db`
- ECS tasks fetch via IAM role at startup — zero plaintext anywhere
- Automatic rotation built in for RDS credentials

---

## Q3 — Monitoring & Alerting Strategy

**Stack:** Prometheus + Grafana + Alertmanager (open source, runs on existing infra)

**3 critical USSD-specific metrics:**

| Metric | Why it matters |
|--------|---------------|
| `ussd_session_success_rate` | USSD sessions time out after 180s — a drop below 95% means customers are losing money mid-transaction |
| `transaction_duration_seconds` (p95) | Regulators in Kenya/Nigeria require payment confirmation within 10s — p95 > 3s is a warning sign |
| `payments_failed_rate` | Failed payments = direct revenue loss + customer complaints on social media within minutes |

**Alert routing:**
- Critical alerts (success rate < 95%, failed payments > 5%) → PagerDuty/SMS to on-call engineer immediately
- Warning alerts (latency creeping up) → Slack `#ops-alerts` channel
- Grafana dashboard per market — one screen shows all 6 markets' health at a glance

**Proactive alerting:** Set warning thresholds at 80% of the critical threshold so the team gets 10–15 minutes to act before customers notice.

---

## Q4 — Peak Load on Salary Dates (25th–31st)

**Problem:** Kenya servers struggle every month — this is predictable, so it's solvable with pre-warming.

**Strategy:**

1. **Auto-scaling (ECS):** `aws_appautoscaling_policy` targets 60% CPU — scales from 2 to 10 tasks automatically (already in Terraform config)

2. **Pre-warm on the 24th:** Scheduled GitHub Actions job runs at 08:00 EAT on the 24th:
   ```yaml
   - run: aws ecs update-service --cluster btransact --service btransact-service --desired-count 6
   ```
   Scale back down on the 1st.

3. **Validate with k6 before the 25th** (`scripts/load-test.js`):
   ```bash
   BASE_URL=https://api.btransact.co.ke k6 run scripts/load-test.js
   ```
   Thresholds: p95 < 3s, error rate < 5%. If the test fails, fix before salary date — not during.

4. **Database connection pooling:** Add PgBouncer in front of RDS to prevent connection exhaustion under spike load.

---

## Q5 — First Priority: Secrets Management

**Why secrets first, not deployments or monitoring?**

Manual deployments cause downtime. No monitoring causes slow incident response. Both are operational problems.

**Plaintext secrets are a compliance and legal liability.**

- A single server breach exposes credentials for all 6 markets simultaneously — blast radius is the entire platform
- Bank of Kenya, CBN (Nigeria), and Bank of Ghana all require demonstrable access controls on financial data. Plaintext secrets fail every audit
- Credential theft is silent — unlike a deployment failure, you won't know it happened until money moves
- Fixing secrets management first builds the trust foundation: once secrets are in Vault/Secrets Manager, the CI/CD pipeline and monitoring stack can be built on top of it securely
- It also unblocks everything else: you can't safely automate deployments if the secrets those deployments use are sitting in plaintext config files

**Two-week plan:**
- Week 1: Inventory all secrets, deploy Vault, migrate Kenya (highest-volume market) as pilot
- Week 2: Roll out to remaining 5 markets, enforce — no plaintext secrets in any config file, PR checks block commits containing credentials
