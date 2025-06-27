// ChronoGuard Chrome Extension Popup Script

class ChronoGuardPopup {
  constructor() {
    this.statusIndicator = document.getElementById('statusIndicator');
    this.statusText = document.getElementById('statusText');
    this.currentTitle = document.getElementById('currentTitle');
    this.currentUrl = document.getElementById('currentUrl');
    this.stats = document.getElementById('stats');
    
    this.setupEventListeners();
    this.loadCurrentState();
  }

  setupEventListeners() {
    document.getElementById('openApp').addEventListener('click', () => {
      this.openNativeApp();
    });

    document.getElementById('viewReports').addEventListener('click', () => {
      this.openReports();
    });
  }

  async loadCurrentState() {
    try {
      // Get current tab info
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      if (tab) {
        this.updateCurrentTab(tab);
      }

      // Get connection status from background script
      const response = await chrome.runtime.sendMessage({ type: 'get_status' });
      if (response) {
        this.updateStatus(response.connected);
      } else {
        // Fallback: try to access background script directly
        const background = await this.getBackgroundScript();
        if (background && background.chronoGuard) {
          this.updateStatus(background.chronoGuard.getConnectionStatus());
          const currentTab = background.chronoGuard.getCurrentTabInfo();
          if (currentTab) {
            this.updateCurrentTab(currentTab);
          }
        }
      }
    } catch (error) {
      console.error('Error loading current state:', error);
      this.updateStatus(false);
    }
  }

  async getBackgroundScript() {
    return new Promise((resolve) => {
      chrome.runtime.getBackgroundPage((backgroundPage) => {
        resolve(backgroundPage);
      });
    });
  }

  updateStatus(isConnected) {
    if (isConnected) {
      this.statusIndicator.className = 'status-indicator connected';
      this.statusText.textContent = 'Connected to ChronoGuard';
      this.stats.textContent = 'Extension active • Tracking enabled • Privacy protected';
    } else {
      this.statusIndicator.className = 'status-indicator disconnected';
      this.statusText.textContent = 'Not connected to app';
      this.stats.textContent = 'Install ChronoGuard app for full functionality';
    }
  }

  updateCurrentTab(tab) {
    if (tab.title) {
      this.currentTitle.textContent = tab.title.length > 50 ? 
        tab.title.substring(0, 50) + '...' : tab.title;
    }

    if (tab.url) {
      try {
        const url = new URL(tab.url);
        this.currentUrl.textContent = `${url.hostname}${url.pathname}`;
      } catch {
        this.currentUrl.textContent = tab.url;
      }
    }
  }

  openNativeApp() {
    // Try to communicate with native app to bring it to foreground
    chrome.runtime.sendMessage({
      type: 'open_app'
    });

    // Also try to open via custom URL scheme (if implemented)
    chrome.tabs.create({
      url: 'chronoguard://open',
      active: false
    }).catch(() => {
      // Fallback: show installation instructions
      this.showInstallationInstructions();
    });
  }

  openReports() {
    // Try to open reports in the native app
    chrome.runtime.sendMessage({
      type: 'open_reports'
    });

    // Fallback: could open a local web interface if implemented
    chrome.tabs.create({
      url: 'http://localhost:9173/reports',
      active: true
    }).catch(() => {
      // Show message about app not running
      this.showAppNotRunningMessage();
    });
  }

  showInstallationInstructions() {
    const newWindow = window.open('', '_blank', 'width=500,height=400');
    newWindow.document.write(`
      <html>
        <head><title>Install ChronoGuard</title></head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 20px;">
          <h2>ChronoGuard App Required</h2>
          <p>To use this extension, you need to install the ChronoGuard macOS app.</p>
          <h3>Installation Steps:</h3>
          <ol>
            <li>Download ChronoGuard from the official website</li>
            <li>Install and run the app</li>
            <li>Grant required permissions when prompted</li>
            <li>The extension will automatically connect</li>
          </ol>
          <p><strong>Privacy Note:</strong> All data stays on your device. No cloud sync.</p>
        </body>
      </html>
    `);
  }

  showAppNotRunningMessage() {
    alert('ChronoGuard app is not running. Please start the app to view reports.');
  }

  // Utility function to format time
  formatTime(timestamp) {
    return new Date(timestamp).toLocaleTimeString();
  }

  // Utility function to sanitize URLs for display
  sanitizeUrl(url) {
    try {
      const urlObj = new URL(url);
      return `${urlObj.hostname}${urlObj.pathname}`;
    } catch {
      return url;
    }
  }
}

// Initialize popup when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  new ChronoGuardPopup();
});