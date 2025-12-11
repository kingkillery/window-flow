# CLAUDE.md - Userscript Development Guide

This file provides guidance to Claude Code when working with Tampermonkey/Greasemonkey userscripts in this repository.

## Overview

This repository contains userscripts for browser automation, primarily targeting **Salesforce Lightning** and other modern web applications that use:
- **Shadow DOM** (Lightning Web Components)
- **Dynamic rendering** (React, Vue, Web Components)
- **Single Page Applications** (SPA routing)

## Core Principles

### 1. **Always Assume Shadow DOM**
Modern web applications (especially Salesforce Lightning) heavily use Web Components with shadow DOM encapsulation. Standard DOM queries will fail.

### 2. **Always Assume Dynamic Rendering**
Elements may not exist until user interaction triggers rendering. Never query once—always use waitFor patterns.

### 3. **Always Assume SPA Behavior**
Pages don't reload; they swap content. Monitor for route changes and DOM mutations.

---

## Shadow DOM Best Practices

### Traversing Shadow DOM

```javascript
/**
 * Recursively find all elements (including shadow DOM)
 * @param {Element} root - Root element to start traversal
 * @param {string} selector - CSS selector to match
 * @returns {Array<Element>} All matching elements
 */
function querySelectorDeep(root = document.body, selector) {
  const results = [];

  // Query current level
  results.push(...Array.from(root.querySelectorAll(selector)));

  // Traverse shadow roots
  const allElements = root.querySelectorAll('*');
  for (const el of allElements) {
    if (el.shadowRoot) {
      results.push(...querySelectorDeep(el.shadowRoot, selector));
    }
  }

  return results;
}
```

### Finding Inputs in Shadow DOM

```javascript
function findInputDeep(filterFn) {
  const getAllInputs = (root = document.body) => {
    const inputs = [];
    inputs.push(...Array.from(root.querySelectorAll('input')));

    const allElements = root.querySelectorAll('*');
    for (const el of allElements) {
      if (el.shadowRoot) {
        inputs.push(...getAllInputs(el.shadowRoot));
      }
    }
    return inputs;
  };

  return getAllInputs().filter(filterFn)[0] || null;
}

// Usage
const searchInput = findInputDeep(inp =>
  inp.offsetParent !== null &&
  inp.getAttribute('aria-label')?.includes('Search')
);
```

### Checking if Element is in Shadow DOM

```javascript
function isInShadowDOM(element) {
  return element.getRootNode() !== document;
}

function getShadowRoot(element) {
  return element.getRootNode();
}
```

---

## Dynamic Rendering Best Practices

### Universal waitFor Pattern

```javascript
/**
 * Wait for condition with timeout
 * @param {Function} fn - Condition function returning truthy value
 * @param {number} timeout - Max wait time in ms
 * @param {number} interval - Check interval in ms
 * @returns {Promise} Resolves with fn() result or null on timeout
 */
function waitFor(fn, timeout = 12000, interval = 150) {
  return new Promise(resolve => {
    const t0 = Date.now();
    (function tick() {
      try {
        const result = fn();
        if (result) return resolve(result);
      } catch (e) {
        // Ignore errors during polling
      }
      if (Date.now() - t0 > timeout) return resolve(null);
      setTimeout(tick, interval);
    })();
  });
}
```

### Waiting for Visibility

```javascript
async function waitForVisible(selector, timeout = 10000) {
  return waitFor(() => {
    const el = querySelectorDeep(document.body, selector);
    return el && el.offsetParent !== null ? el : null;
  }, timeout);
}
```

### Waiting After User Action

```javascript
async function clickAndWait(button, waitForSelector, waitMs = 1500) {
  button.click();
  await sleep(waitMs); // Allow animation/transition
  return waitFor(() => querySelectorDeep(document.body, waitForSelector));
}
```

---

## Event Handling Best Practices

### Proper Event Sequencing for Inputs

```javascript
async function fillInput(input, text) {
  // 1. Focus and click (activate component)
  input.focus();
  input.click();
  await sleep(200);

  // 2. Clear existing value
  input.value = '';
  input.dispatchEvent(new InputEvent('input', {
    bubbles: true,
    composed: true // CRITICAL for shadow DOM
  }));

  // 3. Type character by character
  for (const char of text) {
    input.value += char;
    input.dispatchEvent(new InputEvent('input', {
      data: char,
      bubbles: true,
      composed: true
    }));
    await sleep(50); // Human-like typing
  }

  // 4. Trigger change event
  input.dispatchEvent(new Event('change', {
    bubbles: true,
    composed: true
  }));
}
```

### Proper Keyboard Events

