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

  // ====================================================================
  // CONFIGURATION
  // ====================================================================
  const TIMEZONE = 'America/Denver';
  const BTN_MISSING_DOC_ID = 'tm-note-missing-doc';
  const BTN1_ID = 'tm-note-part1-approval';
  const BTN2_ID = 'tm-note-part2-approval';
  const BTN_MISSING_DOC_TEXT = 'Missing Signed Doc';
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

  // ====================================================================
  // PAGE DETECTION
  // ====================================================================
  /**
   * Check if current page contains TASKRAY__Project_Task__c in URL.
   * Matches any URL path that includes TASKRAY__Project_Task__c.
   */
  function isTaskRayTaskRecordPage() {
    const p = location.pathname || '';
    return p.includes('TASKRAY__Project_Task__c');
  }

  // ====================================================================
  // STYLES
  // ====================================================================
  GM_addStyle(`
    #${BTN_MISSING_DOC_ID}, #${BTN1_ID}, #${BTN2_ID} {
      font-size:12px; line-height:1; padding:.25rem .5rem;
      border-radius:4px; color:#fff; cursor:pointer; white-space:nowrap;
      border:1px solid transparent;
    }
    #${BTN_MISSING_DOC_ID}{ background:#f59e0b; border-color:#d97706; }
    #${BTN1_ID}{ background:#4CAF50; border-color:#3c8d40; margin-left:.5rem; }
    #${BTN2_ID}{ background:#10b981; border-color:#0a8754; margin-left:.5rem; }
    #${BTN_MISSING_DOC_ID}:hover,#${BTN1_ID}:hover,#${BTN2_ID}:hover{ filter:brightness(0.95); }
    #${BTN_MISSING_DOC_ID}:disabled,#${BTN1_ID}:disabled,#${BTN2_ID}:disabled{ opacity:.6; cursor:not-allowed; }

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

    /* Search dialog modal */
    .tm-search-modal {
      position:fixed; top:0; left:0; right:0; bottom:0; z-index:2147483648;
      background:rgba(0,0,0,0.5); display:flex; align-items:center; justify-content:center;
    }
    .tm-search-dialog {
      background:#fff; border-radius:8px; padding:24px; min-width:400px; box-shadow:0 12px 48px rgba(0,0,0,0.3);
    }
    .tm-search-dialog h3 {
      margin:0 0 16px 0; font-size:18px; font-weight:600; color:#1f2937;
    }
    .tm-search-dialog input {
      width:100%; padding:10px; border:1px solid #d1d5db; border-radius:4px; font-size:14px; box-sizing:border-box;
    }
    .tm-search-dialog input:focus {
      outline:none; border-color:#3b82f6; box-shadow:0 0 0 3px rgba(59,130,246,0.1);
    }
    .tm-search-dialog-buttons {
      margin-top:16px; display:flex; gap:8px; justify-content:flex-end;
    }
    .tm-search-dialog-buttons button {
      padding:8px 16px; border-radius:4px; font-size:14px; cursor:pointer; border:none;
    }
    .tm-search-dialog-buttons .tm-btn-search {
      background:#3b82f6; color:#fff;
    }
    .tm-search-dialog-buttons .tm-btn-search:hover {
      background:#2563eb;
    }
    .tm-search-dialog-buttons .tm-btn-cancel {
      background:#e5e7eb; color:#374151;
    }
    .tm-search-dialog-buttons .tm-btn-cancel:hover {
      background:#d1d5db;
    }
  `);

  // ====================================================================
  // UTILITY FUNCTIONS
  // ====================================================================
  /**
   * Sleep for specified milliseconds.
   */
  const sleep = (ms) => new Promise(r => setTimeout(r, ms));

  /**
   * Wait for a condition function to return truthy value.
   * @param {Function} fn - Condition function
   * @param {number} timeout - Max wait time in ms
   * @param {number} interval - Check interval in ms
   * @returns {Promise} Resolves with result of fn() or null on timeout
   */
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

  /**
   * Get today's date in M/D format using configured timezone.
   */
  function todayMD() {
    const d = new Date();
    const parts = new Intl.DateTimeFormat('en-US', {timeZone: TIMEZONE, month:'numeric', day:'numeric'})
      .formatToParts(d);
    const m = parts.find(p=>p.type==='month')?.value ?? '';
    const day = parts.find(p=>p.type==='day')?.value ?? '';
    return `${m}/${day}`;
  }

  /**
   * Create a button element.
   * @param {string} id - Button ID
   * @param {string} text - Button text
   * @param {Function} onClick - Click handler
   * @returns {HTMLButtonElement}
   */
  function makeButton(id, text, onClick) {
    const b = document.createElement('button');
    b.id = id; b.type='button'; b.textContent = text;
    b.addEventListener('click', onClick);
    return b;
  }

  // ====================================================================
  // BUTTON INJECTION
  // ====================================================================
  /**
   * Find preferred injection point for buttons in the Salesforce UI.
   * Tries multiple strategies in order of preference.
   * @returns {HTMLElement|null}
   */
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

  /**
   * Create fallback floating toolbar if preferred injection fails.
   * @returns {HTMLElement}
   */
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

  /**
   * Place all buttons in the UI (preferred location or fallback toolbar).
   * @returns {boolean} True if buttons were placed
   */
  function placeButtons() {
    // Already injected?
    if (document.getElementById(BTN_MISSING_DOC_ID) &&
        document.getElementById(BTN1_ID) &&
        document.getElementById(BTN2_ID)) return true;

    const spot = getPreferredInjectionPoint();
    if (spot) {
      // Inject buttons in order: Missing Doc, Part 1, Part 2
      if (!spot.querySelector('#'+BTN2_ID)) spot.appendChild(makeButton(BTN2_ID, BTN2_TEXT, runPart2));
      const btn2 = spot.querySelector('#'+BTN2_ID);
      if (!spot.querySelector('#'+BTN1_ID)) spot.insertBefore(makeButton(BTN1_ID, BTN1_TEXT, runPart1), btn2);
      const btn1 = spot.querySelector('#'+BTN1_ID);
      if (!spot.querySelector('#'+BTN_MISSING_DOC_ID)) spot.insertBefore(makeButton(BTN_MISSING_DOC_ID, BTN_MISSING_DOC_TEXT, runMissingDoc), btn1);
      log('Buttons injected at preferred location.');
      return true;
    }

    // Fallback toolbar
    const bar = ensureFallbackToolbar();
    if (!bar.querySelector('#'+BTN_MISSING_DOC_ID)) bar.appendChild(makeButton(BTN_MISSING_DOC_ID, BTN_MISSING_DOC_TEXT, runMissingDoc));
    if (!bar.querySelector('#'+BTN1_ID)) bar.appendChild(makeButton(BTN1_ID, BTN1_TEXT, runPart1));
    if (!bar.querySelector('#'+BTN2_ID)) bar.appendChild(makeButton(BTN2_ID, BTN2_TEXT, runPart2));
    log('Buttons injected in fallback toolbar.');
    return true;
  }

  // ====================================================================
  // SALESFORCE FORM INTERACTION HELPERS
  // ====================================================================
  /**
   * Activate the Activity tab and open Log Review subtab.
   * Creates a new Log Review entry if needed.
   */
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

  /**
   * Fill the Subject field in Log Review form.
   * Attempts to pick from dropdown if available, otherwise types value.
   * @param {string} value - Subject value to set
   */
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

  /**
   * Set a picklist field to a specific text value.
   * @param {string} containerSelector - CSS selector for field container
   * @param {string} targetText - Value to select from picklist
   */
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

  /**
   * Set the Comments (Description) field value.
   * @param {string} text - Text to set in comments field
   */
  function setComments(text) {
    const ta = document.querySelector('div[data-target-selection-name="sfdc:RecordField.Task.Description"] textarea');
    if (!ta) throw new Error('Comments textarea not found');
    ta.focus();
    ta.value = text;
    ta.dispatchEvent(new InputEvent('input', {bubbles:true, composed:true}));
    ta.dispatchEvent(new Event('change', {bubbles:true}));
    ta.blur();
  }

  // ====================================================================
  // WORKFLOW EXECUTION HELPERS
  // ====================================================================
  /**
   * Generic workflow runner for filling Log Review forms.
   * @param {Object} cfg - Configuration object
   * @param {string} cfg.id - Button ID
   * @param {string} cfg.text - Button text for error messages
   * @param {string} cfg.logPrefix - Prefix for log messages
   * @param {string} cfg.subject - Subject value to set
   * @param {string} cfg.status - Status picklist value
   * @param {string} cfg.commentSuffix - Comment text to append after date
   */
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

  // ====================================================================
  // SALESFORCE SEARCH & NAVIGATION HELPERS
  // ====================================================================
  /**
   * Show a modal dialog to prompt user for search term.
   * @returns {Promise<string|null>} The search term or null if canceled
   */
  function showSearchDialog() {
    return new Promise((resolve) => {
      // Create modal
      const modal = document.createElement('div');
      modal.className = 'tm-search-modal';
      modal.innerHTML = `
        <div class="tm-search-dialog">
          <h3>Search for TaskRay Task</h3>
          <input type="text" id="tm-search-input" placeholder="Enter address, Task ID, or Case Number" autofocus />
          <div class="tm-search-dialog-buttons">
            <button class="tm-btn-cancel">Cancel</button>
            <button class="tm-btn-search">Search</button>
          </div>
        </div>
      `;

      document.body.appendChild(modal);

      const input = modal.querySelector('#tm-search-input');
      const searchBtn = modal.querySelector('.tm-btn-search');
      const cancelBtn = modal.querySelector('.tm-btn-cancel');

      const cleanup = (result) => {
        modal.remove();
        resolve(result);
      };

      // Handle search
      searchBtn.addEventListener('click', () => cleanup(input.value.trim() || null));

      // Handle cancel
      cancelBtn.addEventListener('click', () => cleanup(null));

      // Handle Enter key
      input.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') cleanup(input.value.trim() || null);
        if (e.key === 'Escape') cleanup(null);
      });

      // Handle click outside dialog
      modal.addEventListener('click', (e) => {
        if (e.target === modal) cleanup(null);
      });

      // Focus input
      setTimeout(() => input.focus(), 100);
    });
  }

  /**
   * Open Salesforce in a new tab and perform search via UI automation.
   * @param {string} searchTerm - Term to search for
   */
  async function performSalesforceSearchInNewTab(searchTerm) {
    log('Opening new tab for automated search...');

    // Open new tab to Salesforce home
    const baseUrl = `${window.location.protocol}//${window.location.host}`;
    const newTab = window.open(baseUrl, '_blank');

    if (!newTab) {
      throw new Error('Failed to open new tab. Please allow popups for this site.');
    }

    // Store that we need to perform search in new tab
    localStorage.setItem('tm_perform_search', 'true');
    localStorage.setItem('tm_search_term', searchTerm);
    localStorage.setItem('tm_search_initiated', Date.now().toString());

    log('New tab opened, search will execute automatically');
  }

  /**
   * Check if this tab should perform automated search (triggered by localStorage).
   * Called during initialization.
   */
  async function checkAndPerformStoredSearch() {
    log('checkAndPerformStoredSearch: Starting check...');
    const performSearch = localStorage.getItem('tm_perform_search');
    const searchTerm = localStorage.getItem('tm_search_term');
    const initiatedTime = localStorage.getItem('tm_search_initiated');

    log(`checkAndPerformStoredSearch: performSearch="${performSearch}", searchTerm="${searchTerm}", initiatedTime="${initiatedTime}"`);

    // Only execute if search was initiated within last 30 seconds
    if (!performSearch || !searchTerm || !initiatedTime || (Date.now() - parseInt(initiatedTime) > 30000)) {
      log('checkAndPerformStoredSearch: No valid stored search found, exiting');
      return;
    }

    // Clear the stored search to prevent re-execution
    localStorage.removeItem('tm_perform_search');
    localStorage.removeItem('tm_search_term');
    localStorage.removeItem('tm_search_initiated');

    log(`Found stored search for term: "${searchTerm}", will execute search workflow...`);

    try {
      // Wait for Salesforce to be fully loaded
      log('Waiting for Salesforce page to load...');
      await waitFor(() => {
        return document.querySelector('one-appnav') ||
               document.querySelector('.slds-global-header') ||
               document.querySelector('div.slds-global-header__item_search button') ||
               document.querySelector('button[aria-label*="Search"]');
      }, 15000);

      await sleep(2000);
      log('Page loaded, starting search automation...');

      // Use the '/' key approach to activate global search
      log('Activating global search with "/" key...');
      
      // Create and dispatch the '/' key event
      const slashKeyEvent = new KeyboardEvent('keydown', {
        key: '/',
        code: 'Slash',
        keyCode: 191, // keyCode for '/' key
        which: 191,
        bubbles: true,
        cancelable: true,
        composed: true
      });
      
      document.dispatchEvent(slashKeyEvent);
      await sleep(1000);
      
      // Capture the now-focused search field and type without additional DOM lookups
      const searchInput = await waitFor(() => {
        const active = document.activeElement;
        return (active && active.tagName === 'INPUT') ? active : null;
      }, 5000);

      if (!searchInput) {
        throw new Error('Search field did not activate after "/" key');
      }

      log('Typing search term via active input...');

      searchInput.focus();
      searchInput.value = '';
      searchInput.dispatchEvent(new InputEvent('input', {bubbles: true, composed: true}));

      for (const char of searchTerm) {
        searchInput.value += char;
        searchInput.dispatchEvent(new InputEvent('input', {data: char, bubbles: true, composed: true}));
        await sleep(60);
      }

      searchInput.dispatchEvent(new Event('change', {bubbles: true, composed: true}));
      await sleep(150);

      log('Submitting search with Enter key...');
      
      // Submit search with Enter key
      const enterEventProps = {
        key: 'Enter',
        code: 'Enter',
        keyCode: 13,
        which: 13,
        bubbles: true,
        composed: true,
        cancelable: true
      };
      
      searchInput.dispatchEvent(new KeyboardEvent('keydown', enterEventProps));
      await sleep(200);
      
      searchInput.dispatchEvent(new KeyboardEvent('keypress', enterEventProps));
      await sleep(200);
      
      searchInput.dispatchEvent(new KeyboardEvent('keyup', enterEventProps));
      await sleep(1000);

      // Wait for search results
      log('Waiting for search results to load...');
      await sleep(4000);

      // Continue with clicking first TaskRay Task result
      await clickFirstTaskRayResult();
      await navigateToTaskRayProject();

    } catch (e) {
      console.error(`${LOG_TAG} Search automation ERROR:`, e);
      alert(`Search automation error:\n${e?.message || e}`);
    }
  }

  /**
   * Click the first TaskRay Task result from search results.
   */
  async function clickFirstTaskRayResult() {
    log('Looking for TaskRay Task results...');

    // Wait for search results container
    await waitFor(() =>
      document.querySelector('div.predictedResultsScrollWrapper, div.forceSearchResultsGridView, div.search-results'), 10000);
    await sleep(1500);

    // Find first TaskRay Task link in results
    const taskLink = await waitFor(() => {
      // Try multiple selectors for task links
      const links = document.querySelectorAll('div.windowViewMode-normal tbody th a, a[title*="AAMO"], a[href*="TASKRAY__Project_Task__c"], div.search-results a');
      
      // First try to find a link with TASKRAY__Project_Task__c in href
      let link = Array.from(links).find(link => link.href?.includes('TASKRAY__Project_Task__c'));
      
      // If not found, try a more general approach
      if (!link) {
        const allLinks = document.querySelectorAll('a');
        for (const l of allLinks) {
          if (l.href?.includes('TASKRAY__Project_Task__c')) {
            link = l;
            break;
          }
        }
      }
      
      return link;
    }, 10000);

    if (!taskLink) throw new Error('No TaskRay Task found in search results');

    log('Found TaskRay Task, clicking...');
    taskLink.click();
    await sleep(2500);
  }

  /**
   * Navigate to the TaskRay Project from the current Task page.
   */
  async function navigateToTaskRayProject() {
    log('Navigating to TaskRay Project...');

    // Wait for page to load
    await waitFor(() => document.querySelector('div.windowViewMode-normal, div.record-layout'), 8000);
    await sleep(1500);

    // Find project link (usually in Details section)
    const projectLink = await waitFor(() => {
      // Look for link containing "TASKRAY__Project__c" in href
      const links = document.querySelectorAll('a[href*="TASKRAY__Project__c"]');
      
      // Prefer links in the first column (Details section) or with specific classes
      const detailsLinks = Array.from(document.querySelectorAll('flexipage-column2:first-of-type a[href*="TASKRAY__Project__c"], .detail-section a[href*="TASKRAY__Project__c"]'));
      
      // Try to find link in shadow DOM as well
      let shadowLink = null;
      const allElements = document.querySelectorAll('*');
      for (const el of allElements) {
        if (el.shadowRoot) {
          const shadowLinks = el.shadowRoot.querySelectorAll('a[href*="TASKRAY__Project__c"]');
          if (shadowLinks.length > 0) {
            shadowLink = shadowLinks[0];
            break;
          }
        }
      }
      
      return detailsLinks[0] || links[0] || shadowLink;
    }, 10000);

    if (!projectLink) throw new Error('TaskRay Project link not found on page');

    log('Found TaskRay Project link, clicking...');
    projectLink.click();
    await sleep(2500);

    log('Navigation to TaskRay Project complete');
  }

  // ====================================================================
  // WORKFLOW 1: MISSING SIGNED DOCUMENT
  // ====================================================================
  /**
   * Handler for "Missing Signed Doc" button.
   * Prompts user for search term, opens new tab, and automatically performs search.
   */
  async function runMissingDoc() {
    const btn = document.getElementById(BTN_MISSING_DOC_ID);
    if (btn) btn.disabled = true;

    try {
      log('Starting Missing Signed Doc workflow...');

      // Step 1: Show search dialog
      const searchTerm = await showSearchDialog();
      if (!searchTerm) {
        log('Search canceled by user');
        if (btn) btn.disabled = false;
        return;
      }

      log(`Opening new tab to search for: ${searchTerm}`);

      // Step 2: Open new tab and initiate automated search
      await performSalesforceSearchInNewTab(searchTerm);

      log('New tab opened, search will execute automatically');

    } catch (e) {
      console.error(`${LOG_TAG} Missing Signed Doc ERROR:`, e);
      alert(`Missing Signed Doc — script error:\n${e?.message || e}`);
    } finally {
      if (btn) setTimeout(() => { btn.disabled = false; }, 1500);
    }
  }

  // ====================================================================
  // WORKFLOW 2: PART 1 APPROVAL
  // ====================================================================
  /**
   * Handler for "Note part 1 Approval" button.
   * Fills Log Review with Part 1 approval details.
   */
  function runPart1() {
    genericRun({
      id: BTN1_ID,
      text: BTN1_TEXT,
      logPrefix: 'Part1',
      subject: SUBJECT1_VALUE,
      status: STATUS1_VALUE,
      commentSuffix: COMMENT1_SUFFIX
    });
  }

  // ====================================================================
  // WORKFLOW 3: PART 2 APPROVAL
  // ====================================================================
  /**
   * Handler for "Note part 2 Approval" button.
   * Fills Log Review with Part 2 approval details.
   */
  function runPart2() {
    genericRun({
      id: BTN2_ID,
      text: BTN2_TEXT,
      logPrefix: 'Part2',
      subject: SUBJECT2_VALUE,
      status: STATUS2_VALUE,
      commentSuffix: COMMENT2_SUFFIX
    });
  }

  // ====================================================================
  // INITIALIZATION & MONITORING
  // ====================================================================
  /**
   * Start the script: inject buttons and monitor for page changes.
   */
  async function start() {
    // ALWAYS check if this tab should perform a stored search (runs on any page)
    await checkAndPerformStoredSearch();

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
      if (document.getElementById(BTN_MISSING_DOC_ID) &&
          document.getElementById(BTN1_ID) &&
          document.getElementById(BTN2_ID)) {
        clearInterval(t);
        return;
      }
      if (tries++ > 40) { clearInterval(t); return; } // ~20s
      placeButtons();
    }, 500);
  }

  // ====================================================================
  // BOOT
  // ====================================================================
  // Avoid double-boot
  if (!window.__tm_noteApprovals_booted__) {
    window.__tm_noteApprovals_booted__ = true;
    log('Script initializing...');
    start();
  }
})();
