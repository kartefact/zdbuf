# Authorization

The upload framework checks two authorization objects before any DB write:

## S_TABU_DIS
- Activity: `02` (Change)
- Table class looked up from `TDDAT` for the target table
- If table has no entry in TDDAT, falls through to S_TABU_NAM

## S_TABU_NAM
- Activity: `02` (Change)
- Table name: exact match against target table

If either check passes, the upload proceeds. If both fail, `ZCX_DBUF_AUTH_ERROR` is raised and the report shows an authorization error message.

## Granting Access
Use SU21/PFCG to assign the relevant table authorization group or table name to the user's role.
