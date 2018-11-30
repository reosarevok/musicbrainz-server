/*
 * @flow
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import React from 'react';
import type {Node as ReactNode} from 'react';

import {withCatalystContext} from '../context';
import Layout from '../layout';
import {l} from '../static/scripts/common/i18n';
import CollectionSidebar from '../layout/components/sidebar/CollectionSidebar';

import CollectionHeader from './CollectionHeader';

type Props = {|
  +$c: CatalystContextT,
  +canonicalURL: string,
  +children: ReactNode,
  +collection: CollectionT,
  +fullWidth?: boolean,
  +page: string,
  +title?: string,
|};

const CollectionLayout = ({
  $c,
  canonicalURL,
  children,
  collection,
  fullWidth,
  page,
  title,
}: Props) => {
  const mainTitle = l('Collection “{collection}”', {__react: true, collection: collection.name});

  return (
    <Layout canonical_url={canonicalURL} title={title ? mainTitle + ' - ' + title : mainTitle}>
      <div id="content">
        <CollectionHeader collection={collection} page={page} />
        {children}
      </div>
      {fullWidth ? null : <CollectionSidebar collection={collection} />}
    </Layout>
  );
};

export default withCatalystContext(CollectionLayout);
