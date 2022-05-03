-- Generated by CompileSchemaScripts.pl from:
-- 20210526-a_upd_release_event.sql
-- 20210606-mbs-11682.sql
-- 20220314-mbs-12252.sql
-- 20220314-mbs-12253.sql
-- 20220314-mbs-12254.sql
-- 20220314-mbs-12255.sql
\set ON_ERROR_STOP 1
BEGIN;
SET search_path = musicbrainz, public;
SET LOCAL statement_timeout = 0;
--------------------------------------------------------------------------------
SELECT '20210526-a_upd_release_event.sql';


CREATE OR REPLACE FUNCTION a_upd_release_event()
RETURNS TRIGGER AS $$
BEGIN
  IF (
    NEW.release != OLD.release OR
    NEW.date_year IS DISTINCT FROM OLD.date_year OR
    NEW.date_month IS DISTINCT FROM OLD.date_month OR
    NEW.date_day IS DISTINCT FROM OLD.date_day
  ) THEN
    PERFORM set_release_first_release_date(OLD.release);
    IF NEW.release != OLD.release THEN
        PERFORM set_release_first_release_date(NEW.release);
    END IF;

    PERFORM set_release_group_first_release_date(release_group)
    FROM release
    WHERE release.id IN (NEW.release, OLD.release);

    PERFORM set_releases_recordings_first_release_dates(ARRAY[NEW.release, OLD.release]);
  END IF;

  IF TG_TABLE_NAME = 'release_country' THEN
    IF NEW.country != OLD.country THEN
      INSERT INTO artist_release_pending_update VALUES (OLD.release);
    END IF;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

--------------------------------------------------------------------------------
SELECT '20210606-mbs-11682.sql';


CREATE OR REPLACE FUNCTION apply_artist_release_pending_updates()
RETURNS trigger AS $$
DECLARE
    release_ids INTEGER[];
    release_id INTEGER;
BEGIN
    -- DO NOT modify any replicated tables in this function; it's used
    -- by a trigger on mirrors.
    WITH pending AS (
        DELETE FROM artist_release_pending_update
        RETURNING release
    )
    SELECT array_agg(DISTINCT release)
    INTO release_ids
    FROM pending;

    IF coalesce(array_length(release_ids, 1), 0) > 0 THEN
        -- If the user hasn't generated `artist_release`, then we
        -- shouldn't update or insert to it. MBS determines whether to
        -- use this table based on it being non-empty, so a partial
        -- table would manifest as partial data on the website and
        -- webservice.
        PERFORM 1 FROM artist_release LIMIT 1;
        IF FOUND THEN
            DELETE FROM artist_release WHERE release = any(release_ids);

            FOREACH release_id IN ARRAY release_ids LOOP
                -- We handle each release ID separately because the
                -- `get_artist_release_rows` query can be planned much
                -- more efficiently that way.
                INSERT INTO artist_release
                SELECT * FROM get_artist_release_rows(release_id);
            END LOOP;
        END IF;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION apply_artist_release_group_pending_updates()
RETURNS trigger AS $$
DECLARE
    release_group_ids INTEGER[];
    release_group_id INTEGER;
BEGIN
    -- DO NOT modify any replicated tables in this function; it's used
    -- by a trigger on mirrors.
    WITH pending AS (
        DELETE FROM artist_release_group_pending_update
        RETURNING release_group
    )
    SELECT array_agg(DISTINCT release_group)
    INTO release_group_ids
    FROM pending;

    IF coalesce(array_length(release_group_ids, 1), 0) > 0 THEN
        -- If the user hasn't generated `artist_release_group`, then we
        -- shouldn't update or insert to it. MBS determines whether to
        -- use this table based on it being non-empty, so a partial
        -- table would manifest as partial data on the website and
        -- webservice.
        PERFORM 1 FROM artist_release_group LIMIT 1;
        IF FOUND THEN
            DELETE FROM artist_release_group WHERE release_group = any(release_group_ids);

            FOREACH release_group_id IN ARRAY release_group_ids LOOP
                -- We handle each release group ID separately because
                -- the `get_artist_release_group_rows` query can be
                -- planned much more efficiently that way.
                INSERT INTO artist_release_group
                SELECT * FROM get_artist_release_group_rows(release_group_id);
            END LOOP;
        END IF;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

