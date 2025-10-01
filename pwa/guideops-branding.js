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
    
    // Function to add GuideOps branding to various elements
    function addGuideOpsBranding() {
        replaceSignInText();
        
        // Also check for any "Open WebUI" text and optionally replace
        const elements = document.querySelectorAll('*');
        elements.forEach(el => {
            if (el.childNodes.length === 1 && 
                el.childNodes[0].nodeType === Node.TEXT_NODE && 
                el.textContent.trim() === 'Open WebUI') {
                el.textContent = 'GuideOps';
                console.log('GuideOps: Replaced Open WebUI branding');
            }
        });
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
