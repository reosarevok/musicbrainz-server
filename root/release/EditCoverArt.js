/*
 * @flow strict-local
 * Copyright (C) 2022 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import {Artwork} from '../components/Artwork.js';
import * as manifest from '../static/manifest.mjs';
import EnterEdit from '../static/scripts/edit/components/EnterEdit.js';
import EnterEditNote
  from '../static/scripts/edit/components/EnterEditNote.js';

import CoverArtFields from './CoverArtFields.js';
import ReleaseLayout from './ReleaseLayout.js';
import {type EditCoverArtFormT} from './types.js';

type PropsT = {
  +artwork: ArtworkT,
  +form: EditCoverArtFormT,
  +release: ReleaseWithMediumsT,
  +typeIdOptions: SelectOptionsT,
};

const EditCoverArt = ({
  artwork,
  form,
  release,
  typeIdOptions,
}: PropsT): React.Element<typeof ReleaseLayout> => {
  return (
    <ReleaseLayout
      entity={release}
      page="edit_cover_art"
      title={l('Edit Cover Art')}
    >
      <h2>{l('Edit Cover Art')}</h2>

      <form className="cover-art" id="edit-cover-art" method="post">
        <div className="edit-cover-art float-right">
          <Artwork artwork={artwork} />
        </div>

        <CoverArtFields form={form} typeIdOptions={typeIdOptions} />

        <EnterEditNote field={form.field.edit_note} />
        <EnterEdit form={form} />

      </form>
      {manifest.js('release/index', {async: 'async'})}
    </ReleaseLayout>
  );
};

export default EditCoverArt;
