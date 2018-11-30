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

import CollectionLayout from './CollectionLayout';

type Props = {|
  +$c: CatalystContextT,
  +canonicalURL: string,
  +entity: CollectionT,
  +privateEditors: number,
  +publicEditors: $ReadOnlyArray<EditorT>,
  +subscribed: boolean,
|};

const CollectionSubscribers = ({
  $c,
  canonicalURL,
  entity,
  privateEditors,
  publicEditors,
  subscribed,
}: Props) => (
  <CollectionLayout canonicalURL={canonicalURL} collection={entity} page="subscribers" title={l('Subscribers')}>
    <h2>{l('Subscribers')}</h2>

    {(publicEditors.length || (privateEditors > 0)) ? (
      <>
        <p>{ln(
          'There is currently {num} user subscribed to {collection}:',
          'There are currently {num} users subscribed to {collection}:',
          publicEditors.length + privateEditors,
          {
            __react: true,
            collection: entity.name,
            num: publicEditors.length + privateEditors,
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
      <p>{l('There are currently no users subscribed to {collection}.',
        {__react: true, collection: entity.name})}
      </p>
    )}

    {subscribed ? (
      <p>{l('You are currently subscribed. {unsub|Unsubscribe}?',
        {__react: true, unsub: '/account/subscriptions/collection/remove?id=' + entity.id})}
      </p>
    ) : (
      (publicEditors.length + privateEditors === 0) ? (
        <p>{l('Be the first! {sub|Subscribe}?',
          {__react: true, sub: '/account/subscriptions/collection/add?id=' + entity.id})}
        </p>
      ) : (
        <p>{l('You are not currently subscribed. {sub|Subscribe}?',
          {__react: true, sub: '/account/subscriptions/collection/add?id=' + entity.id})}
        </p>
      )
    )}
  </CollectionLayout>
);

export default withCatalystContext(CollectionSubscribers);
