/*
 * @flow
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import React from 'react';

import {withCatalystContext} from '../context';
import {l, ln} from '../static/scripts/common/i18n';
import EditorLink from '../static/scripts/common/components/EditorLink';

import SeriesLayout from './SeriesLayout';

type Props = {|
  +$c: CatalystContextT,
  +canonicalURL: string,
  +entity: SeriesT,
  +privateEditors: number,
  +publicEditors: $ReadOnlyArray<EditorT>,
  +subscribed: boolean,
|};

const SeriesSubscribers = ({
  $c,
  canonicalURL,
  entity,
  privateEditors,
  publicEditors,
  subscribed,
}: Props) => (
  <SeriesLayout canonicalURL={canonicalURL} page="subscribers" series={entity} title={l('Subscribers')}>
    <h2>{l('Subscribers')}</h2>

    {(publicEditors.length || (privateEditors > 0)) ? (
      <>
        <p>{ln(
          'There is currently {num} user subscribed to {series}:',
          'There are currently {num} users subscribed to {series}:',
          publicEditors.length + privateEditors,
          {
            __react: true,
            num: publicEditors.length + privateEditors,
            series: entity.name,
          },
        )}
        </p>

        <ul>
          {publicEditors.map(editor => (
            <li key={editor.id}>
              <EditorLink editor={editor} />
            </li>
          ))}
          {publicEditors.length && (privateEditors > 0) ? (
            <li>{ln(
              'Plus {n} other anonymous user',
              'Plus {n} other anonymous users',
              privateEditors,
              {n: privateEditors},
            )}
            </li>
          ) : (
            privateEditors > 0 ? (
              <li>{ln(
                'An anonymous user',
                '{n} anonymous users',
                privateEditors,
                {n: privateEditors},
              )}
              </li>
            ) : null
          )}
        </ul>
      </>
    ) : (
      <p>{l('There are currently no users subscribed to {series}.',
        {__react: true, series: entity.name})}
      </p>
    )}

    {subscribed ? (
      <p>{l('You are currently subscribed. {unsub|Unsubscribe}?',
        {__react: true, unsub: '/account/subscriptions/series/remove?id=' + entity.id})}
      </p>
    ) : (
      (publicEditors.length + privateEditors === 0) ? (
        <p>{l('Be the first! {sub|Subscribe}?',
          {__react: true, sub: '/account/subscriptions/series/add?id=' + entity.id})}
        </p>
      ) : (
        <p>{l('You are not currently subscribed. {sub|Subscribe}?',
          {__react: true, sub: '/account/subscriptions/series/add?id=' + entity.id})}
        </p>
      )
    )}
  </SeriesLayout>
);

export default withCatalystContext(SeriesSubscribers);
