-- Generated by CompileSchemaScripts.pl from:
-- 20210526-a_upd_release_event.sql
-- 20210606-mbs-11682.sql
-- 20220408-immutable-link-tables.sql
-- 20220408-mbs-12249.sql
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
SELECT '20220408-immutable-link-tables.sql';


CREATE OR REPLACE FUNCTION deny_deprecated_links()
RETURNS trigger AS $$
BEGIN
  IF (SELECT is_deprecated FROM link_type WHERE id = NEW.link_type)
  THEN
    RAISE EXCEPTION 'Attempt to create a relationship with a deprecated type';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION b_upd_link() RETURNS trigger AS $$
BEGIN
    -- Like artist credits, links are shared across many entities
    -- (relationships) and so are immutable: they can only be inserted
    -- or deleted.
    --
    -- This helps ensure the data integrity of relationships and other
    -- materialized tables that rely on their immutability, like
    -- area_containment.
    RAISE EXCEPTION 'link rows are immutable';
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION b_upd_link_attribute() RETURNS trigger AS $$
BEGIN
    -- Refer to b_upd_link.
    RAISE EXCEPTION 'link_attribute rows are immutable';
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION b_upd_link_attribute_credit() RETURNS trigger AS $$
BEGIN
    -- Refer to b_upd_link.
    RAISE EXCEPTION 'link_attribute_credit rows are immutable';
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION b_upd_link_attribute_text_value() RETURNS trigger AS $$
BEGIN
    -- Refer to b_upd_link.
    RAISE EXCEPTION 'link_attribute_text_value rows are immutable';
END;
$$ LANGUAGE 'plpgsql';

--------------------------------------------------------------------------------
SELECT '20220408-mbs-12249.sql';


CREATE TABLE area_containment (
    descendant          INTEGER NOT NULL, -- PK, references area.id
    parent              INTEGER NOT NULL, -- PK, references area.id
    depth               SMALLINT NOT NULL
);

CREATE OR REPLACE FUNCTION a_ins_l_area_area_mirror() RETURNS trigger AS $$
DECLARE
    part_of_area_link_type_id CONSTANT SMALLINT := 356;
BEGIN
    -- DO NOT modify any replicated tables in this function; it's used
    -- by a trigger on mirrors.
    IF (SELECT link_type FROM link WHERE id = NEW.link) = part_of_area_link_type_id THEN
        PERFORM update_area_containment_mirror(ARRAY[NEW.entity0], ARRAY[NEW.entity1]);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION a_upd_l_area_area_mirror() RETURNS trigger AS $$
DECLARE
    part_of_area_link_type_id CONSTANT SMALLINT := 356;
    old_lt_id INTEGER;
    new_lt_id INTEGER;
BEGIN
    -- DO NOT modify any replicated tables in this function; it's used
    -- by a trigger on mirrors.
    SELECT link_type INTO old_lt_id FROM link WHERE id = OLD.link;
    SELECT link_type INTO new_lt_id FROM link WHERE id = NEW.link;
    IF (
        (
            old_lt_id = part_of_area_link_type_id AND
            new_lt_id = part_of_area_link_type_id AND
            (OLD.entity0 != NEW.entity0 OR OLD.entity1 != NEW.entity1)
        ) OR
        (old_lt_id = part_of_area_link_type_id) != (new_lt_id = part_of_area_link_type_id)
    ) THEN
        PERFORM update_area_containment_mirror(ARRAY[OLD.entity0, NEW.entity0], ARRAY[OLD.entity1, NEW.entity1]);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION a_del_l_area_area_mirror() RETURNS trigger AS $$
DECLARE
    part_of_area_link_type_id CONSTANT SMALLINT := 356;
BEGIN
    -- DO NOT modify any replicated tables in this function; it's used
    -- by a trigger on mirrors.
    IF (SELECT link_type FROM link WHERE id = OLD.link) = part_of_area_link_type_id THEN
        PERFORM update_area_containment_mirror(ARRAY[OLD.entity0], ARRAY[OLD.entity1]);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_area_parent_hierarchy_rows(
    descendant_area_ids INTEGER[]
) RETURNS SETOF area_containment AS $$
DECLARE
    part_of_area_link_type_id CONSTANT SMALLINT := 356;
