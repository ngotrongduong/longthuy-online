// Runs inside a www.meshy.ai tab (signed in). Paste once per full page load; see README for the download window.
// 1) Harvest: walks the public community list by tag and category, reads each model's task (triangles, licence,
//    texture) and keeps CC0, textured, Roblox-sized models, named and sorted into a theme folder.
// 2) Download: loads each kept model in the download window and clicks its Download button (format glb).
//    Every 5 clicks it saves a manifest that tools/sorter.py reads.
// State: ll_seen, ll_cands, ll_seen2 in IndexedDB 'll' (store 'kv'); ll_done, ll_hstat, ll_hstat2, ll_dstat,
// ll_stop in localStorage.
(async () => {
  if (window.__ll) return 'already running';
  window.__ll = 1;
  // The big lists live in IndexedDB: localStorage holds only 5 MB.
  const IDB = await new Promise((res, rej) => { const q = indexedDB.open('ll', 1); q.onupgradeneeded = () => q.result.createObjectStore('kv'); q.onsuccess = () => res(q.result); q.onerror = () => rej(q.error); });
  const BIG = ['ll_seen', 'll_cands', 'll_seen2'];
  const IC = {};
  for (const k of BIG) IC[k] = await new Promise(r => { const g = IDB.transaction('kv').objectStore('kv').get(k); g.onsuccess = () => r(g.result); g.onerror = () => r(undefined); });
  const S = (k, d) => { if (IC[k] !== undefined) return IC[k]; try { return JSON.parse(localStorage.getItem(k)) ?? d } catch (e) { return d } };
  const W = (k, v) => {
    try { if (BIG.includes(k)) IDB.transaction('kv', 'readwrite').objectStore('kv').put(v, k); else localStorage.setItem(k, JSON.stringify(v)); }
    catch (e) { console.warn('ll save', k, e) }
  };
  const GEN = window.__llGen = (window.__llGen || 0) + 1;   // a newer start makes the loops of this one quit
  const stopped = () => S('ll_stop', false) || window.__llGen !== GEN;
  // Timers run in a worker: when nobody uses the browser, Edge slows a page's own timers to about one a minute.
  const TK = new Worker(URL.createObjectURL(new Blob(['onmessage=e=>setTimeout(()=>postMessage(e.data[0]),e.data[1])'], { type: 'text/javascript' })));
  const TW8 = {}; let tkn = 0;
  TK.onmessage = e => { const f = TW8[e.data]; delete TW8[e.data]; if (f) f(); };
  const sleep = ms => new Promise(r => { const id = ++tkn; TW8[id] = r; TK.postMessage([id, ms]); });
  const API = '/meshyd-api/web/public';

  const RULES = [
    ['Props', 'Eggs', /\b(egg|eggs)\b/],
    ['Weapons', 'Swords', /\b(sword|swords|katana|saber|sabre|scimitar|longsword|greatsword|rapier|cutlass|claymore)\b/],
    ['Weapons', 'Daggers_Knives', /\b(dagger|daggers|knife|knives|shiv|kunai|sai)\b/],
    ['Weapons', 'Axes', /\b(axe|axes|battleaxe|hatchet|tomahawk)\b/],
    ['Weapons', 'Hammers_Maces', /\b(hammer|warhammer|mace|morningstar|morning star|flail|club)\b/],
    ['Weapons', 'Spears_Polearms', /\b(spear|lance|halberd|trident|scythe|glaive|polearm|pike|naginata)\b/],
    ['Weapons', 'Bows_Crossbows', /\b(bow|bows|longbow|crossbow|arrow|arrows|quiver|slingshot)\b/],
    ['Weapons', 'Guns', /\b(gun|guns|pistol|rifle|shotgun|revolver|blaster|smg|sniper|musket|minigun|firearm|uzi|ak47|ak-47|carbine|flintlock)\b/],
    ['Weapons', 'Explosives', /\b(grenade|bomb|dynamite|tnt|rocket launcher|bazooka|rpg|landmine|missile)\b/],
    ['Weapons', 'Heavy_Artillery', /\b(cannon|canon|howitzer|turret|artillery|flak|mortar|ballista|catapult|trebuchet)\b/],
    ['Weapons', 'Staffs_Wands', /\b(staff|wand|scepter|sceptre|magic rod)\b/],
    ['Weapons', 'Shields', /\b(shield|buckler)\b/],
    ['Weapons', 'Armor_Helmets', /\b(helmet|armor|armour|gauntlet|chestplate|breastplate)\b/],
    ['Weapons', 'Other_Weapons', /\b(weapon|weapons|blade|blades)\b/],
    ['Monsters', 'Dragons', /\b(dragon|dragons|wyvern|drake|hydra|wyrm)\b/],
    ['Monsters', 'Undead', /\b(skeleton|skeletal|zombie|ghost|lich|mummy|vampire|ghoul|undead|reaper|wraith|banshee|necromancer)\b/],
    ['Monsters', 'Demons', /\b(demon|demonic|devil|imp|fiend|hellhound|succubus|infernal)\b/],
    ['Monsters', 'Slimes_Blobs', /\b(slime|slimes|blob|jelly monster|ooze)\b/],
    ['Monsters', 'Golems_Elementals', /\b(golem|elemental|treant|ent|living rock|stone giant)\b/],
    ['Monsters', 'Spiders_Insects', /\b(spider|scorpion|insect|beetle|mantis|centipede|wasp|giant ant|worm|larva)\b/],
    ['Monsters', 'Orcs_Goblins_Trolls', /\b(orc|orcs|goblin|goblins|troll|ogre|kobold|gnoll|cyclops|minotaur|giant)\b/],
    ['Monsters', 'Beasts_Mythic', /\b(werewolf|yeti|chimera|griffin|gryphon|basilisk|kraken|cerberus|manticore|wendigo|hellbeast|phoenix|unicorn|pegasus)\b/],
    ['Monsters', 'Aliens_Mutants', /\b(alien|mutant|tentacle|eldritch|parasite)\b/],
    ['Monsters', 'Other_Monsters', /\b(monster|monsters|creature|beast|boss|kaiju|mimic|fiend)\b/],
    ['Vehicles', 'Vehicles', /\b(car|truck|tank|boat|ship|plane|airplane|aircraft|helicopter|bike|motorcycle|train|van|spaceship|starship|jeep|bus|submarine|kart|tractor|vehicle|wagon|carriage|rover|hovercraft|jet)\b/],
    ['Characters', 'Characters', /\b(knight|warrior|soldier|wizard|mage|ninja|samurai|character|hero|heroine|princess|prince|king|queen|pirate|villager|archer|astronaut|robot|mech|man|woman|boy|girl|chibi|figure|viking|cowboy|police|chef|farmer|witch|elf|dwarf|paladin|rogue|assassin|hunter|guard|npc)\b/],
    ['Animals', 'Animals', /\b(cat|dog|fox|wolf|bear|deer|stag|doe|fawn|rabbit|bunny|horse|cow|pig|sheep|goat|chicken|hen|duck|bird|owl|eagle|parrot|penguin|fish|shark|whale|dolphin|turtle|frog|snake|lizard|crocodile|lion|tiger|elephant|monkey|gorilla|panda|raccoon|squirrel|mouse|rat|bat|crab|octopus|dinosaur|t-rex|raptor|boar|llama|camel|giraffe|zebra|hippo|rhino|kangaroo|koala|sloth|otter|seal|hedgehog|bee|butterfly|snail|animal|pet|puppy|kitten|doberman|quetzal)\b/],
    ['Props', 'Containers', /\b(barrel|barrels|crate|crates|box|boxes|chest|sack|basket|pot|jar|vase|urn|bucket|keg|cauldron)\b/],
    ['Props', 'Treasure_Loot', /\b(coin|coins|gem|gems|crystal|crystals|gold|treasure|trophy|potion|potions|key|ring|crown|relic|artifact|artefact|chalice|goblet|loot|ingot|diamond|ruby|emerald|amulet|necklace|orb)\b/],
    ['Props', 'Furniture', /\b(chair|table|bed|sofa|couch|shelf|cabinet|desk|bench|stool|wardrobe|throne|bookshelf|bookcase|dresser|drawer|armchair|nightstand|furniture)\b/],
    ['Props', 'Lights_Fire', /\b(lamp|lantern|torch|candle|candles|chandelier|campfire|brazier|bonfire|streetlight|lamppost|fireplace)\b/],
    ['Props', 'Nature', /\b(tree|trees|rock|rocks|stone|stones|bush|bushes|plant|plants|flower|flowers|mushroom|mushrooms|grass|log|logs|stump|cactus|fern|palm|cliff|boulder|foliage|shrub|vine|coral|seaweed|pine|oak|bamboo|hay|haystack)\b/],
    ['Props', 'Buildings_Structures', /\b(house|hut|cabin|tower|castle|wall|gate|bridge|fence|arch|ruins|ruin|temple|shop|building|chalet|well|windmill|tent|shrine|cottage|shack|lighthouse|dock|pier|stairs|staircase|platform|watchtower|outpost|barn|church|pagoda|igloo|portal)\b/],
    ['Props', 'Decor', /\b(statue|sign|signpost|banner|flag|fountain|clock|painting|pillar|column|totem|gravestone|tombstone|grave|mailbox|bell|mirror|rug|carpet|wreath|ornament|decoration|sculpture|idol|monument|obelisk|scarecrow|altar|lamp post|trophy)\b/],
    ['Props', 'Food', /\b(food|apple|bread|cake|burger|pizza|fruit|drink|cheese|meat|donut|cookie|candy|sushi|pie|banana|carrot|watermelon|soda|coffee|cup|bottle|ice cream)\b/],
    ['Props', 'Tools_Items', /\b(pickaxe|shovel|tool|tools|anvil|rope|ladder|book|books|scroll|map|backpack|wrench|saw|hoe|rake|fishing rod|lockpick|compass|telescope|bag|toolbox|bucket)\b/],
    ['Props', 'SciFi_Tech', /\b(computer|terminal|machine|generator|console|screen|reactor|robot arm|drone|satellite|antenna|server|battery|capsule|pod|crate sci-fi|radio|tv|television|arcade)\b/],
  ];
  const CAT_FALLBACK = { WeaponsMilitary: ['Weapons', 'Other_Weapons'], Characters: ['Characters', 'Characters'],
    Animals: ['Animals', 'Animals'], FurnitureHome: ['Props', 'Furniture'], NaturePlants: ['Props', 'Nature'],
    Architecture: ['Props', 'Buildings_Structures'], FoodDrink: ['Props', 'Food'], FantasyMythology: ['Monsters', 'Other_Monsters'] };
  const MAXTRIS = { Sets: 80000, Weapons: 10000, Props: 10000, Monsters: 20000, Characters: 20000, Animals: 20000, Vehicles: 20000 };
  const PRIO = { Sets: 2.5, Weapons: 0, Monsters: 1, Props: 2, Characters: 3, Animals: 4, Vehicles: 5 };

  function classify(text, cats) {
    for (const [th, sb, re] of RULES) if (re.test(text)) return [th, sb];
    for (const c of cats || []) if (CAT_FALLBACK[c]) return CAT_FALLBACK[c];
    return null;
  }
  const STOP = new Set(['a', 'an', 'the', 'of', 'with', 'and', 'in', 'on', 'for', 'low', 'poly', 'lowpoly', 'low-poly', '3d',
    'model', 'stylized', 'game', 'asset', 'roblox', 'style', 'cartoon', 'pbr', 'high', 'quality', 'detailed', 'render', 'isolated',
    'white', 'background', 'simple', 'cute', 'mesh', 'texture', 'textured', 'compatible', 'r15', 'object', 'design', 'very',
    'create', 'generate', 'make', 'can', 'you', 'please', 'me', 'my', 'i', 'want', 'need', 'image', 'icon', 'highly', 'give',
    'cree', 'moi', 'une', 'un', 'de', 'la', 'le', 'des', 'et', 'du', 'el', 'una', 'crea', 'version', 'based', 'picture', 'photo',
    'reference', 'clean', 'symmetrical', 'silhouette', 'is', 'that', 'this', 'to', 'it', 'from', 'idle', 'pose', 'tpose', 'new']);
  function makeName(raw, fallback) {
    let s = (raw || '').split(/[,.;:\n(]/)[0].replace(/#[^#]*#/g, ' ').replace(/\*+/g, ' ').replace(/[_\-]+/g, ' ').replace(/[^\p{L}\p{N} ]+/gu, ' ');
    const words = s.split(/\s+/).filter(w => w && /^[A-Za-z0-9]+$/.test(w) && !STOP.has(w.toLowerCase())).slice(0, 5);
    const n = words.map(w => w[0].toUpperCase() + w.slice(1).toLowerCase()).join('_');
    return n.length >= 3 ? n : fallback;
  }

  const TAGS = ['lowpoly', 'low-poly', 'roblox', 'gameasset', 'game asset', 'stylized', 'cartoon', 'voxel', 'blocky',
    'sword', 'katana', 'axe', 'hammer', 'mace', 'spear', 'bow', 'crossbow', 'gun', 'pistol', 'rifle', 'shotgun', 'blaster',
    'cannon', 'grenade', 'bomb', 'staff', 'wand', 'shield', 'dagger', 'knife', 'weapon', 'weapons', 'scythe', 'helmet', 'armor',
    'monster', 'creature', 'dragon', 'skeleton', 'zombie', 'ghost', 'demon', 'slime', 'golem', 'goblin', 'orc', 'troll',
    'spider', 'boss', 'beast', 'undead', 'alien', 'werewolf', 'minotaur', 'kraken',
    'prop', 'props', 'barrel', 'crate', 'chest', 'treasure', 'potion', 'coin', 'gem', 'crystal', 'lamp', 'lantern', 'torch',
    'chair', 'table', 'furniture', 'tree', 'rock', 'plant', 'mushroom', 'house', 'tower', 'castle', 'fence', 'statue', 'sign',
    'food', 'tool', 'book', 'car', 'vehicle', 'tank', 'ship', 'robot', 'knight', 'character', 'animal', 'pet'];
  const CATS = ['WeaponsMilitary', 'FantasyMythology', 'Characters', 'Animals', 'FurnitureHome', 'NaturePlants', 'Architecture',
    'FoodDrink', 'Gaming', 'SciFi', 'ScienceTechnology', 'CultureHistory', 'ArtAbstract', 'AnimeManga', 'PlacesTravel'];
  const QUERIES = [];
  for (const sort of ['popularity', 'newest']) {
    for (const t of TAGS) QUERIES.push(`tags=${encodeURIComponent(t)}&sortBy=${sort}`);
    for (const c of CATS) QUERIES.push(`categories=${c}&sortBy=${sort}`);
  }

  const seen = (() => { const s = new Set(S('ll_seen', []).map(k => k.slice(-12))); return { has: k => s.has(k.slice(-12)), add: k => s.add(k.slice(-12)), [Symbol.iterator]: () => s[Symbol.iterator]() }; })();  // last 12 chars only: storage is small
  const cands = S('ll_cands', {});
  const done = S('ll_done', {});
  const hs = S('ll_hstat', { qi: 0, page: 1, checked: 0, kept: 0, finished: false });
  const ds = S('ll_dstat', { ok: 0, fail: 0, last: '' });
  window.__llState = { seen, cands, done, hs, ds };
  const saveH = () => { W('ll_seen', [...seen]); W('ll_cands', cands); W('ll_hstat', hs); };

  async function getJSON(url) {
    for (let i = 0; i < 4; i++) {
      try { const r = await fetch(url); if (r.status === 429) { await sleep(5000 * (i + 1)); continue } return await r.json(); }
      catch (e) { await sleep(2000 * (i + 1)); }
    }
    return null;
  }

  async function checkPost(p) {
    const ci = p.coverItem; const ref = ci && ci.refId;
    if (!ref || seen.has(ref) || p.isNsfw || ci.kind !== 'model') { if (ref) seen.add(ref); return; }
    seen.add(ref);
    const j = await getJSON(`${API}/v2/tasks/${ref}`); const t = j && j.result;
    hs.checked++;
    if (!t || t.status !== 'SUCCEEDED') return;
    const tris = t.triangleCount || t.faceCount || 0;
    if (t.license !== 'cc0' || tris < 120 || tris > 20000 || t.isNSFW) return;
    if (!JSON.stringify(t.result || {}).includes('colorMapUrl')) return;   // untextured
    const raw = [p.title, t.name, ci.objectPrompt].filter(Boolean).join(' ');
    const text = (raw + ' ' + (p.tags || []).join(' ')).toLowerCase();
    const cl = classify(raw.toLowerCase(), []) || classify(text, p.categories); if (!cl) return;  // tags are noisy: last
    if (tris > MAXTRIS[cl[0]]) return;
    const th = ci.thumbnails || {};
    cands[ref] = { r: ref, p: p.id, n: makeName(p.title || t.name || ci.objectPrompt, `${cl[1]}_${ref.slice(-6)}`), th: cl[0], sb: cl[1],
      t: tris, lic: t.license, a: (p.author && p.author.nickname) || '', l: (p.stats && p.stats.likesCount) || 0,
      d: (p.stats && p.stats.downloadsCount) || 0, img: th.thumbnailNoBgUrl || th.thumbnailUrl || '' };
    hs.kept++;
  }

  async function harvest() {
    while (!hs.finished && !stopped() && !S('ll_noharvest', false)) {   // ll_noharvest: the queue is long enough, leave the site's limits to the downloads
      if (hs.qi >= QUERIES.length) { hs.finished = true; break; }
      const q = QUERIES[hs.qi];
      const j = await getJSON(`${API}/community/posts?singleModel=true&pageSize=50&pageNum=${hs.page}&${q}`);
      const list = (j && j.code === 'OK' && j.result) || [];
      const fresh = list.filter(p => p.coverItem && p.coverItem.refId && !seen.has(p.coverItem.refId));
      for (let i = 0; i < fresh.length; i += 6) await Promise.all(fresh.slice(i, i + 6).map(checkPost));
      if (!list.length || !j.hasMore && list.length < 50 || hs.page >= 60) { hs.qi++; hs.page = 1; } else hs.page++;
      list.forEach(p => p.coverItem && p.coverItem.refId && seen.add(p.coverItem.refId));
      saveH();
      await sleep(300);
    }
    saveH();
  }

  let pending = [];
  function saveManifest() {
    if (!pending.length) return;
    const blob = new Blob([JSON.stringify({ llManifest: 1, items: pending })], { type: 'application/json' });
    const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = `ll_manifest_${Date.now()}.json`;
    document.body.appendChild(a); a.click(); a.remove();
    pending = [];
  }
  // The download window: opened by a real click (see README), it does a full page load per model, which frees
  // the memory hundreds of 3D views pile up; this tab only drives it, so it no longer freezes.
  const TW = () => (window.__TW && !window.__TW.closed) ? window.__TW : null;
  const tdoc = () => { try { return TW().document } catch (e) { return null } };
  function facesIn(d) {
    const el = d && [...d.querySelectorAll('div,span')].find(e => e.childElementCount === 0 && e.textContent.trim() === 'Faces');
    const v = el && el.parentElement && el.parentElement.innerText.replace('Faces', '').replace(/[^0-9]/g, '');
    return v ? parseInt(v, 10) : -1;
  }
  // The page shows faces; for some quad models the API counted triangles (1 to 2 per face).
  const fm = (f, t) => f === t || (f > 0 && f < t && t <= 2.2 * f);
  let loads = 0, lastTitle = '', lastN = '';   // the title changes only when the new model's data is in
  async function downloadOne(c) {
    const w = TW(); if (!w) return 'nowin';
    // Site navigation inside the window, a full page load every 5 models: a page load per model made the
    // site answer 403 after ~400 models; the reloads still free memory.
    let nav = false;
    // a model with the same name as the last one keeps the same title: load the page in full instead
    const same = c.n === lastN; lastN = c.n;
    if (loads < 5 && !same) { try { w.next.router.push('/posts/' + c.p); nav = true; loads++; } catch (e) {} }
    if (!nav) { w.location.href = '/posts/' + c.p; loads = 0; }
    await sleep(1500);
    let ok = false, d = null;
    for (let i = 0; i < 80; i++) { await sleep(300); d = tdoc(); let path = ''; try { path = w.location.pathname } catch (e) {} if (d && path.includes(c.p) && (same || d.title !== lastTitle) && fm(facesIn(d), c.t)) { await sleep(1200); d = tdoc(); if (d && fm(facesIn(d), c.t)) { ok = true; break; } } }   // read twice: the last model's count can linger
    if (ok) lastTitle = d.title;
    if (!ok) { const d0 = tdoc(); return d0 && /403/.test(d0.title) ? 'blocked' : 'faces ' + facesIn(d0); }
    // Quad models: Meshy counts quads, the GLB has about twice as many triangles.
    const topoEl = [...d.querySelectorAll('div,span')].find(e => e.childElementCount === 0 && e.textContent.trim() === 'Topology');
    const tp = /quad/i.test((topoEl && topoEl.parentElement && topoEl.parentElement.innerText) || '') ? 'quad' : 'tri';
    if (tp === 'quad' && facesIn(d) * 2 > MAXTRIS[c.th]) return 'quadbig';
    const bt = d.querySelector('[data-testid=community-showcase-download-btn]'); if (!bt) return 'nobtn';
    bt.click();
    let dl = null;
    for (let i = 0; i < 15 && !dl; i++) { await sleep(250); dl = [...d.querySelectorAll('button')].find(x => (x.innerText || '').trim() === 'Download'); }
    if (!dl) return 'nopop';
    const cb = d.querySelector('[data-testid=download-format-btn]');
    if (cb && cb.textContent.trim() !== 'glb') {
      cb.dispatchEvent(new w.PointerEvent('pointerdown', { bubbles: true, pointerType: 'mouse', button: 0 })); cb.click(); await sleep(500);
      const o = d.querySelector('[data-testid=download-format-option-glb]'); if (!o) return 'notglb';
      o.dispatchEvent(new w.PointerEvent('pointerdown', { bubbles: true, pointerType: 'mouse' }));
      o.dispatchEvent(new w.PointerEvent('pointerup', { bubbles: true, pointerType: 'mouse' })); o.click(); await sleep(400);
    }
    if (!cb || cb.textContent.trim() !== 'glb') return 'notglb';
    pending.push({ ...c, tp, ts: Date.now() });
    dl.click();
    await sleep(2500);
    if (/upgrade to download|download limit|reached.*limit/i.test(d.body.innerText)) return 'limit';
    return 'ok';
  }
  const signedIn = () => ![...document.querySelectorAll('a,button')].some(e => /^(Log In|Sign Up Free)$/.test((e.innerText || '').trim()));
  async function downloader() {
    let fails = 0;
    // reposts of one model keep its name and triangle count: download one of them only
    const okKeys = new Set(Object.values(cands).filter(c => done[c.r] === 'ok').map(c => c.n + '|' + c.t));
    while (!stopped()) {
      if (!signedIn()) { ds.last = 'waiting for sign-in'; W('ll_dstat', ds); await sleep(15000); continue; }
      if (!TW()) { window.__TW = window.open('/posts/01a1dc54-72bc-7763-89b8-08e26ad2cc6b', 'lldl', 'width=1200,height=900'); await sleep(5000); }   // pop-ups are allowed for the site
      if (!TW()) { ds.last = 'waiting for download window'; W('ll_dstat', ds); await sleep(5000); continue; }
      const queue = Object.values(cands).filter(c => !done[c.r]).sort((a, b) => (PRIO[a.th] - PRIO[b.th]) || (b.l - a.l));
      if (!queue.length) { if (hs.finished) break; await sleep(10000); continue; }
      const c = queue[0];
      const rc = classify(c.n.replace(/_/g, ' ').toLowerCase(), []);   // older entries were sorted with tags first
      if (rc && c.th !== 'Sets') { c.th = rc[0]; c.sb = rc[1]; }
      const key = c.n + '|' + c.t;
      if (okKeys.has(key)) { done[c.r] = 'dupe'; W('ll_done', done); continue; }
      let res;
      try { res = await downloadOne(c); } catch (e) { res = 'err ' + e; }
      if (res === 'blocked') { ds.blocked = (ds.blocked || 0) + 1; ds.blocked_at = new Date().toTimeString().slice(0, 5); ds.last = 'blocked by the site (403), waiting 15 min'; W('ll_dstat', ds); try { TW().close() } catch (e) {} await sleep(900000); continue; }
      Object.assign(done, S('ll_done', {}));   // union with what is stored: a restart's older loop may have saved too
      done[c.r] = res; W('ll_done', done);
      if (res === 'ok') { ds.ok++; okKeys.add(key); } else ds.fail++;
      fails = res === 'ok' ? 0 : fails + 1;
      if (fails >= 3) { try { TW().close() } catch (e) {} fails = 0; }   // a stuck window is replaced on the next turn
      ds.last = `${c.th}/${c.sb}/${c.n} ${res}`; W('ll_dstat', ds);
      if (res === 'limit') { saveManifest(); W('ll_stop', true); break; }
      if (pending.length >= 5) saveManifest();   // small batches: a frozen tab loses little
      await sleep(2000);   // a gentler pace for the site
    }
    saveManifest();
  }
  // Second pass: sets (several weapons, props or characters in one file), 20k-80k triangles in total, split later.
  // Only posts whose title or prompt reads like a set are checked; only those ids are remembered (storage is small).
  const SETRE = /\b(set|sets|pack|collection|kit|bundle|assortment|variety|arsenal|armory|armoury|inventory|lineup|pieces|items|assets|props|several|multiple|swords|weapons|guns|axes|potions|daggers|shields|helmets|monsters|creatures|characters|enemies|figures|crates|barrels|rocks|trees)\b/;
  const QUERIES2 = [];
  for (const sort of ['popularity', 'newest'])
    for (const t of ['set', 'pack', 'collection', 'kit', 'bundle', 'assets', 'asset pack', 'weapon set', 'weapons pack', 'props pack'])
      QUERIES2.push(`tags=${encodeURIComponent(t)}&sortBy=${sort}`);
  QUERIES2.push(...QUERIES);
  const seen2 = new Set(S('ll_seen2', []));
  const hs2 = S('ll_hstat2', { qi: 0, page: 1, checked: 0, kept: 0, finished: false });
  window.__llState.hs2 = hs2;
  async function checkSet(p) {
    const ci = p.coverItem; const ref = ci && ci.refId;
    if (!ref || seen2.has(ref) || cands[ref] || p.isNsfw || ci.kind !== 'model') return;
    const raw = [p.title, ci.objectPrompt].filter(Boolean).join(' ');
    if (!SETRE.test(raw.toLowerCase())) return;
    seen2.add(ref);
    const j = await getJSON(`${API}/v2/tasks/${ref}`); const t = j && j.result;
    hs2.checked++;
    if (!t || t.status !== 'SUCCEEDED' || t.license !== 'cc0' || t.isNSFW) return;
    const tris = t.triangleCount || t.faceCount || 0;
    if (tris <= 20000 || tris > MAXTRIS.Sets) return;
    if (!JSON.stringify(t.result || {}).includes('colorMapUrl')) return;
    const text = (raw + ' ' + (p.tags || []).join(' ')).toLowerCase();
    const cl = classify(raw.toLowerCase(), []) || classify(text, p.categories); if (!cl) return;
    const th = ci.thumbnails || {};
    cands[ref] = { r: ref, p: p.id, n: makeName(p.title || t.name || ci.objectPrompt, `Set_${ref.slice(-6)}`) + '_Set', th: 'Sets', sb: cl[0],
      t: tris, lic: t.license, a: (p.author && p.author.nickname) || '', l: (p.stats && p.stats.likesCount) || 0,
      d: (p.stats && p.stats.downloadsCount) || 0, img: th.thumbnailNoBgUrl || th.thumbnailUrl || '' };
    hs2.kept++;
  }
  async function harvestSets() {
    while (!hs2.finished && !stopped() && !S('ll_noharvest', false)) {
      if (hs2.qi >= QUERIES2.length) { hs2.finished = true; break; }
      const j = await getJSON(`${API}/community/posts?singleModel=true&pageSize=50&pageNum=${hs2.page}&${QUERIES2[hs2.qi]}`);
      const list = (j && j.code === 'OK' && j.result) || [];
      for (let i = 0; i < list.length; i += 6) await Promise.all(list.slice(i, i + 6).map(checkSet));
      if (!list.length || !j.hasMore && list.length < 50 || hs2.page >= 60) { hs2.qi++; hs2.page = 1; } else hs2.page++;
      W('ll_seen2', [...seen2]); W('ll_hstat2', hs2); W('ll_cands', cands);
      await sleep(300);
    }
  }
  window.__llSaveManifest = saveManifest;
  W('ll_stop', false);
  harvest();
  harvestSets();
  downloader();
  return 'started';
})()
