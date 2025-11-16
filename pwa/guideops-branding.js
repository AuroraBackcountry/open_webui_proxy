// GuideOps Branding Script
// Customizes Open WebUI interface with GuideOps branding

(function() {
    'use strict';
    
    // Function to replace sign-in text
    function replaceSignInText() {
        // Common selectors for sign-in headings
        const selectors = [
            'h1:contains("Sign in")',
            '.text-2xl:contains("Sign in")',
            '[data-testid="signin-form"] h1',
            '.auth-form h1',
            'form h1'
        ];
        
        // Find all headings and check their text content
        const headings = document.querySelectorAll('h1, h2, .text-2xl, .text-xl');
        
        headings.forEach(heading => {
            if (heading.textContent && heading.textContent.trim().toLowerCase().includes('sign in')) {
                // Don't modify if already changed
                if (!heading.textContent.includes('GuideOps')) {
                    heading.textContent = 'Sign in to GuideOps';
                    console.log('GuideOps: Updated sign-in text');
                }
            }
        });
    }
    
    // Function to replace Open WebUI branding in sidebar and other locations
    function replaceOpenWebUIText() {
        // Target common locations where "Open WebUI" appears
        const selectors = [
            // Sidebar header/title
            'div[class*="flex"] > div:not([class*="hidden"])',
            'a[href="/"]',
            'header',
            '.sidebar',
            // Any text node containing "Open WebUI"
        ];
        
        // Check all text nodes for "Open WebUI"
        const elements = document.querySelectorAll('*');
        elements.forEach(el => {
            // Only process elements with direct text content (not nested)
            if (el.childNodes.length === 1 && 
                el.childNodes[0].nodeType === Node.TEXT_NODE) {
                const text = el.textContent.trim();
                if (text === 'Open WebUI') {
                    el.textContent = 'GuideOps';
                    console.log('GuideOps: Replaced "Open WebUI" with "GuideOps" in', el.tagName);
                }
            }
            
            // Also check for elements that might contain "Open WebUI" with child nodes
            el.childNodes.forEach(node => {
                if (node.nodeType === Node.TEXT_NODE && 
                    node.textContent.trim() === 'Open WebUI') {
                    node.textContent = 'GuideOps';
                    console.log('GuideOps: Replaced "Open WebUI" text node');
                }
            });
        });
    }
    
    // Function to add GuideOps branding to various elements
    function addGuideOpsBranding() {
        replaceSignInText();
        replaceOpenWebUIText();
    }
    
    // Run immediately
    addGuideOpsBranding();
    
    // Run when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', addGuideOpsBranding);
    }
    
    // Run periodically to catch dynamically loaded content
    setInterval(addGuideOpsBranding, 1000);
    
    // Watch for DOM changes (for SPA navigation)
    if (window.MutationObserver) {
        const observer = new MutationObserver(function(mutations) {
            let shouldUpdate = false;
            mutations.forEach(function(mutation) {
                if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
                    shouldUpdate = true;
                }
            });
            if (shouldUpdate) {
                setTimeout(addGuideOpsBranding, 100);
            }
        });
        
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }
    
    console.log('GuideOps branding script loaded');
})();
