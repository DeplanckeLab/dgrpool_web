
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

window.refresh = function(container, url, h){

 $.ajax({
  url: url,
  type: "get",
  dataType: "html",
  beforeSend: function(){
      if (h.loading){
          $("#" + container).html("<div style='vertical-align:middle;text-align:center'><i class='fa fa-spinner fa-pulse fa-fw fa-lg " + h.loading + "'></i></div>")
      }
  },
  success: function(returnData){
   var div= $("#" + container);
      if (container){
          if (!h['step_id'] || $("li#step_" + h['step_id']).hasClass('active')){
              div.empty()
              div.html(returnData);
          }
      }else{
          eval(returnData)
      }
  },
  error: function(e){

  }
 });

}

window.refresh_post = function(container, url, data, method, h){
 //console.log(container, url, data)                                                                                                                 \
                                                                                                                                                      
if (h.redirect === undefined){
h.redirect = false
}
if (h.multipart === undefined){
h.multipart = false
}
    var h2 = {
        url: url,
        type: method,
        dataType: "html",
        data: data,
        beforeSend: function(xhr){
	    xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
            if (h.loading){
                $("#" + container).html("<div class='loading'><i class='fa fa-spinner fa-pulse fa-fw fa-lg " + h.loading + "'></i></div>")
            }
        },
        success: function(returnData){
            if (container){
                if (h.redirect == false){
                    var div= $("#" + container);
                    div.empty()
                    div.html(returnData);
                }else{
                    eval(returnData)
                }
            }else{
                eval(returnData)
            }
        },
        error: function(e){
        }
    }

    if (h.multipart == true){
        h.processData = false;
        h.contentType = false;
    }
    $.ajax(h2);

}
