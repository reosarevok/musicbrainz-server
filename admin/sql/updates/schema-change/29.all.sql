-- Generated by CompileSchemaScripts.pl from:
-- 20231005-edit-data-idx-link-type.sql
-- 20240220-mbs-13403.sql
-- 20240223-mbs-13421.sql
-- 20240319-mbs-13514-mirror.sql
\set ON_ERROR_STOP 1
BEGIN;
SET search_path = musicbrainz, public;
SET LOCAL statement_timeout = 0;
--------------------------------------------------------------------------------
SELECT '20231005-edit-data-idx-link-type.sql';


DROP INDEX IF EXISTS edit_data_idx_link_type;

CREATE INDEX edit_data_idx_link_type ON edit_data USING GIN (
    array_remove(ARRAY[
                     (data#>>'{link_type,id}')::int,
                     (data#>>'{link,link_type,id}')::int,
                     (data#>>'{old,link_type,id}')::int,
                     (data#>>'{new,link_type,id}')::int,
                     (data#>>'{relationship,link,type,id}')::int
                 ], NULL)
);

--------------------------------------------------------------------------------
SELECT '20240220-mbs-13403.sql';


ALTER TABLE link_type DROP COLUMN priority CASCADE;

--------------------------------------------------------------------------------
SELECT '20240223-mbs-13421.sql';

CREATE TABLE editor_collection_genre (
    collection INTEGER NOT NULL,
    genre INTEGER NOT NULL,
    added TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    position INTEGER NOT NULL DEFAULT 0 CHECK (position >= 0),
    comment TEXT DEFAULT '' NOT NULL
);

ALTER TABLE editor_collection_genre ADD CONSTRAINT editor_collection_genre_pkey PRIMARY KEY (collection, genre);

ALTER TABLE editor_collection_type
      DROP CONSTRAINT IF EXISTS allowed_collection_entity_type;

INSERT INTO editor_collection_type (id, name, entity_type, parent, child_order, gid)
     VALUES (16, 'Genre', 'genre', NULL, 2, generate_uuid_v3('6ba7b8119dad11d180b400c04fd430c8', 'editor_collection_type' || 16));

--------------------------------------------------------------------------------
SELECT '20240319-mbs-13514-mirror.sql';


ALTER TABLE label DROP CONSTRAINT IF EXISTS label_label_code_check;

ALTER TABLE label DROP CONSTRAINT IF EXISTS label_code_length;

COMMIT;
