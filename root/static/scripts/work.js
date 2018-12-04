/*
 * @flow
 * Copyright (C) 2015-2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import $ from 'jquery';
import _ from 'lodash';
import ko from 'knockout';
import React from 'react';
import ReactDOM from 'react-dom';
import {createStore} from 'redux';

import FormRowSelectList from '../../components/FormRowSelectList';
import createField from '../../utility/createField';
import subfieldErrors from '../../utility/subfieldErrors';

import {l} from './common/i18n';
import {lp_attributes} from './common/i18n/attributes';
import getScriptArgs from './common/utility/getScriptArgs';
import {Lens, prop, index, set, compose3} from './common/utility/lens';
import forms from './edit/forms';
import bubble from './edit/MB/Control/Bubble';
import guessCase from './guess-case/MB/Control/GuessCase';

const scriptArgs = getScriptArgs();

type LanguageField = FieldT<number>;

type LanguageFields = $ReadOnlyArray<LanguageField>;

type WorkAttributeField = CompoundFieldT<{|
  +type_id: FieldT<number | null>,
  +value: FieldT<number | string | null>,
|}>;

type WorkForm = FormT<{|
  +attributes: RepeatableFieldT<WorkAttributeField>,
  +languages: RepeatableFieldT<LanguageField>,
|}>;

/*
 * Flow does not support assigning types within destructuring assignments:
 * https://github.com/facebook/flow/issues/235
 */
const form: WorkForm = scriptArgs.form;
const workAttributeTypeTree: WorkAttributeTypeTreeRootT =
  scriptArgs.workAttributeTypeTree;
const workAttributeValueTree: WorkAttributeTypeAllowedValueTreeRootT =
  scriptArgs.workAttributeValueTree;
const workLanguageOptions: MaybeGroupedOptionsT = {
  grouped: true,
  options: scriptArgs.workLanguageOptions,
};

const languagesField: Lens<WorkForm, LanguageFields> =
  compose3(prop('field'), prop('languages'), prop('field'));

const store = createStore(function (state: WorkForm = form, action) {
  switch (action.type) {
    case 'ADD_LANGUAGE':
      state = addLanguageToState(state);
      break;

    case 'EDIT_LANGUAGE':
      state = set(
        (compose3(languagesField, index(action.index), prop('value')):
          Lens<WorkForm, number>),
        action.languageId,
        state,
      );
      break;

    case 'REMOVE_LANGUAGE':
      state = removeLanguageFromState(state, action.index);
      break;
  }

  if (!state.field.languages.field.length) {
    state = addLanguageToState(state);
  }

  return state;
});

function pushField<F, R: RepeatableFieldT<F>>(
  form: WorkForm,
  repeatable: R,
  value: mixed,
) {
  return createField(
    form,
    repeatable,
    String(repeatable.field.length),
    value,
  );
}

function addLanguageToState(form: WorkForm): WorkForm {
  const languages = form.field.languages.field.slice(0);
  const newForm = set(languagesField, languages, form);
  languages.push(
    pushField(
      newForm,
      newForm.field.languages,
      null,
    )
  );
  return newForm;
}

function removeLanguageFromState(form: WorkForm, i: number): WorkForm {
  const languages = form.field.languages.field.slice(0);
  languages.splice(i, 1);
  return set(languagesField, languages, form);
}

class WorkAttribute {
  allowedValues: () => OptionListT;

  allowedValuesByTypeID: {[number]: OptionListT};

  attributeValue: (?string) => string;

  errors: (?$ReadOnlyArray<string>) => $ReadOnlyArray<string>;

  parent: ViewModel;

  typeHasFocus: (?boolean) => boolean;

  typeID: (?number) => number;

  constructor(
    data: WorkAttributeField,
    parent: ViewModel,
  ) {
    this.attributeValue = ko.observable(data.field.value.value);
    this.errors = ko.observableArray(subfieldErrors(data));
    this.parent = parent;
    this.typeHasFocus = ko.observable(false);
    this.typeID = ko.observable(data.field.type_id.value);

    this.allowedValues = ko.computed(() => {
      const typeID = this.typeID();

      if (this.allowsFreeText()) {
        return [];
      }
      return this.parent.allowedValuesByTypeID[typeID];
    });

    this.typeID.subscribe(newTypeID => {
      // != is used intentionally for type coercion.
      if (this.typeID() != newTypeID) { // eslint-disable-line eqeqeq
        this.attributeValue('');
        this.resetErrors();
      }
    });

    this.attributeValue.subscribe(() => this.resetErrors());
  }

