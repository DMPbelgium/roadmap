import { renderAlert,renderNotice } from '../../utils/notificationHelper';

$(() => {

  $("form.form-role-update-contributor")
      .on("ajax:success", function(e){
        const data = e.detail[0];console.log("ajax:success");
        renderNotice(data.msg);
      })
      .on("ajax:error", function(e){
        const xhr = e.detail[2];console.log("ajax:error");
        if(typeof xhr.responseJSON == "object"){
          renderAlert(xhr.responseJSON.msg);
        } else {
          renderAlert(`${xhr.statusCode} - ${xhr.statusText}`);
        }
      });

    $(".checkbox-role-update-contributor")
      .on("change", function(){
        $(this.form).find('input[type=submit]')
                    .trigger("click");
      });
});
