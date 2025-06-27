// ChronoGuard Chrome Extension Background Script
// Handles tab monitoring and native messaging to macOS app

class ChronoGuardExtension {
  constructor() {
    this.port = null;
    this.isConnected = false;
    this.currentTabInfo = null;
    this.setupEventListeners();
    this.connectToNativeApp();
  }

  setupEventListeners() {
    // Tab activation changes
    chrome.tabs.onActivated.addListener((activeInfo) => {
      this.handleTabActivation(activeInfo);
    });

    // Tab updates (URL changes, page loads)
    chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
      if (changeInfo.status === 'complete' && tab.active) {
        this.handleTabUpdate(tab);
      }
    });

    // Window focus changes
    chrome.windows.onFocusChanged.addListener((windowId) => {
      if (windowId !== chrome.windows.WINDOW_ID_NONE) {
        this.handleWindowFocus(windowId);
      }
    });

    // Extension startup
    chrome.runtime.onStartup.addListener(() => {
      this.connectToNativeApp();
    });

    // Extension installed/enabled
    chrome.runtime.onInstalled.addListener(() => {
      this.connectToNativeApp();
    });
  }

  connectToNativeApp() {
    try {
      this.port = chrome.runtime.connectNative('com.chronoguard.native');
      
      this.port.onMessage.addListener((message) => {
        console.log('Received from native app:', message);
      });

      this.port.onDisconnect.addListener(() => {
        console.log('Disconnected from native app');
        this.isConnected = false;
        this.port = null;
        
        // Attempt to reconnect after 5 seconds
        setTimeout(() => {
          this.connectToNativeApp();
        }, 5000);
      });

      this.isConnected = true;
      console.log('Connected to ChronoGuard native app');
      
      // Send initial connection message
      this.sendToNativeApp({
        type: 'connection',
        message: 'Chrome extension connected',
        timestamp: Date.now()
      });

    } catch (error) {
      console.error('Failed to connect to native app:', error);
      this.isConnected = false;
    }
  }

  sendToNativeApp(data) {
    if (this.isConnected && this.port) {
      try {
        this.port.postMessage(data);
      } catch (error) {
        console.error('Failed to send message to native app:', error);
        this.isConnected = false;
      }
    }
  }

  async handleTabActivation(activeInfo) {
    try {
      const tab = await chrome.tabs.get(activeInfo.tabId);
      this.processTabInfo(tab);
    } catch (error) {
      console.error('Error handling tab activation:', error);
    }
  }

  handleTabUpdate(tab) {
    if (tab.active) {
      this.processTabInfo(tab);
    }
  }

  async handleWindowFocus(windowId) {
    try {
      const tabs = await chrome.tabs.query({ active: true, windowId: windowId });
      if (tabs.length > 0) {
        this.processTabInfo(tabs[0]);
      }
    } catch (error) {
      console.error('Error handling window focus:', error);
    }
  }

  processTabInfo(tab) {
    if (!tab || !tab.url) return;

    // Filter out chrome:// and extension pages
    if (tab.url.startsWith('chrome://') || 
        tab.url.startsWith('chrome-extension://') ||
        tab.url.startsWith('moz-extension://')) {
      return;
    }

    const tabInfo = {
      type: 'tab_activity',
      url: tab.url,
      title: tab.title || 'Untitled',
      favIconUrl: tab.favIconUrl,
      timestamp: Date.now(),
      tabId: tab.id,
      windowId: tab.windowId
    };

    // Only send if the tab info has changed
    if (!this.currentTabInfo || 
        this.currentTabInfo.url !== tabInfo.url || 
        this.currentTabInfo.title !== tabInfo.title) {
      
      this.currentTabInfo = tabInfo;
      this.sendToNativeApp(tabInfo);
      
      console.log('Tab activity:', tabInfo.title, '-', this.sanitizeUrl(tabInfo.url));
    }
  }

  sanitizeUrl(url) {
    try {
      const urlObj = new URL(url);
      return `${urlObj.protocol}//${urlObj.hostname}${urlObj.pathname}`;
    } catch {
      return url;
    }
  }

  // Public API for popup/content scripts
  getCurrentTabInfo() {
    return this.currentTabInfo;
  }

  getConnectionStatus() {
    return this.isConnected;
  }
}

// Initialize the extension
const chronoGuard = new ChronoGuardExtension();

// Expose for popup access
globalThis.chronoGuard = chronoGuard;