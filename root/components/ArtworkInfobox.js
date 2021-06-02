/*
 * @flow strict-local
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import {CatalystContext} from '../context';
import {Artwork} from '../static/scripts/common/components/Artwork';
import {commaOnlyListText} from '../static/scripts/common/i18n/commaOnlyList';

const CoverArtLinks = ({
  artwork,
}: {artwork: ArtworkT}): React.Element<typeof React.Fragment> => (
  <>
    {artwork.small_thumbnail ? (
      <>
        <a href={artwork.small_thumbnail}>{l('250px')}</a>
        {' | '}
      </>
    ) : null}
    {artwork.large_thumbnail ? (
      <>
        <a href={artwork.large_thumbnail}>{l('500px')}</a>
        {' | '}
      </>
    ) : null}
    {artwork.huge_thumbnail ? (
      <>
        <a href={artwork.huge_thumbnail}>{l('1200px')}</a>
        {' | '}
      </>
    ) : null}
    <a href={artwork.image}>{l('original')}</a>
  </>
);

type Props = {
  +artwork: ArtworkT,
  +release: ReleaseT,
  +showButtons?: boolean,
};

export const ArtworkInfobox = ({
  artwork,
  release,
  showButtons = false,
}: Props): React.Element<'div'> => {
  const $c = React.useContext(CatalystContext);
  return (
    <div
      className={
        'artwork-cont' +
        (artwork.editsPending ? ' mp' : '')
      }
      key={artwork.id}
    >
      <div className="artwork" style={{position: 'relative'}}>
        <Artwork artwork={artwork} />
      </div>
      <p>
        {l('Types:')}
        {' '}
        {artwork.types?.length ? (
          commaOnlyListText(artwork.types.map(
            type => lp_attributes(type, 'cover_art_type'),
          ))
        ) : lp('-', 'missing data')}
      </p>
      {artwork.comment ? (
        <p>
          {artwork.comment}
        </p>
      ) : null}
      <p className="small">
        {l('All sizes:')}
        {' '}
        <CoverArtLinks artwork={artwork} />
      </p>
      {showButtons && $c.user ? (
        <div className="buttons">
          <a
            href={'/release/' + release.gid +
                  '/edit-cover-art/' + artwork.id}
          >
            {l('Edit')}
          </a>
          <a
            href={'/release/' + release.gid +
                  '/remove-cover-art/' + artwork.id}
          >
            {l('Remove')}
          </a>
        </div>
      ) : null}
    </div>
  );
};

export default ArtworkInfobox;
