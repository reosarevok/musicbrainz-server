/*
 * @flow
 * Copyright (C) 2018 Shamroy Pellew
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import React from 'react';

import manifest from '../static/manifest';
import {l_statistics as l} from '../static/scripts/common/i18n/statistics';
import EntityLink from '../static/scripts/common/components/EntityLink';
import {withCatalystContext} from '../context';
import loopParity from '../utility/loopParity';

import {formatCount} from './utilities';
import StatisticsLayout from './StatisticsLayout';

type CountriesStatsT = {|
  +$c: CatalystContextT,
  +countryStats: $ReadOnlyArray<CountryStatT>,
  +dateCollected: string,
|};

type CountryStatT = {|
  +artist_count: number,
  +entity: AreaT,
  +label_count: number,
  +release_count: number,
|};

const Countries = ({$c, countryStats, dateCollected}: CountriesStatsT) => (
  <StatisticsLayout fullWidth page="countries" title={l('Countries')}>
    {manifest.css('statistics')}
    <p>
      {l('Last updated: {date}',
        {date: dateCollected})}
    </p>
    <table className="tbl">
      <thead>
        <tr>
          <th className="pos">{l('Rank')}</th>
          <th>
            {l('Country')}
            <div className="arrow" />
          </th>
          <th>
            {l('Artists')}
            <div className="arrow" />
          </th>
          <th>
            {l('Releases')}
            <div className="arrow" />
          </th>
          <th>
            {l('Labels')}
            <div className="arrow" />
          </th>
          <th>
            {l('Total')}
            <div className="arrow" />
          </th>
        </tr>
      </thead>
      <tbody>
        {countryStats.map((country, index) => (
          <tr className={loopParity(index)} key={country.entity.gid}>
            <td className="t">{index + 1}</td>
            <td>
              {country.entity.country_code
                ? <EntityLink entity={country.entity} />
                : l('Unknown Country')}
            </td>
            <td className="t">{country.entity.country_code ? <EntityLink content={formatCount($c, country.artist_count)} entity={country.entity} subPath="artists" /> : formatCount($c, country.artist_count)}</td>
            <td className="t">{country.entity.country_code ? <EntityLink content={formatCount($c, country.release_count)} entity={country.entity} subPath="releases" /> : formatCount($c, country.release_count)}</td>
            <td className="t">{country.entity.country_code ? <EntityLink content={formatCount($c, country.label_count)} entity={country.entity} subPath="labels" /> : formatCount($c, country.label_count)}</td>
            <td className="t">{formatCount($c, country.artist_count + country.release_count + country.label_count)}</td>
          </tr>
        ))}
      </tbody>
    </table>
    {manifest.js('statistics')}
  </StatisticsLayout>
);

export default withCatalystContext(Countries);
