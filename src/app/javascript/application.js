// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

import * as bootstrap from "bootstrap"
import "@popperjs/core"

// Import $ for jQuery operations
import './src/jquery'

console.log("jQuery version: " + $.fn.jquery); // Log jQuery version           

import 'datatables.net' 
import './src/jquery-ui'
import './src/jquery.ui.autocomplete.html'

//import './src/tooltipster'
import "bootstrap-tooltip"

import './src/custom'                              


/*import 'datatables.net'
import './src/custom'
import './src/tooltipster'
import 'plotly.js-dist/plotly'
*/