--------------------------------------------------------------------------------
SELECT '20220314-mbs-12252.sql';


CREATE TABLE edit_genre
(
    edit                INTEGER NOT NULL, -- PK, references edit.id
    genre               INTEGER NOT NULL  -- PK, references genre.id CASCADE
);

ALTER TABLE edit_genre ADD CONSTRAINT edit_genre_pkey PRIMARY KEY (edit, genre);

CREATE INDEX edit_genre_idx ON edit_genre (genre);

--------------------------------------------------------------------------------
SELECT '20220314-mbs-12253.sql';


CREATE TABLE l_area_genre ( -- replicate
    id                  SERIAL,
    link                INTEGER NOT NULL, -- references link.id
    entity0             INTEGER NOT NULL, -- references area.id
    entity1             INTEGER NOT NULL, -- references genre.id
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    link_order          INTEGER NOT NULL DEFAULT 0 CHECK (link_order >= 0),
    entity0_credit      TEXT NOT NULL DEFAULT '',
    entity1_credit      TEXT NOT NULL DEFAULT ''
);

CREATE TABLE l_artist_genre ( -- replicate
    id                  SERIAL,
    link                INTEGER NOT NULL, -- references link.id
    entity0             INTEGER NOT NULL, -- references artist.id
    entity1             INTEGER NOT NULL, -- references genre.id
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    link_order          INTEGER NOT NULL DEFAULT 0 CHECK (link_order >= 0),
    entity0_credit      TEXT NOT NULL DEFAULT '',
    entity1_credit      TEXT NOT NULL DEFAULT ''
);

CREATE TABLE l_event_genre ( -- replicate
    id                  SERIAL,
    link                INTEGER NOT NULL, -- references link.id
    entity0             INTEGER NOT NULL, -- references event.id
    entity1             INTEGER NOT NULL, -- references genre.id
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    link_order          INTEGER NOT NULL DEFAULT 0 CHECK (link_order >= 0),
    entity0_credit      TEXT NOT NULL DEFAULT '',
    entity1_credit      TEXT NOT NULL DEFAULT ''
);

CREATE TABLE l_genre_genre ( -- replicate
    id                  SERIAL,
    link                INTEGER NOT NULL, -- references link.id
    entity0             INTEGER NOT NULL, -- references genre.id
    entity1             INTEGER NOT NULL, -- references genre.id
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    link_order          INTEGER NOT NULL DEFAULT 0 CHECK (link_order >= 0),
    entity0_credit      TEXT NOT NULL DEFAULT '',
    entity1_credit      TEXT NOT NULL DEFAULT ''
);

CREATE TABLE l_genre_instrument ( -- replicate
    id                  SERIAL,
    link                INTEGER NOT NULL, -- references link.id
    entity0             INTEGER NOT NULL, -- references genre.id
    entity1             INTEGER NOT NULL, -- references instrument.id
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    link_order          INTEGER NOT NULL DEFAULT 0 CHECK (link_order >= 0),
    entity0_credit      TEXT NOT NULL DEFAULT '',
    entity1_credit      TEXT NOT NULL DEFAULT ''
);

CREATE TABLE l_genre_label ( -- replicate
    id                  SERIAL,
    link                INTEGER NOT NULL, -- references link.id
    entity0             INTEGER NOT NULL, -- references genre.id
    entity1             INTEGER NOT NULL, -- references label.id
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    link_order          INTEGER NOT NULL DEFAULT 0 CHECK (link_order >= 0),
    entity0_credit      TEXT NOT NULL DEFAULT '',
    entity1_credit      TEXT NOT NULL DEFAULT ''
);

CREATE TABLE l_genre_place ( -- replicate
    id                  SERIAL,
    link                INTEGER NOT NULL, -- references link.id
    entity0             INTEGER NOT NULL, -- references genre.id
    entity1             INTEGER NOT NULL, -- references place.id
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    link_order          INTEGER NOT NULL DEFAULT 0 CHECK (link_order >= 0),
    entity0_credit      TEXT NOT NULL DEFAULT '',
    entity1_credit      TEXT NOT NULL DEFAULT ''
);