  allowsFreeText() {
    return !this.typeID() ||
      this.parent.attributeTypesByID[this.typeID()].freeText;
  }

  isGroupingType() {
    return !this.allowsFreeText() && this.allowedValues().length === 0;
  }

  remove() {
    this.parent.attributes.remove(this);
  }

  resetErrors() {
    this.errors([]);
  }
}

class ViewModel {
  attributeTypes: OptionListT;

  attributeTypesByID: {[number]: WorkAttributeTypeTreeT};

  allowedValuesByTypeID: {[number]: OptionListT};

  attributes: (?$ReadOnlyArray<WorkAttribute>) =>
    $ReadOnlyArray<WorkAttribute>;

  constructor(
    attributeTypes: WorkAttributeTypeTreeRootT,
    allowedValues: WorkAttributeTypeAllowedValueTreeRootT,
    attributes: $ReadOnlyArray<WorkAttributeField>,
  ) {
    this.attributeTypes = forms.buildOptionsTree(
      attributeTypes,
      x => lp_attributes(x.name, 'work_attribute_type'),
      'id',
    );

    this.attributeTypesByID = attributeTypes.children.reduce(byID, {});

    this.allowedValuesByTypeID = _(allowedValues.children)
      .groupBy(x => x.workAttributeTypeID)
      .mapValues(function (children) {
        return forms.buildOptionsTree(
          {children},
          x => lp_attributes(x.value, 'work_attribute_type_allowed_value'),
          'id',
        );
      })
      .value();

    if (_.isEmpty(attributes)) {
      attributes = [
        pushField(form, form.field.attributes, {
          type_id: null,
          value: null,
        }),
      ];
    }

    this.attributes = ko.observableArray(
      _.map(attributes, data => new WorkAttribute(data, this)),
    );
  }

  newAttribute() {
    const attr = new WorkAttribute(pushField(form, form.field.attributes, {
      type_id: null,
      value: null,
    }), this);
    attr.typeHasFocus(true);
    this.attributes.push(attr);
  }
}

function byID(result, parent) {
  result[parent.id] = parent;
  if (parent.children) {
    parent.children.reduce(byID, result);
  }
  return result;
}

ko.applyBindings(
  new ViewModel(
    workAttributeTypeTree,
    workAttributeValueTree,
    form.field.attributes.field,
  ),
  $('#work-attributes')[0],
);

guessCase.initialize_guess_case('work', 'id-edit-work');

function addLanguage() {
  store.dispatch({type: 'ADD_LANGUAGE'});
}

function editLanguage(i, languageId) {
  store.dispatch({
    index: i,
    languageId: languageId,
    type: 'EDIT_LANGUAGE',
  });
}

function removeLanguage(i) {
  store.dispatch({
    index: i,
    type: 'REMOVE_LANGUAGE',
  });
}

function renderWorkLanguages() {
  const workLanguagesNode = document.getElementById('work-languages-editor');
  if (!workLanguagesNode) {
    throw new Error('Mount point #work-languages-editor does not exist');
  }
  const form: WorkForm = store.getState();
  ReactDOM.render(
    <FormRowSelectList
      addId="add-language"
      addLabel={l('Add Language')}
      getSelectField={_.identity}
      label={l('Lyrics Languages')}
      onAdd={addLanguage}
      onEdit={editLanguage}
      onRemove={removeLanguage}
      options={workLanguageOptions}
      removeClassName="remove-language"
      removeLabel={l('Remove Language')}
      repeatable={form.field.languages}
    />,
    workLanguagesNode,
  );
}

store.subscribe(renderWorkLanguages);
renderWorkLanguages();

bubble.initializeBubble('#iswcs-bubble', 'input[name=edit-work\\.iswcs\\.0]');

const typeIdField = 'select[name=edit-work\\.type_id]';
bubble.initializeBubble('#type-bubble', typeIdField);
$(typeIdField).on('change', function () {
  if (this.value.match(/\S/g)) {
    $('#type-bubble-default').hide();
    $('.type-bubble-description').hide();
    $(`#type-bubble-description-${this.value}`).show();
  } else {
    $('.type-bubble-description').hide();
    $('#type-bubble-default').show();
  }
});
