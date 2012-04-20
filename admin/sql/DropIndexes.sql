-- Automatically generated, do not edit.
\unset ON_ERROR_STOP

DROP INDEX artist_alias_idx_artist;
DROP INDEX artist_alias_idx_locale_artist;
DROP INDEX artist_credit_name_idx_artist;
DROP INDEX artist_idx_gid;
DROP INDEX artist_idx_ipi_code;
DROP INDEX artist_idx_name;
DROP INDEX artist_idx_sort_name;
DROP INDEX artist_name_idx_lower_name;
DROP INDEX artist_name_idx_musicbrainz_collate;
DROP INDEX artist_name_idx_name;
DROP INDEX artist_name_idx_page;
DROP INDEX artist_rating_raw_idx_artist;
DROP INDEX artist_rating_raw_idx_editor;
DROP INDEX artist_tag_idx_artist;
DROP INDEX artist_tag_idx_tag;
DROP INDEX artist_tag_raw_idx_artist;
DROP INDEX artist_tag_raw_idx_editor;
DROP INDEX artist_tag_raw_idx_tag;
DROP INDEX cdtoc_idx_discid;
DROP INDEX cdtoc_idx_freedb_id;
DROP INDEX cdtoc_raw_discid;
DROP INDEX cdtoc_raw_toc;
DROP INDEX cdtoc_raw_track_offset;
DROP INDEX country_idx_iso_code;
DROP INDEX edit_artist_idx;
DROP INDEX edit_artist_idx_status;
DROP INDEX edit_idx_editor;
DROP INDEX edit_idx_status;
DROP INDEX edit_idx_type;
DROP INDEX edit_label_idx;
DROP INDEX edit_label_idx_status;
DROP INDEX edit_note_idx_edit;
DROP INDEX edit_recording_idx;
DROP INDEX edit_release_group_idx;
DROP INDEX edit_release_idx;
DROP INDEX edit_url_idx;
DROP INDEX edit_work_idx;
DROP INDEX editor_collection_idx_editor;
DROP INDEX editor_collection_idx_gid;
DROP INDEX editor_collection_idx_name;
DROP INDEX editor_idx_name;
DROP INDEX editor_preference_idx_editor_name;
DROP INDEX editor_subscribe_artist_idx_artist;
DROP INDEX editor_subscribe_artist_idx_uniq;
DROP INDEX editor_subscribe_editor_idx_uniq;
DROP INDEX editor_subscribe_label_idx_label;
DROP INDEX editor_subscribe_label_idx_uniq;
DROP INDEX isrc_idx_isrc;
DROP INDEX isrc_idx_isrc_recording;
DROP INDEX isrc_idx_recording;
DROP INDEX iswc_idx_iswc;
DROP INDEX iswc_idx_work;
DROP INDEX l_artist_artist_idx_entity1;
DROP INDEX l_artist_artist_idx_uniq;
DROP INDEX l_artist_label_idx_entity1;
DROP INDEX l_artist_label_idx_uniq;
DROP INDEX l_artist_recording_idx_entity1;
DROP INDEX l_artist_recording_idx_uniq;
DROP INDEX l_artist_release_group_idx_entity1;
DROP INDEX l_artist_release_group_idx_uniq;
DROP INDEX l_artist_release_idx_entity1;
DROP INDEX l_artist_release_idx_uniq;
DROP INDEX l_artist_url_idx_entity1;
DROP INDEX l_artist_url_idx_uniq;
DROP INDEX l_artist_work_idx_entity1;
DROP INDEX l_artist_work_idx_uniq;
DROP INDEX l_label_label_idx_entity1;
DROP INDEX l_label_label_idx_uniq;
DROP INDEX l_label_recording_idx_entity1;
DROP INDEX l_label_recording_idx_uniq;
DROP INDEX l_label_release_group_idx_entity1;
DROP INDEX l_label_release_group_idx_uniq;
DROP INDEX l_label_release_idx_entity1;
DROP INDEX l_label_release_idx_uniq;
DROP INDEX l_label_url_idx_entity1;
DROP INDEX l_label_url_idx_uniq;
DROP INDEX l_label_work_idx_entity1;
DROP INDEX l_label_work_idx_uniq;
DROP INDEX l_recording_recording_idx_entity1;
DROP INDEX l_recording_recording_idx_uniq;
DROP INDEX l_recording_release_group_idx_entity1;
DROP INDEX l_recording_release_group_idx_uniq;
DROP INDEX l_recording_release_idx_entity1;
DROP INDEX l_recording_release_idx_uniq;
DROP INDEX l_recording_url_idx_entity1;
DROP INDEX l_recording_url_idx_uniq;
DROP INDEX l_recording_work_idx_entity1;
DROP INDEX l_recording_work_idx_uniq;
DROP INDEX l_release_group_release_group_idx_entity1;
DROP INDEX l_release_group_release_group_idx_uniq;
DROP INDEX l_release_group_url_idx_entity1;
DROP INDEX l_release_group_url_idx_uniq;
DROP INDEX l_release_group_work_idx_entity1;
DROP INDEX l_release_group_work_idx_uniq;
DROP INDEX l_release_release_group_idx_entity1;
DROP INDEX l_release_release_group_idx_uniq;
DROP INDEX l_release_release_idx_entity1;
DROP INDEX l_release_release_idx_uniq;
DROP INDEX l_release_url_idx_entity1;
DROP INDEX l_release_url_idx_uniq;
DROP INDEX l_release_work_idx_entity1;
DROP INDEX l_release_work_idx_uniq;
DROP INDEX l_url_url_idx_entity1;
DROP INDEX l_url_url_idx_uniq;
DROP INDEX l_url_work_idx_entity1;
DROP INDEX l_url_work_idx_uniq;
DROP INDEX l_work_work_idx_entity1;
DROP INDEX l_work_work_idx_uniq;
DROP INDEX label_alias_idx_label;
DROP INDEX label_alias_idx_locale_label;
DROP INDEX label_idx_gid;
DROP INDEX label_idx_ipi_code;
DROP INDEX label_idx_name;
DROP INDEX label_idx_sort_name;
DROP INDEX label_name_idx_lower_name;
DROP INDEX label_name_idx_musicbrainz_collate;
DROP INDEX label_name_idx_name;
DROP INDEX label_name_idx_page;
DROP INDEX label_rating_raw_idx_editor;
DROP INDEX label_rating_raw_idx_label;
DROP INDEX label_tag_idx_label;
DROP INDEX label_tag_idx_tag;
DROP INDEX label_tag_raw_idx_editor;
DROP INDEX label_tag_raw_idx_label;
DROP INDEX label_tag_raw_idx_tag;
DROP INDEX language_idx_iso_code_1;
DROP INDEX language_idx_iso_code_2b;
DROP INDEX language_idx_iso_code_2t;
DROP INDEX link_attribute_type_idx_gid;
DROP INDEX link_idx_type_attr;
DROP INDEX link_type_idx_gid;
DROP INDEX medium_cdtoc_idx_cdtoc;
DROP INDEX medium_cdtoc_idx_medium;
DROP INDEX medium_cdtoc_idx_uniq;
DROP INDEX medium_idx_release;
DROP INDEX medium_idx_tracklist;
DROP INDEX puid_idx_puid;
DROP INDEX recording_idx_artist_credit;
DROP INDEX recording_idx_gid;
DROP INDEX recording_idx_name;
DROP INDEX recording_puid_idx_puid;
DROP INDEX recording_puid_idx_uniq;
DROP INDEX recording_rating_raw_idx_editor;
DROP INDEX recording_rating_raw_idx_track;
DROP INDEX recording_tag_idx_recording;
DROP INDEX recording_tag_idx_tag;
DROP INDEX recording_tag_raw_idx_editor;
DROP INDEX recording_tag_raw_idx_tag;
DROP INDEX recording_tag_raw_idx_track;
DROP INDEX release_group_idx_artist_credit;
DROP INDEX release_group_idx_gid;
DROP INDEX release_group_idx_name;
DROP INDEX release_group_rating_raw_idx_editor;
DROP INDEX release_group_rating_raw_idx_release_group;
DROP INDEX release_group_tag_idx_release_group;
DROP INDEX release_group_tag_idx_tag;
DROP INDEX release_group_tag_raw_idx_editor;
DROP INDEX release_group_tag_raw_idx_release;
DROP INDEX release_group_tag_raw_idx_tag;
DROP INDEX release_idx_artist_credit;
DROP INDEX release_idx_date;
DROP INDEX release_idx_gid;
DROP INDEX release_idx_name;
DROP INDEX release_idx_release_group;
DROP INDEX release_label_idx_label;
DROP INDEX release_label_idx_release;
DROP INDEX release_name_idx_musicbrainz_collate;
DROP INDEX release_name_idx_name;
DROP INDEX release_name_idx_page;
DROP INDEX release_raw_idx_last_modified;
DROP INDEX release_raw_idx_lookup_count;
DROP INDEX release_raw_idx_modify_count;
DROP INDEX script_idx_iso_code;
DROP INDEX statistic_name;
DROP INDEX statistic_name_date_collected;
DROP INDEX tag_idx_name;
DROP INDEX track_idx_artist_credit;
DROP INDEX track_idx_name;
DROP INDEX track_idx_recording;
DROP INDEX track_idx_tracklist;
DROP INDEX track_name_idx_musicbrainz_collate;
DROP INDEX track_name_idx_name;
DROP INDEX track_raw_idx_release;
DROP INDEX tracklist_idx_track_count;
DROP INDEX tracklist_index_idx;
DROP INDEX url_idx_gid;
DROP INDEX url_idx_url;
DROP INDEX vote_idx_edit;
DROP INDEX vote_idx_editor;
DROP INDEX work_alias_idx_locale_work;
DROP INDEX work_alias_idx_work;
DROP INDEX work_idx_artist_credit;
DROP INDEX work_idx_gid;
DROP INDEX work_idx_name;
DROP INDEX work_name_idx_musicbrainz_collate;
DROP INDEX work_name_idx_name;
DROP INDEX work_name_idx_page;
DROP INDEX work_tag_idx_tag;
