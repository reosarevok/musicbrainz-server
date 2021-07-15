/*
 * @flow strict-local
 * Copyright (C) 2021 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import Layout from '../layout';
import expand2react from '../static/scripts/common/i18n/expand2react';

type PropsT = {
  +events: Array<StatisticsEventT>,
};

const MusicBrainzHistory = ({
  events,
}: PropsT): React.Element<typeof Layout> => {
  const sortedEvents = events.reverse();

  return (
    <Layout fullWidth title={l('History')}>
      <h1>{l('Our Glorious History')}</h1>
      {sortedEvents ? sortedEvents
        .map((event) => {
          const title = exp.l(
            '{date} - {title}',
            {date: event.date, title: event.title},
          );
          return (
            <div key={event.date}>
              <h2>
                {event.link ? (
                  <a href={event.link}>{title}</a>
                ) : title}
              </h2>
              <p>{expand2react(event.description)}</p>
              <hr />
            </div>
          );
        }) : (
        l('It seems we have no history to show at all!')
      )}
    </Layout>
  );
};

export default MusicBrainzHistory;
