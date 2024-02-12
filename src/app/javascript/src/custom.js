
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
