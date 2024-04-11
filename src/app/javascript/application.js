// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

import * as bootstrap from "bootstrap"
import "@popperjs/core"

// Import $ for jQuery operations
import './src/jquery'

console.log("jQuery version: " + $.fn.jquery); // Log jQuery version           

import 'datatables.net' 

//import './src/jquery-ui'
//import './src/jquery.ui.autocomplete.html'

/*import 'datatables.net'
import './src/custom'
import './src/tooltipster'
import 'plotly.js-dist/plotly'

window.initTooltips = function(){
   var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
  return new bootstrap.Tooltip(tooltipTriggerEl)
    })
}

document.addEventListener('DOMContentLoaded', function () {
    initTooltips();
})

window.downloadFullHtml = function(el_to_download) {
    // Create a new HTML document
    var newHtmlDocument = document.implementation.createHTMLDocument();
    
    // Clone the head content of the current document to the new document
    newHtmlDocument.head.innerHTML = document.head.innerHTML;
    
    // Clone the content you want to download to the new document
    newHtmlDocument.body.innerHTML = document.getElementById(el_to_download).outerHTML;
    
    // Get the entire HTML content of the new document
    var fullHtml = newHtmlDocument.documentElement.outerHTML;
    
    // Create a Blob containing the entire HTML content
    var blob = new Blob([fullHtml], { type: 'text/html' });
    
    // Create a temporary URL for the Blob
    var url = URL.createObjectURL(blob);
    
    // Create a link element
            var link = document.createElement('a');
    
    // Set the href attribute of the link to the temporary URL
    link.href = url;
    
    // Set the download attribute with the desired filename
    link.download = 'full_content.html';
    
    // Append the link to the document
    document.body.appendChild(link);
    
    // Trigger a click on the link to start the download
    link.click();
    
    // Remove the link from the document
    document.body.removeChild(link);
    
            // Release the temporary URL
    URL.revokeObjectURL(url);
}
*/
//function initTooltips() {
/*
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
  return new bootstrap.Tooltip(tooltipTriggerEl)
  })
  */
//}

/*$(document).on('ajax:success', function() {
  initTooltips();
});
*/


/*document.addEventListener('DOMContentLoaded', function () {
    initTooltips();
});

*/
/*document.addEventListener('DOMContentLoaded', function () {   
$('.tooltip').tooltipster();
})
*/
