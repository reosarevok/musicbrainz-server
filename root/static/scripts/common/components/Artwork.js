/*
 * @flow strict-local
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import {commaOnlyListText} from '../i18n/commaOnlyList';
import {bracketedText} from '../utility/bracketed';
import Tooltip from '../../edit/components/Tooltip';
import hydrate from '../../../../utility/hydrate';

const lType = (x) => lp_attributes(x, 'cover_art_type');

function artworkHover(artwork: ArtworkT) {
  let result = '';
  if (artwork.types.length) {
    result = commaOnlyListText(artwork.types.map(lType));
  }
  if (artwork.comment) {
    result += ' ' + bracketedText(artwork.comment);
  }
  return result;
}

type Props = {
  +artwork: ArtworkT,
  +fallback?: string,
  +hover?: string,
  +message?: string,
};

export const ArtworkImage = ({
  artwork,
  fallback,
  message,
}: Props): React.Element<typeof React.Fragment> => (
  <>
    <noscript>
      <img src={artwork.small_ia_thumbnail} />
    </noscript>
    <span
      className="cover-art-image"
      data-fallback={fallback || ''}
      data-huge-thumbnail={artwork.huge_ia_thumbnail}
      data-large-thumbnail={artwork.large_ia_thumbnail}
      data-message={nonEmpty(message)
        ? message
        : l('Image not available yet, please try again in a few minutes.')}
      data-small-thumbnail={artwork.small_ia_thumbnail}
    />
  </>
);

export const Artwork: React.AbstractComponent<Props, void> =
hydrate<Props>('span.artwork', ({
  artwork,
  fallback,
  hover,
  message,
}: Props) => {
  const [showHover, setShowHover] = React.useState(false);
  const tooltipContent = nonEmpty(hover) ? hover : artworkHover(artwork);

  return (
    <>
      <a
        className={artwork.mime_type === 'application/pdf'
          ? 'artwork-pdf'
          : 'artwork-image'}
        href={artwork.image}
        onMouseEnter={() => setShowHover(true)}
        onMouseLeave={() => setShowHover(false)}
      >
        {artwork.mime_type === 'application/pdf' ? (
          <div
            className="file-format-tag"
            title={l(
              `This is a PDF file, the thumbnail may not show
              the entire contents of the file.`,
            )}
          >
            {l('PDF file')}
          </div>
        ) : null}
        <ArtworkImage
          artwork={artwork}
          fallback={fallback}
          hover={hover}
          message={message}
        />
      </a>
      {showHover ? (
        <Tooltip
          content={tooltipContent}
          hoverCallback={setShowHover}
        />
      ) : null}
    </>
  );
});