```javascript
function pressEnter(element) {
  const eventProps = {
    key: 'Enter',
    code: 'Enter',
    keyCode: 13,
    which: 13,
    bubbles: true,
    composed: true, // CRITICAL for shadow DOM
    cancelable: true
  };

  element.dispatchEvent(new KeyboardEvent('keydown', eventProps));
  element.dispatchEvent(new KeyboardEvent('keypress', eventProps));
  element.dispatchEvent(new KeyboardEvent('keyup', eventProps));
}
```

### Click Events for Shadow DOM

```javascript
function clickElement(element) {
  // Real click events automatically cross shadow boundaries
  element.click();

  // Or dispatch for more control
  element.dispatchEvent(new MouseEvent('click', {
    bubbles: true,
    composed: true, // CRITICAL for shadow DOM
    cancelable: true
  }));
}
```

---

## SPA & Dynamic Page Best Practices

### Monitoring for SPA Route Changes

```javascript
function observeRouteChanges(callback) {
  // URL-based routing
  window.addEventListener('popstate', callback);
  window.addEventListener('hashchange', callback);

  // Modern SPA routing (intercept pushState/replaceState)
  const originalPushState = history.pushState;
  history.pushState = function(...args) {
    originalPushState.apply(this, args);
    callback();
  };

  const originalReplaceState = history.replaceState;
  history.replaceState = function(...args) {
    originalReplaceState.apply(this, args);
    callback();
  };
}
```

### DOM Mutation Monitoring

```javascript
function observeDOM(callback, options = {}) {
  const observer = new MutationObserver(() => callback());
  observer.observe(document.documentElement, {
    childList: true,
    subtree: true,
    ...options
  });
  return observer;
}

// Usage
const observer = observeDOM(() => {
  // Re-inject buttons, re-check state, etc.
  placeButtons();
});
```

### Retry Pattern for Dynamic Elements

```javascript
async function ensureElementExists(findFn, maxRetries = 40, retryInterval = 500) {
  let tries = 0;
  const intervalId = setInterval(async () => {
    const element = findFn();
    if (element) {
      clearInterval(intervalId);
      return element;
    }
    if (tries++ > maxRetries) {
      clearInterval(intervalId);
      throw new Error('Element not found after max retries');
    }
  }, retryInterval);
}
```

---

## Salesforce Lightning Specific

### Common Shadow DOM Components

```javascript
// Lightning Web Components that use shadow DOM
const LIGHTNING_COMPONENTS = [
  'lightning-input',
  'lightning-textarea',
  'lightning-combobox',
  'lightning-button',
  'lightning-datatable',
  'lightning-record-edit-form',
  'one-appnav',
  'lightning-global-navigation'
];

// Search their shadow roots
function findInLightningComponent(componentTag, selector) {
  const component = document.querySelector(componentTag);
  return component?.shadowRoot?.querySelector(selector) || null;
}
```

### Global Search Pattern

```javascript
async function performGlobalSearch(searchTerm) {
  // 1. Wait for header to load
  await waitFor(() => document.querySelector('one-appnav'));

  // 2. Click search button (reveals input)
  const searchBtn = await waitFor(() =>
    document.querySelector('button[title*="Search"]')
  );
  searchBtn.click();
  await sleep(1500);

  // 3. Find input (may be in shadow DOM)
  const searchInput = await waitFor(() => {
    // Try direct
    let inp = document.querySelector('input[type="search"]');
    if (inp?.offsetParent !== null) return inp;

    // Try shadow DOM
    const appNav = document.querySelector('one-appnav');
    inp = appNav?.shadowRoot?.querySelector('input[type="search"]');
    return inp?.offsetParent !== null ? inp : null;
  }, 10000);

  if (!searchInput) throw new Error('Search input not found');

  // 4. Fill and submit
  await fillInput(searchInput, searchTerm);
  pressEnter(searchInput);
}
```

### Picklist Interaction

```javascript
async function setPicklist(containerSelector, targetValue) {
  const container = await waitFor(() =>
    querySelectorDeep(document.body, containerSelector)
  );

  const trigger = container.querySelector('button.slds-combobox__input');
  trigger.click();

  const dropdown = await waitFor(() =>
    document.querySelector('.slds-dropdown.slds-is-open')
  );

  const option = Array.from(dropdown.querySelectorAll('lightning-base-combobox-item'))
    .find(el => el.textContent.trim() === targetValue);

  option.click();
}
```

---

## Debugging Patterns

### Comprehensive Element Dump

```javascript
function dumpAllElements(selector = 'input') {
  const elements = querySelectorDeep(document.body, selector);
  console.table(elements.map((el, idx) => ({
    index: idx,
    tag: el.tagName.toLowerCase(),
    type: el.type,
    id: el.id,
    class: el.className,
    placeholder: el.placeholder,
    'aria-label': el.getAttribute('aria-label'),
    visible: el.offsetParent !== null,
    inShadow: el.getRootNode() !== document,
    shadowHost: el.getRootNode().host?.tagName
  })));
}

// Usage in console
dumpAllElements('input');
```

