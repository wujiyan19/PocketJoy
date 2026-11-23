/* Artwork behind the native game pieces. All coordinates live in a 360 × 460 panel. */
const ceramic = {
  blockfit: ['#E9EAF4', '#CBD5E8', '#7E91AE', '#2B344D', '#202941', '#536986'],
  tilestack: ['#ECECF4', '#DADDEC', '#9A9DB2', '#383549', '#2B2B40', '#655F7D'],
  bubbleshooter: ['#E7EFF9', '#CEE0F0', '#86A9C4', '#2A3C55', '#1D2C43', '#536C90'],
  fruitmerge: ['#FFF4DF', '#EBDAB9', '#B99C6F', '#453B34', '#332C28', '#85664B'],
  watersort: ['#E9F2F3', '#CEDFE7', '#84A5B7', '#2B3D4D', '#202F3E', '#547687'],
  arrowclear: ['#E7EEF7', '#CCD9EC', '#849BB7', '#314057', '#243045', '#526784'],
  linktiles: ['#F3EDF3', '#DDD3E7', '#A090B0', '#383248', '#2B263B', '#6D5B82'],
  groupclear: ['#E9F0EB', '#CDDBD4', '#87A697', '#30443F', '#253631', '#56746B'],
  untangle: ['#F6F0E6', '#E5DBCA', '#B29D81', '#3C3B3B', '#2F3033', '#74675A'],
  picturepuzzle: ['#F5EEE1', '#E4D9C8', '#B2A084', '#423C37', '#322D2A', '#776450'],
};

const felt = {
  solitaire: ['#CDE4DB', '#A8CDC0', '#608F80', '#2B4E45', '#203C37', '#587E71'],
  spider: ['#DFEAE7', '#C5DCD7', '#9ABAB2', '#304D4B', '#253D3E', '#597D76'],
  freecell: ['#DCE9D9', '#B9D4C0', '#72967C', '#334C40', '#23392F', '#5E7E69'],
  mahjongsolitaire: ['#DBE6D5', '#B4CBB0', '#7A9574', '#394D40', '#293A30', '#648465'],
};

