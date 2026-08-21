# Architecture Decisions

## Storage Abstraction

### Context

Document Watcher currently uses the local filesystem for discovering,
archiving, and quarantining documents.

### Decision

Keep `archive_file()` and `quarantine_file()` as separate workflow
operations while allowing them to share a common storage abstraction
in the future.

### Why

Archiving and quarantining represent different business operations,
even though both interact with storage.

Keeping them separate allows the workflow to express intent clearly
while avoiding unnecessary duplication in the underlying storage
implementation.

### Future Direction

The storage implementation should eventually be replaceable without
requiring changes to `process_files()`.

Potential storage backends:

- Local filesystem
- Amazon S3
- Other object storage systems


## Current Processing Flow

```text
main()
  |
  v
process_files()
  |
  +--> discover_files()
  |
  +--> get_file_type()
  |
  +--> is_supported_document()
  |
  +--> archive_file()
  |
  +--> handle_processing_failure()
          |
          +--> write_failure_metadata()
          |
          +--> quarantine_file()
          |
          +--> verify_quarantine()
