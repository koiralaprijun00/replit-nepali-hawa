// Icon generation script for Nepal Air Quality Monitor PWA
// This creates SVG icons that can be converted to different sizes

import fs from 'fs';

// Create simple SVG icons for the PWA
const mainIcon = `
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#3b82f6;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#1d4ed8;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <!-- Background circle -->
  <circle cx="256" cy="256" r="240" fill="url(#bg)"/>
  
  <!-- Mountain silhouette (Nepal reference) -->
  <path d="M50 350 L120 280 L180 300 L250 220 L320 260 L380 200 L450 240 L500 300 L500 450 L50 450 Z" 
        fill="rgba(255,255,255,0.2)"/>
  
  <!-- Air quality circles (representing air particles) -->
  <circle cx="200" cy="180" r="8" fill="rgba(255,255,255,0.8)"/>
  <circle cx="280" cy="160" r="6" fill="rgba(255,255,255,0.6)"/>
  <circle cx="320" cy="200" r="4" fill="rgba(255,255,255,0.4)"/>
  <circle cx="180" cy="220" r="5" fill="rgba(255,255,255,0.7)"/>
  
  <!-- Wind lines -->
  <path d="M100 150 Q140 160 180 150" stroke="rgba(255,255,255,0.6)" stroke-width="3" fill="none"/>
  <path d="M300 180 Q340 190 380 180" stroke="rgba(255,255,255,0.6)" stroke-width="3" fill="none"/>
  
  <!-- AQI text -->
  <text x="256" y="320" text-anchor="middle" font-family="Arial, sans-serif" 
        font-size="48" font-weight="bold" fill="white">AQI</text>
  
  <!-- Nepal text -->
  <text x="256" y="370" text-anchor="middle" font-family="Arial, sans-serif" 
        font-size="24" fill="rgba(255,255,255,0.9)">NEPAL</text>
</svg>
`;

const maskableIcon = `
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#3b82f6;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#1d4ed8;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <!-- Full background (for maskable) -->
  <rect width="512" height="512" fill="url(#bg)"/>
  
  <!-- Centered content within safe area -->
  <g transform="translate(128, 128)">
    <!-- Mountain silhouette -->
    <path d="M20 150 L70 100 L110 115 L150 60 L190 85 L230 40 L270 70 L300 100 L300 200 L20 200 Z" 
          fill="rgba(255,255,255,0.2)"/>
    
    <!-- Air particles -->
    <circle cx="100" cy="80" r="6" fill="rgba(255,255,255,0.8)"/>
    <circle cx="150" cy="70" r="4" fill="rgba(255,255,255,0.6)"/>
    <circle cx="180" cy="90" r="3" fill="rgba(255,255,255,0.4)"/>
    
    <!-- AQI text centered -->
    <text x="128" y="140" text-anchor="middle" font-family="Arial, sans-serif" 
          font-size="32" font-weight="bold" fill="white">AQI</text>
    <text x="128" y="170" text-anchor="middle" font-family="Arial, sans-serif" 
          font-size="16" fill="rgba(255,255,255,0.9)">NEPAL</text>
  </g>
</svg>
`;

const currentLocationIcon = `
<svg width="192" height="192" viewBox="0 0 192 192" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="loc-bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#10b981;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#059669;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <circle cx="96" cy="96" r="80" fill="url(#loc-bg)"/>
  
  <!-- Location pin -->
  <path d="M96 50 C110 50 120 60 120 74 C120 88 96 120 96 120 S72 88 72 74 C72 60 82 50 96 50 Z" 
        fill="white"/>
  <circle cx="96" cy="74" r="8" fill="url(#loc-bg)"/>
  
  <!-- Target rings -->
  <circle cx="96" cy="96" r="35" stroke="rgba(255,255,255,0.4)" stroke-width="2" fill="none"/>
  <circle cx="96" cy="96" r="25" stroke="rgba(255,255,255,0.6)" stroke-width="2" fill="none"/>
</svg>
`;

const mapIcon = `
<svg width="192" height="192" viewBox="0 0 192 192" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="map-bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#8b5cf6;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#7c3aed;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <circle cx="96" cy="96" r="80" fill="url(#map-bg)"/>
  
  <!-- Map grid -->
  <g stroke="rgba(255,255,255,0.3)" stroke-width="1.5" fill="none">
    <line x1="40" y1="60" x2="152" y2="60"/>
    <line x1="40" y1="90" x2="152" y2="90"/>
    <line x1="40" y1="120" x2="152" y2="120"/>
    <line x1="60" y1="40" x2="60" y2="152"/>
    <line x1="90" y1="40" x2="90" y2="152"/>
    <line x1="120" y1="40" x2="120" y2="152"/>
  </g>
  
  <!-- Location markers -->
  <circle cx="75" cy="75" r="4" fill="#ef4444"/>
  <circle cx="110" cy="85" r="4" fill="#f59e0b"/>
  <circle cx="85" cy="110" r="4" fill="#10b981"/>
  <circle cx="125" cy="105" r="4" fill="#ef4444"/>
</svg>
`;

const rankingsIcon = `
<svg width="192" height="192" viewBox="0 0 192 192" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="trophy-bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#f59e0b;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#d97706;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <circle cx="96" cy="96" r="80" fill="url(#trophy-bg)"/>
  
  <!-- Trophy -->
  <path d="M70 60 L122 60 L122 80 C122 95 110 105 96 105 S70 95 70 80 Z" fill="white"/>
  <rect x="88" y="105" width="16" height="20" fill="white"/>
  <rect x="75" y="125" width="42" height="8" fill="white"/>
  
  <!-- Trophy handles -->
  <path d="M70 70 Q55 70 55 80 Q55 90 70 90" stroke="white" stroke-width="3" fill="none"/>
  <path d="M122 70 Q137 70 137 80 Q137 90 122 90" stroke="white" stroke-width="3" fill="none"/>
  
  <!-- Rankings bars -->
  <rect x="60" y="45" width="8" height="15" fill="rgba(255,255,255,0.6)"/>
  <rect x="75" y="40" width="8" height="20" fill="rgba(255,255,255,0.8)"/>
  <rect x="90" y="35" width="8" height="25" fill="white"/>
  <rect x="105" y="40" width="8" height="20" fill="rgba(255,255,255,0.8)"/>
  <rect x="120" y="45" width="8" height="15" fill="rgba(255,255,255,0.6)"/>
</svg>
`;

// Write the SVG files
if (!fs.existsSync('public')) {
  fs.mkdirSync('public');
}

fs.writeFileSync('public/icon.svg', mainIcon);
fs.writeFileSync('public/icon-maskable.svg', maskableIcon);
fs.writeFileSync('public/icon-current-location.svg', currentLocationIcon);
fs.writeFileSync('public/icon-map.svg', mapIcon);
fs.writeFileSync('public/icon-rankings.svg', rankingsIcon);

console.log('SVG icons generated successfully!');
console.log('To convert to PNG, use a tool like imagemagick:');
console.log('convert icon.svg -resize 512x512 icon-512.png');