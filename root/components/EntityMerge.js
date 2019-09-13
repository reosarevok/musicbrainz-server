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
import sortBy from 'lodash/sortBy';

import EnterEdit from '../components/EnterEdit';
import EnterEditNote from '../components/EnterEditNote';
import FieldErrors from '../components/FieldErrors';
import RecordingList from '../components/list/RecordingList';
import {withCatalystContext} from '../context';
import Layout from '../layout';

type Props = {|
  +$c: CatalystContextT,
  +children: ReactNode,
  +form: MergeForm,
  +title: string,
  +toMerge: $ReadOnlyArray<CoreEntityTypeT>,
|};

const EntityMerge = ({$c, children, form, title, toMerge}: Props) => {
  function renderCheckboxElement(recording, index) {
    return (
      <>
        <input
          name={'merge.merging.' + index}
          type="hidden"
          value={recording.id}
        />
        <input
          checked={recording.id === form.field.target.value}
          name="merge.target"
          type="radio"
          value={recording.id}
        />
      </>
    );
  }

  // To ensure same order on reload
  const orderedToMerge = sortBy(toMerge, 'name');

  return (
    <Layout fullWidth title={title}>
      <div id="content">
        <h1>{title}</h1>
        {children}
        <form action={$c.req.uri} method="post">
          <RecordingList
            recordings={orderedToMerge}
            renderCheckboxElement={renderCheckboxElement}
          />
          <FieldErrors field={form.field.target} />

          <EnterEditNote field={form.field.edit_note} />

          <EnterEdit form={form}>
            <button
              className="negative"
              name="submit"
              type="submit"
              value="cancel"
            >
              {l('Cancel')}
            </button>
          </EnterEdit>
        </form>
      </div>
    </Layout>
  );
};
export default withCatalystContext(EntityMerge);
