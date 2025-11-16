// GuideOps Branding Script
// Customizes Open WebUI interface with GuideOps branding

(function() {
    'use strict';
    
    // Function to replace sign-in text
    function replaceSignInText() {
        // Find all headings and check their text content
        const headings = document.querySelectorAll('h1, h2, h3, .text-2xl, .text-xl, .text-lg');
        
        headings.forEach(heading => {
            const text = heading.textContent.trim();
            // Match "Sign in" exactly or as part of "Sign in to..."
            if (text.toLowerCase() === 'sign in' || 
                text.toLowerCase().startsWith('sign in to')) {
                // Don't modify if already changed
                if (!text.includes('GuideOps')) {
                    heading.textContent = 'Sign in to GuideOps';
                    console.log('GuideOps: Updated sign-in text from:', text);
                }
            }
        });
    }
    
    // Function to replace Open WebUI branding in sidebar and other locations
    function replaceOpenWebUIText() {
        let replacementCount = 0;
        
        // Function to walk through all text nodes in the document
        function walkTextNodes(node) {
            if (node.nodeType === Node.TEXT_NODE) {
                const text = node.textContent.trim();
                if (text === 'Open WebUI') {
                    node.textContent = 'GuideOps';
                    replacementCount++;
                    console.log('GuideOps: Replaced "Open WebUI" text node in:', node.parentElement?.tagName);
                }
            } else {
                // Recursively walk child nodes
                for (let i = 0; i < node.childNodes.length; i++) {
                    walkTextNodes(node.childNodes[i]);
                }
            }
        }
        
        // Start walking from document body
        if (document.body) {
            walkTextNodes(document.body);
        }
        
        // Also specifically target common elements
        const commonSelectors = [
            'a[href="/"]',
            'a[href="/workspace"]',
            '.sidebar-header',
            '[class*="sidebar"]',
            'button',
            'div[class*="text"]',
            'span',
            'p'
        ];
        
        commonSelectors.forEach(selector => {
            try {
                const elements = document.querySelectorAll(selector);
                elements.forEach(el => {
                    // Check direct text content
                    if (el.childNodes.length === 1 && 
                        el.childNodes[0].nodeType === Node.TEXT_NODE &&
                        el.textContent.trim() === 'Open WebUI') {
                        el.textContent = 'GuideOps';
                        replacementCount++;
                        console.log('GuideOps: Replaced "Open WebUI" in', selector);
                    }
                });
            } catch (e) {
                // Silently catch invalid selectors
            }
        });
        
        if (replacementCount > 0) {
            console.log(`GuideOps: Made ${replacementCount} replacements this cycle`);
        }
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
    } else {
        // DOM already loaded, run again
        setTimeout(addGuideOpsBranding, 100);
    }
    
    // Run periodically to catch dynamically loaded content (more frequently)
    setInterval(addGuideOpsBranding, 500);
    
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
