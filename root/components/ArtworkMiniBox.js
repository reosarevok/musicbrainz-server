/*
 * @flow strict-local
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import {Artwork} from '../static/scripts/common/components/Artwork';

type Props = {
  +artwork: ArtworkT,
  +className?: string,
  +count: number,
};

export const ArtworkMiniBox = ({
  artwork,
  className,
  count,
}: Props): React.Element<'div'> => (
  <div
    className={'thumb-position' +
                (nonEmpty(className) ? ' ' + className : '')}
  >
    <Artwork artwork={artwork} />
    <button className="left" type="button">{'←'}</button>
    <button
      className="right"
      style={{float: 'right'}}
      type="button"
    >
      {'→'}
    </button>
    <input
      className="id"
      id={`id-reorder-cover-art.artwork.${count}.id`}
      name={`reorder-cover-art.artwork.${count}.id`}
      type="hidden"
      value={artwork.id}
    />
    <input
      className="position"
      id={`id-reorder-cover-art.artwork.${count}.position`}
      name={`reorder-cover-art.artwork.${count}.position`}
      type="hidden"
      value={count + 1}
    />
  </div>
);

export default ArtworkMiniBox;
