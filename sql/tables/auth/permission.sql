
-- table containing possible permissions

CREATE TABLE base.permission (
  permission TEXT NOT NULL,
  conference_permission BOOL NOT NULL DEFAULT FALSE,
  rank INTEGER
);

CREATE TABLE auth.permission (
  PRIMARY KEY(permission)
) INHERITS( base.permission );

CREATE TABLE log.permission (
  PRIMARY KEY(log_transaction_id,permission)
) INHERITS( base.logging, base.permission );

CREATE INDEX log_permission_permission_idx ON log.permission( permission );
CREATE INDEX log_permission_log_transaction_id_idx ON log.permission( log_transaction_id );

