/*
 * @flow strict-local
 * Copyright (C) 2019 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import {CatalystContext} from '../../context';
import Table from '../Table';
import {
  defineCheckboxColumn,
  defineCollectionCommentsColumn,
  defineNameColumn,
  defineTypeColumn,
  defineTextColumn,
  defineEntityColumn,
  defineBeginDateColumn,
  defineEndDateColumn,
  defineRatingsColumn,
  removeFromMergeColumn,
} from '../../utility/tableColumns';

type Props = {
  ...CollectionCommentsRoleT,
  +checkboxes?: string,
  +mergeForm?: MergeFormT,
  +order?: string,
  +places: $ReadOnlyArray<PlaceT>,
  +showCollectionComments?: boolean,
  +showRatings?: boolean,
  +sortable?: boolean,
};

const PlaceList = ({
  checkboxes,
  collectionComments,
  mergeForm,
  order,
  places,
  showCollectionComments = false,
  showRatings = false,
  sortable,
}: Props): React.Element<typeof Table> => {
  const $c = React.useContext(CatalystContext);

  const columns = React.useMemo(
    () => {
      const checkboxColumn = $c.user && (nonEmpty(checkboxes) || mergeForm)
        ? defineCheckboxColumn({mergeForm: mergeForm, name: checkboxes})
        : null;
      const nameColumn = defineNameColumn<PlaceT>({
        descriptive: false, // since area has its own column
        order: order,
        sortable: sortable,
        title: l('Place'),
      });
      const typeColumn = defineTypeColumn({
        order: order,
        sortable: sortable,
        typeContext: 'place_type',
      });
      const addressColumn = defineTextColumn<PlaceT>({
        columnName: 'address',
        getText: entity => entity.address,
        order: order,
        sortable: sortable,
        title: l('Address'),
      });
      const areaColumn = defineEntityColumn<PlaceT>({
        columnName: 'area',
        getEntity: entity => entity.area,
        title: l('Area'),
      });
      const beginDateColumn = defineBeginDateColumn({});
      const endDateColumn = defineEndDateColumn({});
      const ratingsColumn = defineRatingsColumn<PlaceT>({
        getEntity: entity => entity,
      });
      const collectionCommentsColumn = showCollectionComments
        ? defineCollectionCommentsColumn({
          collectionComments: collectionComments,
        })
        : null;

      return [
        ...(checkboxColumn ? [checkboxColumn] : []),
        nameColumn,
        typeColumn,
        addressColumn,
        areaColumn,
        beginDateColumn,
        endDateColumn,
        ...(showRatings ? [ratingsColumn] : []),
        ...(collectionCommentsColumn ? [collectionCommentsColumn] : []),
        ...(mergeForm && places.length > 2 ? [removeFromMergeColumn] : []),
      ];
    },
    [
      $c.user,
      checkboxes,
      mergeForm,
      order,
      places,
      showRatings,
      collectionComments,
      showCollectionComments,
      sortable,
    ],
  );

  return <Table columns={columns} data={places} />;
};

export default PlaceList;