BEGIN
    RETURN QUERY EXECUTE $SQL$
        WITH RECURSIVE area_parent_hierarchy(descendant, parent, path, cycle) AS (
            SELECT entity1, entity0, ARRAY[ROW(entity1, entity0)], FALSE
              FROM l_area_area laa
              JOIN link ON laa.link = link.id
             WHERE link.link_type = $1
    $SQL$ || (CASE WHEN descendant_area_ids IS NULL THEN '' ELSE 'AND entity1 = any($2)' END) ||
    $SQL$
             UNION ALL
            SELECT descendant, entity0, path || ROW(descendant, entity0), ROW(descendant, entity0) = any(path)
              FROM l_area_area laa
              JOIN link ON laa.link = link.id
              JOIN area_parent_hierarchy ON area_parent_hierarchy.parent = laa.entity1
             WHERE link.link_type = $1
               AND descendant != entity0
               AND NOT cycle
        )
        SELECT descendant, parent, array_length(path, 1)::SMALLINT
          FROM area_parent_hierarchy
    $SQL$
    USING part_of_area_link_type_id, descendant_area_ids;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_area_descendant_hierarchy_rows(
    parent_area_ids INTEGER[]
) RETURNS SETOF area_containment AS $$
DECLARE
    part_of_area_link_type_id CONSTANT SMALLINT := 356;
BEGIN
    RETURN QUERY EXECUTE $SQL$
        WITH RECURSIVE area_descendant_hierarchy(descendant, parent, path, cycle) AS (
            SELECT entity1, entity0, ARRAY[ROW(entity1, entity0)], FALSE
              FROM l_area_area laa
              JOIN link ON laa.link = link.id
             WHERE link.link_type = $1
    $SQL$ || (CASE WHEN parent_area_ids IS NULL THEN '' ELSE 'AND entity0 = any($2)' END) ||
    $SQL$
             UNION ALL
            SELECT entity1, parent, path || ROW(entity1, parent), ROW(entity1, parent) = any(path)
              FROM l_area_area laa
              JOIN link ON laa.link = link.id
              JOIN area_descendant_hierarchy ON area_descendant_hierarchy.descendant = laa.entity0
             WHERE link.link_type = $1
               AND parent != entity1
               AND NOT cycle
        )
        SELECT descendant, parent, array_length(path, 1)::SMALLINT
          FROM area_descendant_hierarchy
    $SQL$
    USING part_of_area_link_type_id, parent_area_ids;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_area_containment_mirror(
    parent_ids INTEGER[], -- entity0 of area-area "part of"
    descendant_ids INTEGER[] -- entity1
) RETURNS VOID AS $$
DECLARE
    part_of_area_link_type_id CONSTANT SMALLINT := 356;
    descendant_ids_to_update INTEGER[];
    parent_ids_to_update INTEGER[];
BEGIN
    -- DO NOT modify any replicated tables in this function; it's used
    -- by a trigger on mirrors.

    SELECT array_agg(descendant)
      INTO descendant_ids_to_update
      FROM area_containment
     WHERE parent = any(parent_ids);

    SELECT array_agg(parent)
      INTO parent_ids_to_update
      FROM area_containment
     WHERE descendant = any(descendant_ids);

    -- For INSERTS/UPDATES, include the new IDs that aren't present in
    -- area_containment yet.
    descendant_ids_to_update := descendant_ids_to_update || descendant_ids;
    parent_ids_to_update := parent_ids_to_update || parent_ids;

    DELETE FROM area_containment
     WHERE descendant = any(descendant_ids_to_update);

    DELETE FROM area_containment
     WHERE parent = any(parent_ids_to_update);

    -- Update the parents of all descendants of parent_ids.
    -- Update the descendants of all parents of descendant_ids.

    INSERT INTO area_containment
    SELECT DISTINCT ON (descendant, parent)
        descendant, parent, depth
      FROM (
          SELECT * FROM get_area_parent_hierarchy_rows(descendant_ids_to_update)
          UNION ALL
          SELECT * FROM get_area_descendant_hierarchy_rows(parent_ids_to_update)
      ) area_hierarchy
     ORDER BY descendant, parent, depth;
END;
$$ LANGUAGE plpgsql;

-- Note: when passing NULL, it doesn't matter whether we use
-- get_area_parent_hierarchy_rows vs. get_area_descendant_hierarchy_rows
-- to build the entire table.
INSERT INTO area_containment
SELECT DISTINCT ON (descendant, parent)
    descendant,
    parent,
    depth
 FROM get_area_parent_hierarchy_rows(NULL)
ORDER BY descendant, parent, depth;

ALTER TABLE area_containment ADD CONSTRAINT area_containment_pkey PRIMARY KEY (descendant, parent);

CREATE INDEX area_containment_idx_parent ON area_containment (parent);

COMMIT;
