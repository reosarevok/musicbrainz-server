/*
 * Copyright (C) 2015-2017 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

/* eslint-disable import/no-commonjs */

const Sentry = require('@sentry/node');
const React = require('react');
const ReactDOMServer = require('react-dom/server');

const {CatalystContext, SanitizedCatalystContext} = require('../context');
const getRequestCookie = require('../utility/getRequestCookie');
const sanitizedContext = require('../utility/sanitizedContext');

const components = require('./components');
const gettext = require('./gettext');

function badRequest(err) {
  return Buffer.from(JSON.stringify({
    body: err.stack,
    content_type: 'text/plain',
    status: 400,
  }));
}

function getExport(object) {
  return object.default || object;
}

const jsExt = /\.js$/;

function getResponse(requestBody, context) {
  let status = null;
  let response;

  const user = context.user;
  if (user) {
    Sentry.setUser({id: user.id, username: user.name});
  }

  /*
   * Set the current translations to be used for this request based on the
   * given 'lang' cookie.
   */
  const bcp47Locale = getRequestCookie(context.req, 'lang') || 'en';
  gettext.setLocale(bcp47Locale.replace('-', '_'));

  const componentPath = String(requestBody.component).replace(jsExt, '');
  const componentModule = components[componentPath];

  if (!componentModule) {
    console.warn(
      'warning: component ' + JSON.stringify(componentPath) +
      ' is missing from root/server/components.js or invalid',
    );
  }

  let Page = componentModule ? getExport(componentModule) : undefined;
  if (Page === undefined) {
    try {
      Page = getExport(components['main/error/404']);
      status = 404;
    } catch (err) {
      Sentry.captureException(err);
      return badRequest(err);
    }
  }

  try {
    let props = requestBody.props;
    if (props == null) {
      props = {};
    }
    props.$c = context;

    response = ReactDOMServer.renderToString(
      React.createElement(
        CatalystContext.Provider,
        {value: context},
        React.createElement(
          SanitizedCatalystContext.Provider,
          {value: sanitizedContext(context)},
          React.createElement(Page, props),
        ),
      ),
    );
  } catch (err) {
    Sentry.captureException(err);
    return badRequest(err);
  }

  return Buffer.from(JSON.stringify({
    body: response,
    content_type: 'text/html',
    status,
  }));
}

exports.badRequest = badRequest;
exports.getResponse = getResponse;
