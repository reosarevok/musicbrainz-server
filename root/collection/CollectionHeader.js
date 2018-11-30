/*
 * @flow
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import React from 'react';

import {l} from '../static/scripts/common/i18n';
import EntityTabLink from '../components/EntityTabLink';
import SubHeader from '../components/SubHeader';
import Tabs from '../components/Tabs';
import EditorLink from '../static/scripts/common/components/EditorLink';
import EntityLink from '../static/scripts/common/components/EntityLink';
import {withCatalystContext} from '../context';


type Props = {|
  +$c: CatalystContextT,
  +collection: CollectionT,
  +page: string,
|};

const CollectionHeader = ({$c, collection, page}: Props) => {
  const subHeading = (
    <>
      {collection.public ? (
        l('Public collection by {owner}',
          {
            __react: true,
            owner: <EditorLink editor={collection.editor} />,
          })
      ) : l('Private collection')}
      {collection.editor ? (
        <span className="small">
          {[
            ' (',
            <a href={'/user/' + collection.editor.name + '/collections'} key={collection.editor.name}>
              {$c.user && collection.editor && collection.editor.id === $c.user.id ? (
                l('See all of your collections')
              ) : (
                l("See all of {editor}'s public collections", {__react: true, editor: collection.editor.name})
              )}
            </a>,
            ')',
          ]}
        </span>
      ) : null}
    </>
  );
  return (
    <>
      <div className="collectionheader">
        <h1>
          <EntityLink entity={collection} />
        </h1>
        <SubHeader subHeading={subHeading} />
      </div>

      <Tabs>
        <EntityTabLink
          content={l('Overview')}
          entity={collection}
          key=""
          selected={'index' === page}
          subPath=""
        />
        {$c.user && collection.editor && collection.editor.id === $c.user.id ? (
          <>
            <EntityTabLink
              content={l('Edit')}
              entity={collection}
              key="own_collection/edit"
              selected={'edit' === page}
              subPath="own_collection/edit"
            />
            <EntityTabLink
              content={l('Remove')}
              entity={collection}
              key="own_collection/delete"
              selected={'delete' === page}
              subPath="own_collection/delete"
            />
          </>
        ) : null}
      </Tabs>
    </>
  );
};


export default withCatalystContext(CollectionHeader);