CREATE TABLE l_genre_recording ( -- replicate
    id                  SERIAL,
    link                INTEGER NOT NULL, -- references link.id
    entity0             INTEGER NOT NULL, -- references genre.id
    entity1             INTEGER NOT NULL, -- references recording.id
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    link_order          INTEGER NOT NULL DEFAULT 0 CHECK (link_order >= 0),
    entity0_credit      TEXT NOT NULL DEFAULT '',
    entity1_credit      TEXT NOT NULL DEFAULT ''
);

CREATE TABLE l_genre_release ( -- replicate
    id                  SERIAL,
    link                INTEGER NOT NULL, -- references link.id
    entity0             INTEGER NOT NULL, -- references genre.id
    entity1             INTEGER NOT NULL, -- references release.id
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    link_order          INTEGER NOT NULL DEFAULT 0 CHECK (link_order >= 0),
    entity0_credit      TEXT NOT NULL DEFAULT '',
    entity1_credit      TEXT NOT NULL DEFAULT ''
);

CREATE TABLE l_genre_release_group ( -- replicate
    id                  SERIAL,
    link                INTEGER NOT NULL, -- references link.id
    entity0             INTEGER NOT NULL, -- references genre.id
    entity1             INTEGER NOT NULL, -- references release_group.id
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    link_order          INTEGER NOT NULL DEFAULT 0 CHECK (link_order >= 0),
    entity0_credit      TEXT NOT NULL DEFAULT '',
    entity1_credit      TEXT NOT NULL DEFAULT ''
);

CREATE TABLE l_genre_series ( -- replicate
    id                  SERIAL,
    link                INTEGER NOT NULL, -- references link.id
    entity0             INTEGER NOT NULL, -- references genre.id
    entity1             INTEGER NOT NULL, -- references series.id
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    link_order          INTEGER NOT NULL DEFAULT 0 CHECK (link_order >= 0),
    entity0_credit      TEXT NOT NULL DEFAULT '',
    entity1_credit      TEXT NOT NULL DEFAULT ''
);

CREATE TABLE l_genre_url ( -- replicate
    id                  SERIAL,
    link                INTEGER NOT NULL, -- references link.id
    entity0             INTEGER NOT NULL, -- references genre.id
    entity1             INTEGER NOT NULL, -- references url.id
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    link_order          INTEGER NOT NULL DEFAULT 0 CHECK (link_order >= 0),
    entity0_credit      TEXT NOT NULL DEFAULT '',
    entity1_credit      TEXT NOT NULL DEFAULT ''
);

CREATE TABLE l_genre_work ( -- replicate
    id                  SERIAL,
    link                INTEGER NOT NULL, -- references link.id
    entity0             INTEGER NOT NULL, -- references genre.id
    entity1             INTEGER NOT NULL, -- references work.id
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    link_order          INTEGER NOT NULL DEFAULT 0 CHECK (link_order >= 0),
    entity0_credit      TEXT NOT NULL DEFAULT '',
    entity1_credit      TEXT NOT NULL DEFAULT ''
);


ALTER TABLE l_area_genre ADD CONSTRAINT l_area_genre_pkey PRIMARY KEY (id);
ALTER TABLE l_artist_genre ADD CONSTRAINT l_artist_genre_pkey PRIMARY KEY (id);
ALTER TABLE l_event_genre ADD CONSTRAINT l_event_genre_pkey PRIMARY KEY (id);
ALTER TABLE l_genre_genre ADD CONSTRAINT l_genre_genre_pkey PRIMARY KEY (id);
ALTER TABLE l_genre_instrument ADD CONSTRAINT l_genre_instrument_pkey PRIMARY KEY (id);
ALTER TABLE l_genre_label ADD CONSTRAINT l_genre_label_pkey PRIMARY KEY (id);
ALTER TABLE l_genre_place ADD CONSTRAINT l_genre_place_pkey PRIMARY KEY (id);
ALTER TABLE l_genre_recording ADD CONSTRAINT l_genre_recording_pkey PRIMARY KEY (id);
ALTER TABLE l_genre_release ADD CONSTRAINT l_genre_release_pkey PRIMARY KEY (id);
ALTER TABLE l_genre_release_group ADD CONSTRAINT l_genre_release_group_pkey PRIMARY KEY (id);
ALTER TABLE l_genre_series ADD CONSTRAINT l_genre_series_pkey PRIMARY KEY (id);
ALTER TABLE l_genre_url ADD CONSTRAINT l_genre_url_pkey PRIMARY KEY (id);
ALTER TABLE l_genre_work ADD CONSTRAINT l_genre_work_pkey PRIMARY KEY (id);

