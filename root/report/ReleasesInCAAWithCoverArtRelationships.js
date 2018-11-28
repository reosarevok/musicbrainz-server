/*
 * @flow
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import {withCatalystContext} from '../context';
import Layout from '../layout';
import formatUserDate from '../utility/formatUserDate';
import {l} from '../static/scripts/common/i18n';

import ReleaseList from './components/ReleaseList';
import FilterLink from './FilterLink';
import type {ReportDataT, ReportReleaseT} from './types';

const ReleasesInCAAWithCoverArtRelationships = ({
  $c,
  canBeFiltered,
  filtered,
  generated,
  items,
  pager,
}: ReportDataT<ReportReleaseT>) => (
  <Layout fullWidth title={l('Releases in the Cover Art Archive that still have cover art relationships')}>
    <h1>{l('Releases in the Cover Art Archive that still have cover art relationships')}</h1>

    <ul>
      <li>{l('This report shows releases which have artwork in the Cover Art \
            Archive, but still have a cover art relationship (pointing to a URL).')}
      </li>
      <li>{l('Total releases found: {count}', {__react: true, count: pager.total_entries})}</li>
      <li>{l('Generated on {date}', {__react: true, date: formatUserDate($c.user, generated)})}</li>

      {canBeFiltered ? <FilterLink filtered={filtered} /> : null}
    </ul>

    <ReleaseList items={items} pager={pager} />

  </Layout>
);

export default withCatalystContext(ReleasesInCAAWithCoverArtRelationships);
