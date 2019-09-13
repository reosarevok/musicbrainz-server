/*
 * @flow
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import React from 'react';

import EntityMerge from '../components/EntityMerge';

type Props = {|
  +form: MergeForm,
  +isrcsDiffer?: boolean,
  +toMerge: $ReadOnlyArray<RecordingT>,
|};

const RecordingMerge = ({form, isrcsDiffer, toMerge}: Props) => (
  <EntityMerge
    form={form}
    title={l('Merge recordings')}
    toMerge={toMerge}
  >
    <p>
      {l(`You are about to merge the following recordings into a single
          recording. Please select the recording which you would like other
          recordings to be merged into:`)}
    </p>
    {isrcsDiffer ? (
      <div className="warning warning-isrcs-differ">
        <p>
          {exp.l(`<strong>Warning:</strong> Some of the recordings you're
                  merging have different ISRCs. Please make sure they are
                  indeed the same recordings and you wish to continue with
                  the merge.`)}
        </p>
      </div>
    ) : null}
  </EntityMerge>
);

export default RecordingMerge;
