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

import WorkRelationshipList from './components/WorkRelationshipList';
import FilterLink from './FilterLink';
import type {ReportDataT, ReportWorkRelationshipT} from './types';

const DeprecatedRelationshipWorks = ({
  $c,
  canBeFiltered,
  filtered,
  generated,
  items,
  pager,
}: ReportDataT<ReportWorkRelationshipT>) => (
  <Layout fullWidth title={l('Works with deprecated relationships')}>
    <h1>{l('Works with deprecated relationships')}</h1>

    <ul>
      <li>{l('This report lists works which have relationships using deprecated and grouping-only relationship types')}
      </li>
      <li>{l('Total works found: {count}', {__react: true, count: pager.total_entries})}</li>
      <li>{l('Generated on {date}', {__react: true, date: formatUserDate($c.user, generated)})}</li>

      {canBeFiltered ? <FilterLink filtered={filtered} /> : null}
    </ul>

    <WorkRelationshipList items={items} pager={pager} />

  </Layout>
);

export default withCatalystContext(DeprecatedRelationshipWorks);
