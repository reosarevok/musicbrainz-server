-- Generated by CompileSchemaScripts.pl from:
-- 20201028-mbs-1424-fks.sql
-- 20210311-mbs-11438-standalone.sql
-- 20210319-mbs-10208-standalone.sql
-- 20210319-mbs-10647.sql
-- 20210319-mbs-11451-standalone.sql
-- 20210507-mbs-11652-artist-series-fks.sql
\set ON_ERROR_STOP 1
BEGIN;
SET search_path = musicbrainz, public;
SET LOCAL statement_timeout = 0;
--------------------------------------------------------------------------------
SELECT '20201028-mbs-1424-fks.sql';


ALTER TABLE release_first_release_date
   ADD CONSTRAINT release_first_release_date_fk_release
   FOREIGN KEY (release)
   REFERENCES release(id)
   ON DELETE CASCADE;

ALTER TABLE recording_first_release_date
  ADD CONSTRAINT recording_first_release_date_fk_recording
  FOREIGN KEY (recording)
  REFERENCES recording(id)
  ON DELETE CASCADE;

--------------------------------------------------------------------------------
SELECT '20210311-mbs-11438-standalone.sql';


ALTER TABLE artist_release
    ADD CONSTRAINT artist_release_fk_artist
    FOREIGN KEY (artist)
    REFERENCES artist(id)
    ON DELETE CASCADE;

ALTER TABLE artist_release
    ADD CONSTRAINT artist_release_fk_release
    FOREIGN KEY (release)
    REFERENCES release(id)
    ON DELETE CASCADE;

ALTER TABLE artist_release_group
    ADD CONSTRAINT artist_release_group_fk_artist
    FOREIGN KEY (artist)
    REFERENCES artist(id)
    ON DELETE CASCADE;

ALTER TABLE artist_release_group
    ADD CONSTRAINT artist_release_group_fk_release_group
    FOREIGN KEY (release_group)
    REFERENCES release_group(id)
    ON DELETE CASCADE;

CREATE TRIGGER b_upd_artist_credit_name BEFORE UPDATE ON artist_credit_name
    FOR EACH ROW EXECUTE PROCEDURE b_upd_artist_credit_name();

CREATE TRIGGER a_ins_release_group_secondary_type_join AFTER INSERT ON release_group_secondary_type_join
    FOR EACH ROW EXECUTE PROCEDURE a_ins_release_group_secondary_type_join();

CREATE TRIGGER a_del_release_group_secondary_type_join AFTER DELETE ON release_group_secondary_type_join
    FOR EACH ROW EXECUTE PROCEDURE a_del_release_group_secondary_type_join();

CREATE TRIGGER b_upd_release_group_secondary_type_join BEFORE UPDATE ON release_group_secondary_type_join
    FOR EACH ROW EXECUTE PROCEDURE b_upd_release_group_secondary_type_join();

CREATE TRIGGER a_ins_release_label AFTER INSERT ON release_label
    FOR EACH ROW EXECUTE PROCEDURE a_ins_release_label();

CREATE TRIGGER a_upd_release_label AFTER UPDATE ON release_label
    FOR EACH ROW EXECUTE PROCEDURE a_upd_release_label();

CREATE TRIGGER a_del_release_label AFTER DELETE ON release_label
    FOR EACH ROW EXECUTE PROCEDURE a_del_release_label();

CREATE CONSTRAINT TRIGGER apply_artist_release_group_pending_updates
    AFTER INSERT OR UPDATE OR DELETE ON release DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE apply_artist_release_group_pending_updates();

CREATE CONSTRAINT TRIGGER apply_artist_release_pending_updates
    AFTER INSERT OR UPDATE OR DELETE ON release DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE apply_artist_release_pending_updates();

CREATE CONSTRAINT TRIGGER apply_artist_release_pending_updates
    AFTER INSERT OR UPDATE OR DELETE ON release_country DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE apply_artist_release_pending_updates();

CREATE CONSTRAINT TRIGGER apply_artist_release_pending_updates
    AFTER INSERT OR UPDATE OR DELETE ON release_first_release_date DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE apply_artist_release_pending_updates();

CREATE CONSTRAINT TRIGGER apply_artist_release_group_pending_updates
    AFTER INSERT OR UPDATE OR DELETE ON release_group DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE apply_artist_release_group_pending_updates();

CREATE CONSTRAINT TRIGGER apply_artist_release_group_pending_updates
    AFTER UPDATE ON release_group_meta DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE apply_artist_release_group_pending_updates();

CREATE CONSTRAINT TRIGGER apply_artist_release_group_pending_updates
    AFTER INSERT OR DELETE ON release_group_secondary_type_join DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE apply_artist_release_group_pending_updates();

CREATE CONSTRAINT TRIGGER apply_artist_release_pending_updates
    AFTER INSERT OR UPDATE OR DELETE ON release_label DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE apply_artist_release_pending_updates();

CREATE CONSTRAINT TRIGGER apply_artist_release_group_pending_updates
    AFTER INSERT OR UPDATE OR DELETE ON track DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE apply_artist_release_group_pending_updates();

CREATE CONSTRAINT TRIGGER apply_artist_release_pending_updates
    AFTER INSERT OR UPDATE OR DELETE ON track DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE apply_artist_release_pending_updates();

--------------------------------------------------------------------------------
SELECT '20210319-mbs-10208-standalone.sql';


ALTER TABLE editor_collection_gid_redirect
   ADD CONSTRAINT editor_collection_gid_redirect_fk_new_id
   FOREIGN KEY (new_id)
   REFERENCES editor_collection(id);

--------------------------------------------------------------------------------
SELECT '20210319-mbs-10647.sql';

DROP TRIGGER IF EXISTS b_del_label_special ON label;

CREATE TRIGGER b_del_label_special BEFORE DELETE ON label
    FOR EACH ROW WHEN (OLD.id IN (1, 3267)) EXECUTE PROCEDURE deny_special_purpose_deletion();

--------------------------------------------------------------------------------
SELECT '20210319-mbs-11451-standalone.sql';

DROP TRIGGER IF EXISTS a_ins_place ON place;

CREATE TRIGGER a_ins_place AFTER INSERT ON place
    FOR EACH ROW EXECUTE PROCEDURE a_ins_place();

ALTER TABLE ONLY musicbrainz.place_meta
    ADD CONSTRAINT place_meta_fk_id
    FOREIGN KEY (id)
    REFERENCES musicbrainz.place(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY musicbrainz.place_rating_raw
    ADD CONSTRAINT place_rating_raw_fk_editor
    FOREIGN KEY (editor)
    REFERENCES musicbrainz.editor(id);

ALTER TABLE ONLY musicbrainz.place_rating_raw
    ADD CONSTRAINT place_rating_raw_fk_place
    FOREIGN KEY (place)
    REFERENCES musicbrainz.place(id);

--------------------------------------------------------------------------------
SELECT '20210507-mbs-11652-artist-series-fks.sql';

------------------
-- constraints  --
------------------

ALTER TABLE series_type ADD CONSTRAINT allowed_series_entity_type
  CHECK (
    entity_type IN (
      'artist',
      'event',
      'recording',
      'release',
      'release_group',
      'work'
    )
  );

COMMIT;