CREATE OR REPLACE FUNCTION delete_unused_url(ids INTEGER[])
RETURNS VOID AS $$
DECLARE
  clear_up INTEGER[];
BEGIN
  SELECT ARRAY(
    SELECT id FROM url url_row WHERE id = any(ids)
    EXCEPT
    SELECT url FROM edit_url JOIN edit ON (edit.id = edit_url.edit) WHERE edit.status = 1
    EXCEPT
    SELECT entity1 FROM l_area_url
    EXCEPT
    SELECT entity1 FROM l_artist_url
    EXCEPT
    SELECT entity1 FROM l_event_url
    EXCEPT
    SELECT entity1 FROM l_genre_url
    EXCEPT
    SELECT entity1 FROM l_instrument_url
    EXCEPT
    SELECT entity1 FROM l_label_url
    EXCEPT
    SELECT entity1 FROM l_place_url
    EXCEPT
    SELECT entity1 FROM l_recording_url
    EXCEPT
    SELECT entity1 FROM l_release_url
    EXCEPT
    SELECT entity1 FROM l_release_group_url
    EXCEPT
    SELECT entity1 FROM l_series_url
    EXCEPT
    SELECT entity1 FROM l_url_url
    EXCEPT
    SELECT entity0 FROM l_url_url
    EXCEPT
    SELECT entity0 FROM l_url_work
  ) INTO clear_up;

  DELETE FROM url_gid_redirect WHERE new_id = any(clear_up);
  DELETE FROM url WHERE id = any(clear_up);
END;
$$ LANGUAGE 'plpgsql';


CREATE UNIQUE INDEX l_area_genre_idx_uniq ON l_area_genre (entity0, entity1, link, link_order);
CREATE UNIQUE INDEX l_artist_genre_idx_uniq ON l_artist_genre (entity0, entity1, link, link_order);
CREATE UNIQUE INDEX l_event_genre_idx_uniq ON l_event_genre (entity0, entity1, link, link_order);
CREATE UNIQUE INDEX l_genre_genre_idx_uniq ON l_genre_genre (entity0, entity1, link, link_order);
CREATE UNIQUE INDEX l_genre_instrument_idx_uniq ON l_genre_instrument (entity0, entity1, link, link_order);
CREATE UNIQUE INDEX l_genre_label_idx_uniq ON l_genre_label (entity0, entity1, link, link_order);
CREATE UNIQUE INDEX l_genre_place_idx_uniq ON l_genre_place (entity0, entity1, link, link_order);
CREATE UNIQUE INDEX l_genre_recording_idx_uniq ON l_genre_recording (entity0, entity1, link, link_order);
CREATE UNIQUE INDEX l_genre_release_idx_uniq ON l_genre_release (entity0, entity1, link, link_order);
CREATE UNIQUE INDEX l_genre_release_group_idx_uniq ON l_genre_release_group (entity0, entity1, link, link_order);
CREATE UNIQUE INDEX l_genre_series_idx_uniq ON l_genre_series (entity0, entity1, link, link_order);
CREATE UNIQUE INDEX l_genre_url_idx_uniq ON l_genre_url (entity0, entity1, link, link_order);
CREATE UNIQUE INDEX l_genre_work_idx_uniq ON l_genre_work (entity0, entity1, link, link_order);

CREATE INDEX l_area_genre_idx_entity1 ON l_area_genre (entity1);
CREATE INDEX l_artist_genre_idx_entity1 ON l_artist_genre (entity1);
CREATE INDEX l_event_genre_idx_entity1 ON l_event_genre (entity1);
CREATE INDEX l_genre_genre_idx_entity1 ON l_genre_genre (entity1);
CREATE INDEX l_genre_instrument_idx_entity1 ON l_genre_instrument (entity1);
CREATE INDEX l_genre_label_idx_entity1 ON l_genre_label (entity1);
CREATE INDEX l_genre_place_idx_entity1 ON l_genre_place (entity1);
CREATE INDEX l_genre_recording_idx_entity1 ON l_genre_recording (entity1);
CREATE INDEX l_genre_release_idx_entity1 ON l_genre_release (entity1);
CREATE INDEX l_genre_release_group_idx_entity1 ON l_genre_release_group (entity1);
CREATE INDEX l_genre_series_idx_entity1 ON l_genre_series (entity1);
CREATE INDEX l_genre_url_idx_entity1 ON l_genre_url (entity1);
CREATE INDEX l_genre_work_idx_entity1 ON l_genre_work (entity1);


