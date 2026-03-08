```
// ==UserScript==
// @name         Note Part 1 & 2 Approval (TaskRay Task) - v2.9
// @namespace    http://tampermonkey.net/
// @version      2.9
// @description  Adds "Note part 1/2 Approval" buttons on TaskRay Task record pages, with robust injection & fallback toolbar.
// @match        https://*.lightning.force.com/*
// @run-at       document-idle
// @all-frames   true
// @inject-into  content
// @grant        GM_addStyle
// ==/UserScript==

(function () {
  'use strict';

  // ====== Config ======
  const TIMEZONE = 'America/Denver';
  const BTN1_ID = 'tm-note-part1-approval';
  const BTN2_ID = 'tm-note-part2-approval';
  const BTN1_TEXT = 'Note part 1 Approval';
  const BTN2_TEXT = 'Note part 2 Approval';

  const SUBJECT1_VALUE = 'Interconnection: Approved';
  const STATUS1_VALUE  = 'Completed';
  const COMMENT1_SUFFIX = 'PN: IX Part 1 Application Approved. Documents/Email uploaded to Docs folder.';

  const SUBJECT2_VALUE = 'Interconnection: Approved';
  const STATUS2_VALUE  = 'Completed';
  const COMMENT2_SUFFIX = 'Interconnection Application Approved.';

  const LOG_TAG = '[ApprovalButtons]';
  const log = (...a) => console.log(LOG_TAG, ...a);

  // Only act on TASKRAY__Project_Task__c record pages (view/edit)
  function isTaskRayTaskRecordPage() {
    const p = location.pathname || '';
    // Typical: /lightning/r/TASKRAY__Project_Task__c/<Id>/view  (or /edit)
    return /\/lightning\/r\/TASKRAY__Project_Task__c\/[a-zA-Z0-9]+\/(view|edit)/.test(p);
  }

  // ====== Styles ======
  GM_addStyle(`
    #${BTN1_ID}, #${BTN2_ID} {
      font-size:12px; line-height:1; padding:.25rem .5rem;
      border-radius:4px; color:#fff; cursor:pointer; white-space:nowrap;
      border:1px solid transparent;
    }
    #${BTN1_ID}{ background:#4CAF50; border-color:#3c8d40; }
    #${BTN2_ID}{ background:#10b981; border-color:#0a8754; margin-left:.5rem; }
    #${BTN1_ID}:hover,#${BTN2_ID}:hover{ filter:brightness(0.95); }
    #${BTN1_ID}:disabled,#${BTN2_ID}:disabled{ opacity:.6; cursor:not-allowed; }

    /* When injecting into action bar */
    .forceActionsContainer li.tm-injected-btn-li{
      display:flex; align-items:center; margin-right:10px; padding:0;
    }

    /* Fallback floating toolbar */
    .tm-fallback-toolbar{
      position:fixed; right:16px; bottom:16px; z-index: 2147483647;
      background:#1f2937; color:#fff; border-radius:8px; box-shadow:0 6px 24px rgba(0,0,0,.25);
      padding:10px; display:flex; align-items:center; gap:8px;
    }
    .tm-fallback-toolbar .tm-title{
      font-size:12px; opacity:.8; margin-right:8px;
    }
  `);

  // ====== Helpers ======
  const sleep = (ms) => new Promise(r => setTimeout(r, ms));

  function waitFor(fn, timeout = 12000, interval = 150) {
    return new Promise(resolve => {
      const t0 = Date.now();
      (function tick(){
        try { const v = fn(); if (v) return resolve(v); } catch {}
        if (Date.now() - t0 > timeout) return resolve(null);
        setTimeout(tick, interval);
      })();
    });
  }

  function todayMD() {
    const d = new Date();
    const parts = new Intl.DateTimeFormat('en-US', {timeZone: TIMEZONE, month:'numeric', day:'numeric'})
      .formatToParts(d);
    const m = parts.find(p=>p.type==='month')?.value ?? '';
    const day = parts.find(p=>p.type==='day')?.value ?? '';
    return `${m}/${day}`;
  }

  function makeButton(id, text, onClick) {
    const b = document.createElement('button');
    b.id = id; b.type='button'; b.textContent = text;
    b.addEventListener('click', onClick);
    return b;
  }

  // Find a nice place to put the buttons if possible
  function getPreferredInjectionPoint() {
    // Strategy A: Activity tab <li>
    const activityLink = document.querySelector('a[data-label="Activity"], a#flexipage_tab2__item');
    const activityLi = activityLink?.closest('li.slds-tabs_default__item');
    if (activityLi) return activityLi;

    // Strategy B: Page header actions
    const actionsUL = document.querySelector('.forceActionsContainer ul.actionsContainer');
    if (actionsUL) {
      let li = actionsUL.querySelector('.tm-injected-btn-li');
      if (!li) {
        li = document.createElement('li');
        li.className = 'slds-button tm-injected-btn-li';
        actionsUL.prepend(li);
      }
      return li;
    }

    // Strategy C: Activity composer area (least ideal)
    const activityHdr = document.querySelector('.forceChatterPublisherActivityActions');
    if (activityHdr) return activityHdr;

    return null;
  }

  // Fallback floating toolbar that always shows
  function ensureFallbackToolbar() {
    let bar = document.querySelector('.tm-fallback-toolbar');
    if (!bar) {
      bar = document.createElement('div');
      bar.className = 'tm-fallback-toolbar';
      bar.innerHTML = `<span class="tm-title">Log Review:</span>`;
      document.body.appendChild(bar);
    }
    return bar;
  }

  function placeButtons() {
    // Already injected?
    if (document.getElementById(BTN1_ID) && document.getElementById(BTN2_ID)) return true;

    const spot = getPreferredInjectionPoint();
    if (spot) {
      if (!spot.querySelector('#'+BTN2_ID)) spot.appendChild(makeButton(BTN2_ID, BTN2_TEXT, runPart2));
      const btn2 = spot.querySelector('#'+BTN2_ID);
      if (!spot.querySelector('#'+BTN1_ID)) spot.insertBefore(makeButton(BTN1_ID, BTN1_TEXT, runPart1), btn2);
      log('Buttons injected at preferred location.');
      return true;
    }

    // Fallback toolbar
    const bar = ensureFallbackToolbar();
    if (!bar.querySelector('#'+BTN1_ID)) bar.appendChild(makeButton(BTN1_ID, BTN1_TEXT, runPart1));
    if (!bar.querySelector('#'+BTN2_ID)) bar.appendChild(makeButton(BTN2_ID, BTN2_TEXT, runPart2));
    log('Buttons injected in fallback toolbar.');
    return true;
  }

  // ====== Form helpers ======
  async function ensureLogReviewActive() {
    // Make Activity active (if present)
    const activityLink = await waitFor(() => document.querySelector('a[data-label="Activity"], a#flexipage_tab2__item'));
    if (activityLink && activityLink.getAttribute('aria-selected') !== 'true') {
      activityLink.click();
      await sleep(500);
    }

    // Open "Log Review" subtab
    const logReviewTab = await waitFor(() => document.querySelector('a[data-tab-name="TASKRAY__Project_Task__c.Log_Review"]'));
    if (!logReviewTab) throw new Error('Log Review tab not found');
    logReviewTab.click();
    await sleep(700);

    // Click "Create new..." if present
    const createNewBtn = Array.from(document.querySelectorAll('button.slds-button_neutral, button.slds-button.slds-button_neutral'))
      .find(b => (b.textContent||'').trim() === 'Create new...');
    if (createNewBtn && !createNewBtn.disabled) {
      createNewBtn.click();
      await sleep(1000);
    }
  }

  async function fillSubject(value) {
    const wrap = await waitFor(() => document.querySelector('div[data-target-selection-name="sfdc:RecordField.Task.Subject"]'));
    if (!wrap) throw new Error('Subject field container not found');
    const input = wrap.querySelector('input.slds-combobox__input');
    if (!input) throw new Error('Subject combobox input not found');

    input.click();
    await sleep(120);

    let picked = false;
    const dropdownId = input.getAttribute('aria-controls');
    if (dropdownId) {
      const opt = document.querySelector(`#${dropdownId} lightning-base-combobox-item[data-value="${CSS.escape(value)}"]`);
      if (opt) { opt.click(); picked = true; }
    }
    if (!picked) {
      input.value = value;
      input.dispatchEvent(new InputEvent('input', {bubbles:true, composed:true}));
      input.dispatchEvent(new Event('change', {bubbles:true}));
    }
    await sleep(80);
    input.blur();
  }

  async function setPicklistByText(containerSelector, targetText) {
    const cont = await waitFor(() => document.querySelector(containerSelector));
    if (!cont) throw new Error(`Picklist container not found: ${containerSelector}`);

    const trigger = cont.querySelector('button.slds-combobox__input, a.select');
    if (!trigger) throw new Error('Picklist trigger not found');

    const current = (trigger.textContent || trigger.value || '').trim();
    if (current === targetText) return;

    trigger.click();
    const dropdown = await waitFor(() => document.querySelector('.slds-dropdown-trigger_click.slds-is-open .slds-listbox, .uiMenuList.visible, .select-options'));
    if (!dropdown) throw new Error(`Dropdown not found for ${containerSelector}`);

    const item = Array.from(dropdown.querySelectorAll('lightning-base-combobox-item, a, span, li'))
      .find(el => (el.textContent || el.dataset.value || '').trim() === targetText);

    if (!item) { trigger.click(); throw new Error(`Picklist option "${targetText}" not found`); }
    item.click();
  }

  function setComments(text) {
    const ta = document.querySelector('div[data-target-selection-name="sfdc:RecordField.Task.Description"] textarea');
    if (!ta) throw new Error('Comments textarea not found');
    ta.focus();
    ta.value = text;
    ta.dispatchEvent(new InputEvent('input', {bubbles:true, composed:true}));
    ta.dispatchEvent(new Event('change', {bubbles:true}));
    ta.blur();
  }

  async function genericRun(cfg) {
    const btn = document.getElementById(cfg.id);
    if (btn) btn.disabled = true;
    try {
      log(`Start ${cfg.logPrefix}...`);
      await ensureLogReviewActive();

      const form = await waitFor(() => document.querySelector('.forceQuickActionLayout'), 15000);
      if (!form) throw new Error('Log Review form did not appear');

      await fillSubject(cfg.subject);
      await setPicklistByText('div[data-target-selection-name="sfdc:RecordField.Task.Status"]', cfg.status);
      setComments(`${todayMD()} - ${cfg.commentSuffix}`);
      log('Filled form. You can hit Save.');
    } catch (e) {
      console.error(`${LOG_TAG} ${cfg.logPrefix} ERROR:`, e);
      alert(`${cfg.text} — script error:\n${e?.message || e}`);
    } finally {
      if (btn) setTimeout(() => { btn.disabled = false; }, 1500);
    }
  }

  function runPart1() {
    genericRun({
      id: BTN1_ID, text: BTN1_TEXT, logPrefix: 'Part1',
      subject: SUBJECT1_VALUE, status: STATUS1_VALUE, commentSuffix: COMMENT1_SUFFIX
    });
  }
  function runPart2() {
    genericRun({
      id: BTN2_ID, text: BTN2_TEXT, logPrefix: 'Part2',
      subject: SUBJECT2_VALUE, status: STATUS2_VALUE, commentSuffix: COMMENT2_SUFFIX
    });
  }

  // ====== Boot ======
  function start() {
    if (!isTaskRayTaskRecordPage()) return; // Ignore other Lightning routes

    // Keep trying to place buttons as SF renders/updates
    placeButtons();
    const mo = new MutationObserver(() => placeButtons());
    mo.observe(document.documentElement, {childList:true, subtree:true});

    // Also retry on SPA route changes
    window.addEventListener('popstate', placeButtons, true);
    window.addEventListener('hashchange', placeButtons, true);

    // Light polling for first few seconds (covers heavy renders)
    let tries = 0;
    const t = setInterval(() => {
      if (document.getElementById(BTN1_ID) && document.getElementById(BTN2_ID)) { clearInterval(t); return; }
      if (tries++ > 40) { clearInterval(t); return; } // ~20s
      placeButtons();
    }, 500);
  }

  // Avoid double-boot
  if (!window.__tm_noteApprovals_booted__) {
    window.__tm_noteApprovals_booted__ = true;
    start();
  }
})();

```

