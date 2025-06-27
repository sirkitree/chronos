// ChronoGuard Chrome Extension Content Script
// Monitors page changes and user activity within web pages

class ChronoGuardContent {
  constructor() {
    this.lastActivity = Date.now();
    this.pageLoadTime = Date.now();
    this.setupActivityMonitoring();
    this.notifyPageLoad();
  }

  setupActivityMonitoring() {
    // Monitor user interactions
    const events = ['click', 'scroll', 'keypress', 'mousemove'];
    
    events.forEach(event => {
      document.addEventListener(event, () => {
        this.updateActivity();
      }, { passive: true });
    });

    // Monitor visibility changes
    document.addEventListener('visibilitychange', () => {
      this.handleVisibilityChange();
    });

    // Monitor hash changes (SPA navigation)
    window.addEventListener('hashchange', () => {
      this.notifyUrlChange();
    });

    // Monitor history changes (SPA navigation)
    const originalPushState = history.pushState;
    const originalReplaceState = history.replaceState;
    
    history.pushState = function(...args) {
      originalPushState.apply(history, args);
      setTimeout(() => chronoGuardContent.notifyUrlChange(), 100);
    };
    
    history.replaceState = function(...args) {
      originalReplaceState.apply(history, args);
      setTimeout(() => chronoGuardContent.notifyUrlChange(), 100);
    };

    // Periodic activity check
    setInterval(() => {
      this.checkActivity();
    }, 30000); // Every 30 seconds
  }

  updateActivity() {
    this.lastActivity = Date.now();
  }

  handleVisibilityChange() {
    const message = {
      type: 'page_visibility',
      url: window.location.href,
      title: document.title,
      visible: !document.hidden,
      timestamp: Date.now()
    };

    this.sendToBackground(message);
  }

  notifyPageLoad() {
    const message = {
      type: 'page_load',
      url: window.location.href,
      title: document.title,
      timestamp: this.pageLoadTime,
      userAgent: navigator.userAgent
    };

    this.sendToBackground(message);
  }

  notifyUrlChange() {
    const message = {
      type: 'url_change',
      url: window.location.href,
      title: document.title,
      timestamp: Date.now()
    };

    this.sendToBackground(message);
  }

  checkActivity() {
    const inactiveTime = Date.now() - this.lastActivity;
    const isActive = inactiveTime < 60000; // Active if activity within last minute

    const message = {
      type: 'activity_check',
      url: window.location.href,
      title: document.title,
      isActive: isActive,
      inactiveTime: inactiveTime,
      timestamp: Date.now()
    };

    this.sendToBackground(message);
  }

  sendToBackground(message) {
    try {
      chrome.runtime.sendMessage(message);
    } catch (error) {
      console.error('Failed to send message to background:', error);
    }
  }

  // Extract page metadata
  getPageMetadata() {
    const metadata = {
      title: document.title,
      url: window.location.href,
      domain: window.location.hostname,
      path: window.location.pathname,
      timestamp: Date.now()
    };

    // Try to get additional metadata
    try {
      const description = document.querySelector('meta[name="description"]');
      if (description) {
        metadata.description = description.getAttribute('content');
      }

      const keywords = document.querySelector('meta[name="keywords"]');
      if (keywords) {
        metadata.keywords = keywords.getAttribute('content');
      }

      // Get canonical URL if available
      const canonical = document.querySelector('link[rel="canonical"]');
      if (canonical) {
        metadata.canonicalUrl = canonical.getAttribute('href');
      }
    } catch (error) {
      // Ignore metadata extraction errors
    }

    return metadata;
  }
}

// Initialize content script
const chronoGuardContent = new ChronoGuardContent();

// Listen for messages from background script
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.type === 'get_page_metadata') {
    sendResponse(chronoGuardContent.getPageMetadata());
  }
  return true;
});