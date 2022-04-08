/*
 * @flow strict
 * Copyright (C) 2019 Anirudh Jain
 * Copyright (C) 2014 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import {CatalystContext} from '../../context.mjs';
import Layout from '../../layout/index.js';
import {compare} from '../../static/scripts/common/i18n.js';
import expand2react from '../../static/scripts/common/i18n/expand2react.js';
import {isRelationshipEditor}
  from '../../static/scripts/common/utility/privileges.js';
import yesNo from '../../static/scripts/common/utility/yesNo.js';
import loopParity from '../../utility/loopParity.js';

import {type AttributeT} from './types.js';

type Props = {
  +attributes: Array<AttributeT>,
  +model: string,
};

const extraHeaders = (model: string) => {
  switch (model) {
    case 'MediumFormat': {
      return (
        <>
          <th>{l('Year')}</th>
          <th>{l('Disc IDs allowed')}</th>
        </>
      );
    }
    case 'SeriesType':
    case 'CollectionType': {
      return <th>{l('Entity type')}</th>;
    }
    case 'WorkAttributeType': {
      return <th>{l('Free text')}</th>;
    }
    default: return null;
  }
};

const extraColumns = (attribute: AttributeT) => {
  switch (attribute.entityType) {
    case 'medium_format': {
      return (
        <>
          <td>{attribute.year}</td>
          <td>{yesNo(attribute.has_discids)}</td>
        </>
      );
    }
    case 'series_type':
    case 'collection_type': {
      return <td>{attribute.item_entity_type}</td>;
    }
    case 'work_attribute_type': {
      return <td>{yesNo(attribute.free_text)}</td>;
    }
    default: return null;
  }
};

const Attribute = ({
  attributes,
  model,
}: Props): React$Element<typeof Layout> => {
  const $c = React.useContext(CatalystContext);
  const showEditSections = isRelationshipEditor($c.user);

  return (
    <Layout fullWidth title={model}>
      <h1>
        <a href="/admin/attributes">{l('Attributes')}</a>
        {' / ' + model}
      </h1>

      <table className="tbl">
        <thead>
          <tr>
            <th>{l('ID')}</th>
            <th>{l('Name')}</th>
            <th>{l('Description')}</th>
            <th>{l('MBID')}</th>
            {showEditSections ? (
              <>
                <th>{l('Child order')}</th>
                <th>{l('Parent ID')}</th>
              </>
            ) : null}
            {extraHeaders(model)}
            {showEditSections ? (
              <th>{l('Actions')}</th>
            ) : null}
          </tr>
        </thead>
        <tbody>
          {attributes ? attributes
            .sort((a, b) => compare(a.name, b.name))
            .map((attribute, index) => (
              <tr className={loopParity(index)} key={attribute.id}>
                <td>{attribute.id}</td>
                <td>{attribute.name}</td>
                <td>{expand2react(attribute.description)}</td>
                <td>{attribute.gid}</td>
                {showEditSections ? (
                  <>
                    <td>{attribute.child_order}</td>
                    <td>{attribute.parent_id}</td>
                  </>
                ) : null}
                {extraColumns(attribute)}
                {showEditSections ? (
                  <td>
                    <a
                      href={`/admin/attributes/${model}/edit/${attribute.id}`}
                    >
                      {l('Edit')}
                    </a>
                    {' | '}
                    <a
                      href={
                        `/admin/attributes/${model}/delete/${attribute.id}`
                      }
                    >
                      {l('Remove')}
                    </a>
                  </td>
                ) : null}
              </tr>
            )) : null}
        </tbody>
      </table>

      {showEditSections ? (
        <p>
          <span className="buttons">
            <a href={`/admin/attributes/${model}/create`}>
              {l('Add new attribute')}
            </a>
          </span>
        </p>
      ) : null}
    </Layout>
  );
};

export default Attribute;
