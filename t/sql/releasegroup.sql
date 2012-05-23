INSERT INTO artist_name (id, name) VALUES (1, 'Name');
INSERT INTO artist (id, gid, name, sort_name)
    VALUES (1, 'a9d99e40-72d7-11de-8a39-0800200c9a66', 1, 1);

INSERT INTO artist_credit (id, name, artist_count) VALUES (1, 1, 1);
INSERT INTO artist_credit_name (artist_credit, artist, name, position, join_phrase)
    VALUES (1, 1, 1, 0, NULL);

INSERT INTO release_name (id, name) VALUES (1, 'Release Group');
INSERT INTO release_name (id, name) VALUES (2, 'Release Name');
INSERT INTO release_name (id, name) VALUES (3, 'To Merge');

INSERT INTO release_group (id, gid, name, artist_credit, type, comment, edits_pending)
    VALUES (1, '7b5d22d0-72d7-11de-8a39-0800200c9a66', 1, 1, 1, 'Comment', 2);

INSERT INTO release_group (id, gid, name, artist_credit, type, comment, edits_pending)
    VALUES (2, '3b4faa80-72d9-11de-8a39-0800200c9a66', 2, 1, 1, 'Comment', 2);

INSERT INTO release (id, gid, name, artist_credit, release_group)
    VALUES (1, '4c767e70-72d8-11de-8a39-0800200c9a66', 2, 1, 1);

INSERT INTO editor (id, name, password) VALUES (1, 'editor', 'pass');
INSERT INTO annotation (id, editor, text, changelog) VALUES (1, 1, 'Annotation', 'change');
INSERT INTO release_group_annotation (release_group, annotation) VALUES (1, 1);

INSERT INTO release_group_gid_redirect (gid, new_id) VALUES ('77637e8c-be66-46ea-87b3-73addc722fc9', 1);

INSERT INTO artist_name (id, name) VALUES (2, 'Various Artists');
INSERT INTO artist (id, gid, name, sort_name)
    VALUES (2, '7a906020-72db-11de-8a39-0800200c9a66', 2, 2);
INSERT INTO artist_credit (id, name, artist_count) VALUES (2, 2, 1);
INSERT INTO artist_credit_name (artist_credit, artist, name, position, join_phrase) VALUES (2, 2, 2, 1, NULL);

INSERT into release_name (id, name) VALUES (4, 'Various Release');
INSERT INTO release_group (id, gid, name, artist_credit)
    VALUES (3, '25b6fe30-ff5b-11de-8a39-0800200c9a66', 4, 2);
INSERT INTO release (id, gid, name, artist_credit, release_group)
    VALUES (3, '25b6fe30-ff5b-11de-8a39-0800200c9a66', 4, 2, 3);

INSERT INTO track_name (id, name) VALUES (1, 'Track on recording');
INSERT INTO tracklist (id, track_count) VALUES (1, 1);
INSERT INTO medium (id, tracklist, release, position) VALUES (1, 1, 3, 1);
INSERT INTO recording (id, artist_credit, name, gid)
    VALUES (1, 2, 1, 'b43eb990-ff5b-11de-8a39-0800200c9a66');
INSERT INTO track (id, name, artist_credit, tracklist, position, number, recording)
    VALUES (1, 1, 1, 1, 1, 1, 1);

-- Test for searching by track artist
INSERT INTO artist (id, gid, name, sort_name)
    VALUES (3, 'baa99e40-72d7-11de-8a39-0800200c9a66', 1, 1);
INSERT INTO artist_credit (id, name, artist_count) VALUES (3, 2, 2);
INSERT INTO artist_credit_name (artist_credit, artist, name, position, join_phrase)
    VALUES (3, 2, 2, 1, NULL),
           (3, 3, 2, 2, NULL);

-- Both release groups contain tracks by artist 3
-- Release group 4 is by artist 1 & 3. Release 11 is by artist 1
-- Therefore release group 5 is the only VA release for artist 3
INSERT INTO release_group (id, gid, name, artist_credit)
    VALUES (4, '7b906020-72db-11de-8a39-0800200c9a70', 2, 3),
           (5, '7c906020-72db-11de-8a39-0800200c9a71', 2, 2);

INSERT INTO release (id, gid, name, release_group, artist_credit)
    VALUES (4, '7b906020-72db-11de-8a39-0800200c9a70', 2, 4, 3),
           (5, '7c906020-72db-11de-8a39-0800200c9a71', 2, 5, 2);

INSERT INTO tracklist (id, track_count) VALUES (6, 1);
INSERT INTO track (id, name, artist_credit, tracklist, position, number, recording)
    VALUES (6, 1, 3, 6, 1, 1, 1);
INSERT INTO medium (id, release, tracklist, position)
    VALUES (6, 4, 6, 1), (7, 5, 6, 1);

ALTER SEQUENCE release_name_id_seq RESTART 5;
ALTER SEQUENCE release_group_id_seq RESTART 6;