function boardBackground(id, dark) {
  const rect = (x, y, w, h, r, fill, opacity = 1) =>
    `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="${fill}" opacity="${opacity}"/>`;
  const ellipse = (x, y, rx, ry, fill, opacity = 1) =>
    `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="${fill}" opacity="${opacity}"/>`;
  const path = (d, fill, opacity = 1) => `<path d="${d}" fill="${fill}" opacity="${opacity}"/>`;
  const stroke = (d, color, width = 1, opacity = 1) =>
    `<path d="${d}" fill="none" stroke="${color}" stroke-width="${width}" stroke-linecap="round" opacity="${opacity}"/>`;
  const gradient = (name, start, end, diagonal = false) =>
    `<linearGradient id="${name}" x1="0%" y1="0%" x2="${diagonal ? 100 : 0}%" y2="100%"><stop stop-color="${start}"/><stop offset="1" stop-color="${end}"/></linearGradient>`;
  const pick = colors => dark ? colors.slice(3) : colors.slice(0, 3);
  const panel = (colors, details) => {
    const [light, shade, rim] = pick(colors);
    const body = rect(0, 0, 360, 460, 17, rim) + rect(2, 2, 356, 453, 15, 'url(#finish)') +
      stroke('M17 7H340M7 23V426', '#FFFFFF', 1.5, dark ? .15 : .53) +
      stroke('M353 40V438Q353 450 340 450H31', '#172337', 2, dark ? .38 : .16);
    return { defs: gradient('finish', light, shade, true), body: body + details(rim) };
  };
  const cornerInlays = (rim, inset = 12) => [
    [inset, 13, 0], [360 - inset, 13, 90], [360 - inset, 447, 180], [inset, 447, 270],
  ].map(([x, y, turn]) => `<g transform="translate(${x} ${y}) rotate(${turn})">${stroke('M0 20V8Q0 0 8 0H20', rim, 1.6, .45)}</g>`).join('');

  if (ceramic[id]) {
    if (['blockfit', 'tilestack', 'arrowclear'].includes(id)) {
      const [light, shade, rim] = pick(ceramic[id]);
      return {
        defs: gradient('tray', light, shade, true),
        body: rect(0, 0, 360, 460, 14, 'url(#tray)') +
          stroke('M1 20V13Q1 1 13 1H347Q359 1 359 13V447Q359 459 347 459H13Q1 459 1 447Z', rim, 1.3, .22),
      };
    }
    return panel(ceramic[id], rim => {
      if (id === 'watersort') {
        return cornerInlays(rim, 10) + stroke('M46 26H114M246 26H314M75 440H285', rim, 1.4, .36);
      }
      if (id === 'fruitmerge') {
        return path('M0 329Q19 367 91 422Q124 450 171 460H0Z M360 301Q333 356 287 409Q256 438 217 460H360Z', rim, .13) +
          stroke('M11 391Q37 422 81 439M347 367Q330 402 299 430', '#FFFFFF', 2, .32);
      }
      if (id === 'bubbleshooter') {
        return stroke('M7 311Q12 362 42 384M353 311Q348 362 318 384M16 427Q54 442 97 444M344 427Q306 442 263 444', rim, 3, .31);
      }
      if (id === 'untangle') {
        return cornerInlays(rim) + stroke('M14 86V288M346 174V372', rim, 2, .19);
      }
      return cornerInlays(rim) + stroke('M54 13H123M237 447H306', rim, 1.2, .23);
    });
  }

  if (id === 'mahjongsolitaire') {
    const [light, shade] = pick(felt[id]);
    return { defs: gradient('felt', light, shade, true), body: rect(0, 0, 360, 460, 13, 'url(#felt)') };
  }
  if (felt[id]) {
    if (id === 'spider' || id === 'freecell') {
      const [light, shade, rim] = pick(felt[id]);
      return { defs: gradient('felt', light, shade, true),
        body: rect(0, 0, 360, 460, 17, rim) + rect(1, 1, 358, 458, 16, 'url(#felt)') };
    }
    return panel(felt[id], rim => stroke('M13 21Q13 13 21 13H338Q347 13 347 21V437Q347 443 339 443H21Q13 443 13 435Z', rim, 1.8, .55) +
      Array.from({length: 36}, (_, i) => stroke(`M${28 + i * 8.7} 10v6m0 428v5`, rim, .8, .46)).join('') +
      stroke('M22 40V414M338 40V414', '#FFFFFF', 1, dark ? .10 : .27));
  }

  if (['rhythm', 'beatjump', 'melody'].includes(id)) {
    const stage = id === 'melody'
      ? ['#EEE8F1', '#D6D8EB', '#9D8EAC', '#37334B', '#292B40', '#655780']
      : ['#EDE9F5', '#DFD9EC', '#9B93B1', '#1F2130', '#171926', '#52536B'];
    const backdrop = panel(stage, rim => {
      const beam = dark ? '#C8C4DA' : '#FBF3EA';
      const curtain = dark ? '#373650' : '#BDB1CA';
      const topTrim = id === 'beatjump' ? 'M17 16H62M298 16H344' : 'M17 16H344';
      return ellipse(35, 93, 93, 179, 'url(#spotlight)') +
        ellipse(337, 99, 64, 147, 'url(#spotlight)', .63) +
        path('M2 8H27Q23 31 14 47L3 53Z M358 8H333Q337 31 346 47L357 53Z', curtain, .72) +
        stroke('M10 14Q10 36 6 46M17 14Q15 36 10 45M350 14Q350 36 354 46M343 14Q345 36 350 45', rim, 1.2, .37) +
        stroke(topTrim + 'M18 444H342', rim, 2, .52) +
        [29, 42, 55, 305, 318, 331].map(x => ellipse(x, 25, 2.1, 2.1, beam, .64)).join('');
    });
    const glow = dark ? '#C4BFD9' : '#FFF2DF';
    backdrop.defs += `<radialGradient id="spotlight"><stop stop-color="${glow}" stop-opacity="${dark ? .12 : .62}"/><stop offset="1" stop-color="${glow}" stop-opacity="0"/></radialGradient>`;
    return backdrop;
  }

  if (['runner', 'buscolor', 'tanks', 'drift'].includes(id)) {
    if (id === 'runner') {
      const asphalt = dark ? ['#34485B', '#253849'] : ['#DCE7EF', '#B6CADB'];
      const shoulder = dark ? ['#4A6476', '#344C60'] : ['#ACC2D4', '#86A4BC'];
      const grain = dark ? '#8193A1' : '#7893AA';
      const shoulders = rect(0, 0, 13, 460, 0, 'url(#shoulder)') + rect(347, 0, 13, 460, 0, 'url(#shoulder)') +
        stroke('M12 0V460M348 0V460', dark ? '#718A9B' : '#7596B0', 1.8, .66) +
        stroke('M4 0V460M356 0V460', '#F7FBFF', 1, dark ? .13 : .42);
      const flecks = Array.from({ length: 92 }, (_, i) => {
        const side = i % 2 ? 0 : 240;
        const radius = i % 5 ? .7 : 1.15;
        return ellipse(side + 19 + i * 47 % 83, 9 + (i * i * 19 + i * 59) % 443, radius * 1.35, radius, grain, dark ? .16 : .23);
      }).join('');
      return { defs: gradient('asphalt', ...asphalt) + gradient('shoulder', ...shoulder),
        body: rect(0, 0, 360, 460, 0, 'url(#asphalt)') + shoulders + flecks };
    }
    const road = id === 'tanks' ? ['#E9E3D5', '#D7CBB7', '#A79778', '#454136', '#34342E', '#716952']
      : ['#E1EBE8', '#CADCD7', '#87ABA2', '#354D4B', '#243938', '#56786D'];
    if (id === 'buscolor') {
      const [light, shade] = pick(road);
      return { defs: gradient('station', light, shade, true), body: rect(0, 0, 360, 460, 14, 'url(#station)') };
    }
    return panel(road, rim => {
      const verge = dark ? '#3F6252' : '#9CBDA7';
      if (id === 'tanks') {
        return path('M0 318L40 329L53 412L103 460H0Z M360 79L324 60L309 23L286 0H360Z', rim, dark ? .25 : .29) +
          stroke('M11 346l23 13 6 31M349 62l-18-12-8-25', '#FFFFFF', 1.5, dark ? .10 : .37);
      }
      if (id === 'drift') {
        return path('M0 0H93Q60 18 68 58Q33 95 72 136Q29 190 51 242Q11 285 49 331Q52 383 88 460H0Z M360 0H303Q324 58 294 106Q345 154 308 203Q351 252 313 289Q338 354 305 396L286 460H360Z', verge, .72) +
          stroke('M11 78Q30 53 34 30M15 372Q37 389 45 419M347 98Q320 129 331 148M343 344Q326 371 340 401', dark ? '#719282' : '#D3DFB1', 3, .73);
      }
      return cornerInlays(rim) + stroke('M15 97V411M345 96V411', rim, 1.5, .44) + stroke('M16 427H344', rim, 2, .34);
    });
  }

  if (['platformer', 'grapple', 'flappy', 'hillclimb'].includes(id)) {
    const [sky, haze, far, near] = dark ? ['#263C53', '#425B67', '#3F5E6A', '#385A61'] : ['#BCDCEB', '#EAF1E3', '#9DBFC1', '#89B6A8'];
    const cloud = (x, y, size) => `<g transform="translate(${x} ${y}) scale(${size})">${path('M-5 18Q-5 11 9 11Q14 0 25 3Q35 3 38 11Q53 12 55 19Q55 23 48 23H1Q-5 23-5 18Z', dark ? '#8299AA' : '#F5FAF3', dark ? .32 : .78)}</g>`;
    const hills = {
      flappy: 'M0 389Q32 370 74 385Q116 411 172 399Q238 366 278 383Q318 369 360 390V460H0Z',
      platformer: 'M0 317Q45 299 74 329Q109 357 159 335Q207 309 233 331Q297 347 360 305V460H0Z',
      grapple: 'M0 309L37 249Q64 219 83 262L123 337Q152 363 178 337L268 259Q286 235 311 265L360 320V460H0Z',
      hillclimb: 'M0 273L44 207L67 219L123 146L179 229L230 178L266 209L300 160L360 228V460H0Z',
    };
    return { defs: gradient('sky', sky, haze), body: rect(0, 0, 360, 460, 0, 'url(#sky)') +
      ellipse(305, id === 'hillclimb' ? 51 : 38, 19, 19, dark ? '#C6D4DC' : '#F9E7B2', dark ? .52 : .91) +
      cloud(20, id === 'flappy' ? 57 : 91, 1.48) + cloud(237, 116, .9) +
      path(hills[id], far, .83) + path('M0 411Q64 377 121 410Q165 436 254 400Q308 376 360 402V460H0Z', near, .76) };
  }

  if (['fisheat', 'fishing'].includes(id)) {
    const [top, deep, blue, reed] = dark ? ['#365F72', '#203C53', '#82B0B9', '#4D756D'] : ['#C3E6EA', '#80C1CE', '#EBF7EF', '#6EA69A'];
    const isPond = id === 'fishing';
    const pondLight = `<radialGradient id="pondLight"><stop stop-color="${blue}" stop-opacity="${dark ? .21 : .55}"/>
      <stop offset="55%" stop-color="${blue}" stop-opacity="${dark ? .11 : .26}"/>
      <stop offset="100%" stop-color="${blue}" stop-opacity="0"/></radialGradient>`;
    const illumination = isPond ?
      `<g transform="rotate(-23 56 82)">${ellipse(56, 82, 86, 225, 'url(#pondLight)')}</g>` +
      `<g transform="rotate(-22 114 41)">${ellipse(114, 41, 54, 171, 'url(#pondLight)', .55)}</g>` :
      path('M2 0H41L137 346L93 318Z M64 0H89L157 299L136 294Z', blue, dark ? .11 : .31);
    return { defs: gradient('water', top, deep, true) + (isPond ? pondLight : ''), body: rect(0, 0, 360, 460, 0, 'url(#water)') +
      illumination +
      path('M0 407Q25 380 66 400Q95 424 159 442Q214 459 272 410Q311 385 360 399V460H0Z', reed, .43) +
      path('M0 454Q62 418 105 448Q164 475 223 446Q276 418 360 434V460H0Z', reed, .63) +
      stroke('M6 156q32-11 67 0m-57 11q22-7 43 0M282 190q34-10 71 0m-59 12q22-7 47 0M40 317q29-10 52 0M281 352q39-14 62 0', blue, 2, .46) +
      (isPond ? path('M0 441Q4 378 16 363Q9 405 15 441Q17 387 34 379Q20 419 22 446 M360 442Q355 391 344 374Q350 416 344 451Q342 407 328 390Q337 427 334 452Z', reed, .77) :
        path('M11 447Q-3 397 16 372Q16 409 30 423Q14 380 38 366Q31 413 46 445 M338 439Q359 397 344 354Q342 401 325 419Q333 385 316 380Q319 420 305 445Z', reed, .62)) };
  }

  if (id === 'shooter' || id === 'survival') {
    const space = id === 'shooter'
      ? ['#233651', '#182541', '#758FBA', '#172641', '#111A2F', '#5973A3']
      : ['#DBE9ED', '#BDCCD9', '#7DA1AE', '#2F4654', '#243342', '#607987'];
    if (id === 'survival') {
      return panel(space, rim => cornerInlays(rim) +
        path('M0 37L76 0H113L0 78Z M360 384V420L281 460H241Z', rim, .18) +
        stroke('M0 98L44 75M312 396L360 372', rim, 1.2, .52));
    }
    const [top, bottom, star] = pick(space);
    // The shooter scrolls two copies of this backdrop; each cloud vanishes before the seam.
    return { defs: '', body: rect(0, 0, 360, 460, 0, bottom) +
      path('M0 36Q59 79 55 157Q45 228 0 260Z M360 216Q293 261 304 350Q318 387 360 427Z', top, .75) +
      path('M0 72Q33 104 38 153Q33 202 0 226Z M360 252Q323 276 325 342Q339 370 360 392Z', star, .09) +
      Array.from({length: 38}, (_, i) => {
        const edge = i % 2 ? 0 : 270;
        return ellipse(edge + 9 + i * 27 % 78, 13 + i * 61 % 430, i % 5 ? .9 : 1.7, i % 5 ? .9 : 1.7, star, i % 3 ? .53 : .89);
      }).join('') };
  }

  if (id === 'pingpong' || id === 'airhockey') {
    const ice = id === 'airhockey';
    const colors = ice ? ['#E3F3F6', '#C9E1E7', '#8EB8C4', '#2F4A5B', '#213647', '#52788B']
      : ['#D9EAE4', '#BCD5CA', '#71968D', '#35544C', '#28403D', '#5F8279'];
    return panel(colors, rim => stroke('M15 17H345V438H15Z', ice ? rim : '#F5FAEE', 2, .65) +
      (ice ? ellipse(180, 230, 43, 43, rim, .14) + stroke('M124 4V11H236V4', '#C45857', 4) +
        stroke('M124 453V446H236V453', '#3576B4', 4) : stroke('M180 17V438', '#F5FAEE', 1.7, .47)));
  }

  if (['fruitslice', 'xiangqi', 'chess'].includes(id)) {
    const wood = id === 'fruitslice' ? ['#8B674E', '#694B3D', '#6F4F3A', '#35271F', '#2D211B', '#201713']
      : ['#F1E2C9', '#DCC3A3', '#AB8D6E', '#483D35', '#342D2B', '#75604D'];
    return panel(wood, rim => {
      const grain = Array.from({length: 13}, (_, i) => {
        const y = 23 + i * 33;
        return stroke(`M0 ${y}Q53 ${y - 7} 119 ${y}T235 ${y + 2}T360 ${y - 3}`, rim, i % 4 ? .8 : 1.5, i % 4 ? .25 : .36);
      }).join('');
      const rimGroove = id === 'fruitslice' ?
        stroke('M36 19H325Q341 19 341 34V422Q341 439 324 439H33Q18 439 18 420V37Q18 19 36 19Z', '#241910', 3, dark ? .42 : .46) +
        stroke('M37 21H322Q338 21 338 36V421Q338 436 322 436H36Q21 436 21 421', '#F9D9AE', 1.2, dark ? .16 : .36) +
        rect(156, 4, 48, 7, 3, '#231915', .41) : '';
      return grain + rimGroove + stroke('M15 25Q27 14 51 14H297M65 446H344', '#FFECCC', 2, dark ? .16 : .32);
    });
  }
  return undefined;
}

module.exports = { boardBackground };
