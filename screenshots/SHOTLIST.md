# Screenshot shot list

Save each image in this folder with the exact file name so the README links work.

| When | File name | What to capture |
|---|---|---|
| Step 0 (compute) | `03-baseline-apply.png` | Terminal: "Apply complete! Resources: N added" |
| Step 0 (compute) | `03-baseline-rg.png` | Portal: rg-webapp-compute-dev showing vm-web-01 and vm-db-01 |
| Phase 1 (compute) | `04-decommission-plan.png` | Terminal: plan listing the db VM and NIC, with "2 to destroy" |
| Phase 1 (compute) | `04-decommission-rg.png` | Portal: rg-webapp-compute-dev with vm-db-01 resources gone and vm-web-01 still there |
| Phases 2 to 4 (data) | `05-data-apply.png` | Terminal: "Apply complete!" for the data layer |
| Phases 2 to 4 (data) | `05-sql-overview.png` | Portal: sqldb-webapp Overview showing Online and Basic |
| Phases 2 to 4 (data) | `05-sql-networking.png` | Portal: SQL server, then Networking, showing the Azure services exception and the client IP rule |
| Phases 2 to 4 (data) | `05-kv-overview.png` | Portal: Key Vault Overview with the Vault URI |
| Phases 2 to 4 (data) | `05-kv-admin-role.png` | Portal: Key Vault, then Access control (IAM), then Role assignments, showing you as Key Vault Administrator |
| Phases 2 to 4 (data) | `05-kv-secret.png` | Portal: Key Vault, then Secrets, showing SqlAdminPassword as Enabled |
| Phase 5 (compute) | `06-identity-plan.png` | Terminal: plan showing vm-web-01 "updated in-place", "1 to change" |
| Phase 5 (compute) | `06-vm-identity.png` | Portal: vm-web-01, then Identity, showing Status On and the Object (principal) ID |
| Phase 5 (data) | `06-role-plan.png` | Terminal: plan showing "1 to add" for the role assignment |
| Phase 5 (data) | `06-kv-vm-role.png` | Portal: Key Vault IAM showing vm-web-01 as Key Vault Secrets User |
| Phase 6 | `07-dtu-metric.png` | Portal: sqldb-webapp Metrics chart for DTU percentage with Max aggregation |
| Phase 6 | `07-dtu-cli.png` | Terminal: output of `az monitor metrics list` |

Tips:
- Blur or crop your subscription ID, tenant ID, and public IP before committing.
- Never screenshot the secret value or the `TF_VAR_sql_admin_password` export line.
- If something breaks, screenshot the error too. Those make the best Troubleshooting rows.
