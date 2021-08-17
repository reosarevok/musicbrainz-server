/*
 * Copyright (C) 2005 Stefan Kestenholz (keschte)
 * Copyright (C) 2010 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import getCookie from '../../../common/utility/getCookie';
import * as flags from '../../flags';

import GuessCaseAreaHandler from './Handler/Area';
import GuessCaseArtistHandler from './Handler/Artist';
import GuessCaseLabelHandler from './Handler/Label';
import GuessCasePlaceHandler from './Handler/Place';
import GuessCaseReleaseHandler from './Handler/Release';
import GuessCaseTrackHandler from './Handler/Track';
import GuessCaseWorkHandler from './Handler/Work';

// Main class of the GC functionality
class GuessCase {
  constructor() {
    this.modeName = getCookie('guesscase_mode') || 'English';

    // Config
    this.CFG_KEEP_UPPERCASED =
      getCookie('guesscase_keepuppercase') !== 'false';

    // holder for the regular expressions
    this.regexes = {
      // define commonly used RE's
      SERIES_NUMBER: /^(\d+|[ivx]+)$/i,
      SPACES_DOTS: /\s|\./i,
    };

    this.area = {
      guess: this.guess('area', 'process'),
      sortname: this.guess('area', 'guessSortName'),
    };

    this.artist = {
      guess: this.guess('artist', 'process'),
      sortname: this.guess('artist', 'guessSortName'),
    };

    this.event = {
      guess: this.guess('event', 'process'),
      sortname: this.guess('event', 'guessSortName'),
    };

    this.instrument = {
      guess: this.lowercaseInstrumentName,
      sortname: this.lowercaseInstrumentName,
    };

    this.label = {
      guess: this.guess('label', 'process'),
      sortname: this.guess('label', 'guessSortName'),
    };

    this.place = {
      guess: this.guess('place', 'process'),
      sortname: this.guess('place', 'guessSortName'),
    };

    this.release = {
      guess: this.guess('release', 'process'),
      sortname: this.guess('release', 'guessSortName'),
    };

    this.release_group = {
      guess: this.guess('release_group', 'process'),
      sortname: this.guess('release_group', 'guessSortName'),
    };

    this.track = {
      guess: this.guess('track', 'process'),
      sortname: this.guess('track', 'guessSortName'),
    };

    this.recording = {
      guess: this.guess('recording', 'process'),
      sortname: this.guess('recording', 'guessSortName'),
    };

    this.series = {
      guess: this.guess('series', 'process'),
      sortname: this.guess('series', 'guessSortName'),
    };

    this.work = {
      guess: this.guess('work', 'process'),
      sortname: this.guess('work', 'guessSortName'),
    };
  }

  // Member functions

  guess(handlerName, method) {
    let handler;
    const handlerPicker = {
      area: GuessCaseAreaHandler,
      artist: GuessCaseArtistHandler,
      event: GuessCaseWorkHandler,
      label: GuessCaseLabelHandler,
      place: GuessCasePlaceHandler,
      recording: GuessCaseTrackHandler,
      release: GuessCaseReleaseHandler,
      release_group: GuessCaseReleaseHandler,
      series: GuessCaseWorkHandler,
      track: GuessCaseTrackHandler,
      work: GuessCaseWorkHandler,
    };
    /*
     * Guesses the name (e.g. capitalization) or sort name (for aliases)
     * of a given entity.
     * @param {string} is The unprocessed input string.
     * @return {string} The processed string.
     */
    return function (inputString) {
      // Initialise flags for another run.
      flags.init();

      handler = handler || new handlerPicker[handlerName]();

      /*
       * We need to query the handler if the input string is
       * a special case, fetch the correct format, if the
       * returned case is indeed a special case.
       */
      const num = handler.checkSpecialCase(inputString);
      const output = handler.isSpecialCase(num)
        ? handler.getSpecialCaseFormatted(inputString, num)
        // if it was not a special case, start guessing
        : handler[method].apply(handler, arguments);

      return output;
    };
  }

  // For instruments, all we need to do is lowercase the string
  lowercaseInstrumentName(name) {
    return name.toLowerCase();
  }
}

export default new GuessCase();