CREATE TABLE documentation.l_area_genre_example ( -- replicate (verbose)
  id INTEGER NOT NULL, -- PK, references musicbrainz.l_area_genre.id
  published BOOLEAN NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE documentation.l_artist_genre_example ( -- replicate (verbose)
  id INTEGER NOT NULL, -- PK, references musicbrainz.l_artist_genre.id
  published BOOLEAN NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE documentation.l_event_genre_example ( -- replicate (verbose)
  id INTEGER NOT NULL, -- PK, references musicbrainz.l_event_genre.id
  published BOOLEAN NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE documentation.l_genre_genre_example ( -- replicate (verbose)
  id INTEGER NOT NULL, -- PK, references musicbrainz.l_genre_genre.id
  published BOOLEAN NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE documentation.l_genre_instrument_example ( -- replicate (verbose)
  id INTEGER NOT NULL, -- PK, references musicbrainz.l_genre_instrument.id
  published BOOLEAN NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE documentation.l_genre_label_example ( -- replicate (verbose)
  id INTEGER NOT NULL, -- PK, references musicbrainz.l_genre_label.id
  published BOOLEAN NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE documentation.l_genre_place_example ( -- replicate (verbose)
  id INTEGER NOT NULL, -- PK, references musicbrainz.l_genre_place.id
  published BOOLEAN NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE documentation.l_genre_recording_example ( -- replicate (verbose)
  id INTEGER NOT NULL, -- PK, references musicbrainz.l_genre_recording.id
  published BOOLEAN NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE documentation.l_genre_release_example ( -- replicate (verbose)
  id INTEGER NOT NULL, -- PK, references musicbrainz.l_genre_release.id
  published BOOLEAN NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE documentation.l_genre_release_group_example ( -- replicate (verbose)
  id INTEGER NOT NULL, -- PK, references musicbrainz.l_genre_release_group.id
  published BOOLEAN NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE documentation.l_genre_series_example ( -- replicate (verbose)
  id INTEGER NOT NULL, -- PK, references musicbrainz.l_genre_series.id
  published BOOLEAN NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE documentation.l_genre_url_example ( -- replicate (verbose)
  id INTEGER NOT NULL, -- PK, references musicbrainz.l_genre_url.id
  published BOOLEAN NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE documentation.l_genre_work_example ( -- replicate (verbose)
  id INTEGER NOT NULL, -- PK, references musicbrainz.l_genre_work.id
  published BOOLEAN NOT NULL,
  name TEXT NOT NULL
);


ALTER TABLE documentation.l_area_genre_example ADD CONSTRAINT l_area_genre_example_pkey PRIMARY KEY (id);
ALTER TABLE documentation.l_artist_genre_example ADD CONSTRAINT l_artist_genre_example_pkey PRIMARY KEY (id);
ALTER TABLE documentation.l_event_genre_example ADD CONSTRAINT l_event_genre_example_pkey PRIMARY KEY (id);
ALTER TABLE documentation.l_genre_genre_example ADD CONSTRAINT l_genre_genre_example_pkey PRIMARY KEY (id);
ALTER TABLE documentation.l_genre_instrument_example ADD CONSTRAINT l_genre_instrument_example_pkey PRIMARY KEY (id);
ALTER TABLE documentation.l_genre_label_example ADD CONSTRAINT l_genre_label_example_pkey PRIMARY KEY (id);
ALTER TABLE documentation.l_genre_place_example ADD CONSTRAINT l_genre_place_example_pkey PRIMARY KEY (id);
ALTER TABLE documentation.l_genre_recording_example ADD CONSTRAINT l_genre_recording_example_pkey PRIMARY KEY (id);
ALTER TABLE documentation.l_genre_release_example ADD CONSTRAINT l_genre_release_example_pkey PRIMARY KEY (id);
ALTER TABLE documentation.l_genre_release_group_example ADD CONSTRAINT l_genre_release_group_example_pkey PRIMARY KEY (id);
ALTER TABLE documentation.l_genre_series_example ADD CONSTRAINT l_genre_series_example_pkey PRIMARY KEY (id);
ALTER TABLE documentation.l_genre_url_example ADD CONSTRAINT l_genre_url_example_pkey PRIMARY KEY (id);
ALTER TABLE documentation.l_genre_work_example ADD CONSTRAINT l_genre_work_example_pkey PRIMARY KEY (id);

--------------------------------------------------------------------------------
SELECT '20220314-mbs-12254.sql';


CREATE TABLE genre_annotation ( -- replicate (verbose)
    genre       INTEGER NOT NULL, -- PK, references genre.id
    annotation  INTEGER NOT NULL -- PK, references annotation.id
);

ALTER TABLE genre_annotation ADD CONSTRAINT genre_annotation_pkey PRIMARY KEY (genre, annotation);

--------------------------------------------------------------------------------
SELECT '20220314-mbs-12255.sql';


CREATE TABLE genre_alias_type ( -- replicate
    id                  SERIAL, -- PK,
    name                TEXT NOT NULL,
    parent              INTEGER, -- references genre_alias_type.id
    child_order         INTEGER NOT NULL DEFAULT 0,
    description         TEXT,
    gid                 uuid NOT NULL
);

ALTER TABLE genre_alias_type ADD CONSTRAINT genre_alias_type_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX genre_alias_type_idx_gid ON genre_alias_type (gid);

-- generate_uuid_v3('6ba7b8119dad11d180b400c04fd430c8', 'genre_type' || id);
INSERT INTO genre_alias_type (id, gid, name)
    VALUES (1, '61e89fea-acce-3908-a590-d999dc627ac9', 'Genre name'),
           (2, '5d81fc72-598a-3a9d-a85a-a471c6ba84dc', 'Search hint');

-- We drop and recreate the table to standardise it
-- rather than adding a ton of rows to it out of the standard order.
-- This is empty in production and mirrors but might not be on standalone
CREATE TEMPORARY TABLE tmp_genre_alias
    ON COMMIT DROP
    AS
    SELECT * FROM genre_alias;

DROP TABLE genre_alias;

CREATE TABLE genre_alias ( -- replicate (verbose)
    id                  SERIAL, --PK
    genre               INTEGER NOT NULL, -- references genre.id
    name                VARCHAR NOT NULL,
    locale              TEXT,
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    type                INTEGER, -- references genre_alias_type.id
    sort_name           VARCHAR NOT NULL,
    begin_date_year     SMALLINT,
    begin_date_month    SMALLINT,
    begin_date_day      SMALLINT,
    end_date_year       SMALLINT,
    end_date_month      SMALLINT,
    end_date_day        SMALLINT,
    primary_for_locale  BOOLEAN NOT NULL DEFAULT false,
    ended               BOOLEAN NOT NULL DEFAULT FALSE
      CHECK (
        (
          -- If any end date fields are not null, then ended must be true
          (end_date_year IS NOT NULL OR
           end_date_month IS NOT NULL OR
           end_date_day IS NOT NULL) AND
          ended = TRUE
        ) OR (
          -- Otherwise, all end date fields must be null
          (end_date_year IS NULL AND
           end_date_month IS NULL AND
           end_date_day IS NULL)
        )
      ),
    CONSTRAINT primary_check CHECK ((locale IS NULL AND primary_for_locale IS FALSE) OR (locale IS NOT NULL)),
    CONSTRAINT search_hints_are_empty
      CHECK (
        (type <> 2) OR (
          type = 2 AND sort_name = name AND
          begin_date_year IS NULL AND begin_date_month IS NULL AND begin_date_day IS NULL AND
          end_date_year IS NULL AND end_date_month IS NULL AND end_date_day IS NULL AND
          primary_for_locale IS FALSE AND locale IS NULL
        )
      )
);

ALTER TABLE genre_alias ADD CONSTRAINT genre_alias_pkey PRIMARY KEY (id);

CREATE INDEX genre_alias_idx_genre ON genre_alias (genre);
CREATE UNIQUE INDEX genre_alias_idx_primary ON genre_alias (genre, locale) WHERE primary_for_locale = TRUE AND locale IS NOT NULL;

INSERT INTO genre_alias (id, genre, name, locale, edits_pending, last_updated, type, sort_name)
SELECT id, genre, name, locale, edits_pending, last_updated, 1, name -- sortname = name, type = genre name
FROM tmp_genre_alias;

COMMIT;
