/*
 * @flow strict
 * Copyright (C) 2021 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

export type StatisticsEventFormT = FormT<{
  +date: FieldT<string>,
  +description: FieldT<string>,
  +link: FieldT<string>,
  +title: FieldT<string>,
}>;

export type StatisticsEventT = {
  +date: string,
  +description: string,
  +link: string,
  +title: string,
};
