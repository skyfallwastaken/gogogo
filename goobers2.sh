#!/bin/bash

DB="postgres"
TABLE="heartbeats"
MWM=4        # parallel workers per index build
MEM="6GB"    # maintenance_work_mem per session (4 parallel * 6GB = 24GB per batch)
BATCH=16      # concurrent index jobs at a time (4 * 4 workers = 16 cores, leaves headroom)

INDEXES=(
  index_heartbeats_on_user_id_with_ip
  heartbeats_pkey
  idx_heartbeats_coding_time_user
  idx_heartbeats_user_time_active
  index_heartbeats_on_user_agent
  index_heartbeats_on_category_and_time
  index_heartbeats_on_fields_hash_when_not_deleted
  index_heartbeats_on_source_type_time_user_project
  index_heartbeats_on_user_id
  index_heartbeats_on_user_time_category
  index_heartbeats_on_project
  index_heartbeats_on_project_and_time
  idx_heartbeats_user_time_project_stats
  idx_heartbeats_user_time_language_stats
  idx_heartbeats_user_project_time_stats
  idx_heartbeats_user_category_time
  index_heartbeats_on_ip_address
  index_heartbeats_on_machine
  idx_heartbeats_user_editor_time
  idx_heartbeats_user_language_time
  index_heartbeats_on_user_source_id_direct
)

reindex_one() {
  local idx=$1
  echo "[$(date +%T)] Starting: $idx"

  psql -d "$DB" \
    -c "SET maintenance_work_mem = '$MEM'" \
    -c "SET max_parallel_maintenance_workers = $MWM" \
    -c "SET max_parallel_workers = 20" \
    -c "REINDEX INDEX $idx"

  echo "[$(date +%T)] Done:     $idx"
}

export -f reindex_one
export DB MWM MEM

# Run in batches of $BATCH using GNU parallel or xargs
printf '%s\n' "${INDEXES[@]}" | xargs -P "$BATCH" -I{} bash -c 'reindex_one "$@"' _ {}
