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
import SeriesSidebar from '../layout/components/sidebar/SeriesSidebar';

import SeriesHeader from './SeriesHeader';

type Props = {|
  +$c: CatalystContextT,
  +canonicalURL: string,
  +children: ReactNode,
  +fullWidth?: boolean,
  +page: string,
  +series: SeriesT,
  +title?: string,
|};

const SeriesLayout = ({
  $c,
  canonicalURL,
  children,
  fullWidth,
  page,
  series,
  title,
}: Props) => (
  <Layout canonical_url={canonicalURL} title={title ? series.name + ' - ' + title : series.name}>
    <div id="content">
      <SeriesHeader page={page} series={series} />
      {children}
    </div>
    {fullWidth ? null : <SeriesSidebar series={series} />}
  </Layout>
);


export default withCatalystContext(SeriesLayout);