### Test if Shadow DOM is Accessible

```javascript
function testShadowDOMAccess() {
  const shadowHosts = Array.from(document.querySelectorAll('*'))
    .filter(el => el.shadowRoot);

  console.log(`Found ${shadowHosts.length} shadow DOM hosts:`);
  shadowHosts.forEach(host => {
    console.log(`  ${host.tagName}:`, {
      mode: host.shadowRoot.mode,
      accessible: !!host.shadowRoot
    });
  });
}
```

---

## Common Pitfalls to Avoid

### ❌ **DON'T: Query once without waiting**
```javascript
// BAD
const button = document.querySelector('.my-button');
button.click(); // May be null!
```

### ✅ **DO: Always use waitFor**
```javascript
// GOOD
const button = await waitFor(() => document.querySelector('.my-button'));
if (!button) throw new Error('Button not found');
button.click();
```

---

### ❌ **DON'T: Assume standard DOM selectors work**
```javascript
// BAD - misses shadow DOM
const input = document.querySelector('input[type="search"]');
```

### ✅ **DO: Check shadow DOM too**
```javascript
// GOOD
const input = findInputDeep(inp => inp.type === 'search' && inp.offsetParent !== null);
```

---

### ❌ **DON'T: Use simple event dispatch for shadow DOM**
```javascript
// BAD - won't cross shadow boundary
element.dispatchEvent(new InputEvent('input', {bubbles: true}));
```

### ✅ **DO: Use composed: true**
```javascript
// GOOD
element.dispatchEvent(new InputEvent('input', {
  bubbles: true,
  composed: true // Crosses shadow boundaries
}));
```

---

### ❌ **DON'T: Assume elements stay in DOM**
```javascript
// BAD
const button = document.getElementById('my-btn');
// Later (after SPA navigation)...
button.click(); // May be detached/removed!
```

### ✅ **DO: Re-query when needed**
```javascript
// GOOD
function getButton() {
  return document.getElementById('my-btn');
}

// Later...
const button = getButton();
if (button) button.click();
```

---

## Script Structure Template

```javascript
(function() {
  'use strict';

  // ============ CONFIGURATION ============
  const CONFIG = {
    RETRY_INTERVAL: 500,
    MAX_RETRIES: 40,
    WAIT_TIMEOUT: 12000
  };

  // ============ UTILITIES ============
  const sleep = (ms) => new Promise(r => setTimeout(r, ms));

  function waitFor(fn, timeout = CONFIG.WAIT_TIMEOUT, interval = 150) {
    // ... implementation
  }

  function querySelectorDeep(root, selector) {
    // ... implementation
  }

  // ============ MAIN LOGIC ============
  async function initialize() {
    // Wait for app to load
    await waitFor(() => document.querySelector('.app-loaded-indicator'));

    // Inject UI
    injectButtons();

    // Monitor for changes
    observeDOM(() => injectButtons());
    observeRouteChanges(() => injectButtons());
  }

  function injectButtons() {
    if (document.getElementById('my-custom-btn')) return;

    const targetContainer = waitFor(() =>
      querySelectorDeep(document.body, '.target-container')
    );

    if (!targetContainer) return;

    const btn = document.createElement('button');
    btn.id = 'my-custom-btn';
    btn.addEventListener('click', handleButtonClick);
    targetContainer.appendChild(btn);
  }

  async function handleButtonClick() {
    try {
      // Workflow implementation
    } catch (e) {
      console.error('Error:', e);
      alert(`Error: ${e.message}`);
    }
  }

  // ============ BOOT ============
  if (!window.__myScript_loaded__) {
    window.__myScript_loaded__ = true;
    initialize();
  }
})();
```

---

## Testing Checklist

Before deploying a userscript, verify:

- [ ] Works with shadow DOM elements
- [ ] Handles dynamic rendering (elements load after delay)
- [ ] Survives SPA navigation (re-injects UI)
- [ ] Uses `composed: true` for events
- [ ] Has comprehensive error handling
- [ ] Logs useful debugging info
- [ ] Doesn't break on missing elements (null checks)
- [ ] Uses waitFor for all critical elements
- [ ] Includes retry logic for timing-sensitive operations

---

## Resources

- [Shadow DOM v1 Spec](https://developers.google.com/web/fundamentals/web-components/shadowdom)
- [Salesforce Lightning Web Components](https://developer.salesforce.com/docs/component-library/overview/components)
- [Tampermonkey Documentation](https://www.tampermonkey.net/documentation.php)

---

## Development Commands

```bash
# View console logs in browser DevTools
# Filter by: [YourScriptTag]

# Test shadow DOM access in console:
testShadowDOMAccess()

# Dump all inputs:
dumpAllElements('input')

# Find specific element:
querySelectorDeep(document.body, 'button.my-class')
```
