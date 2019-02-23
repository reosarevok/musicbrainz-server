/*
 * @flow
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import {l} from '../i18n';
import commaOnlyList from '../i18n/commaOnlyList';
import localizeArtistRoles from '../i18n/localizeArtistRoles';

import EntityLink from './EntityLink';

type Props = {|
  +relations: $ReadOnlyArray<{|
    +entity: ArtistT,
    +roles: $ReadOnlyArray<string>,
  |}>,
|};

const ArtistRoles = ({relations}: Props) => (
  <ul>
    {relations.map(r => (
      <li key={r.entity.id}>
        {l('{artist} ({roles})', {
          artist: <EntityLink entity={r.entity} />,
          roles: commaOnlyList(localizeArtistRoles(r.roles)),
        })}
      </li>
    ))}
  </ul>
);

export default ArtistRoles;
