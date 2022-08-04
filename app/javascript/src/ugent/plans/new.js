import debounce from '../../utils/debounce';
import getConstant from '../../utils/constants';
import { isObject, isArray, isString } from '../../utils/isType';
import { renderAlert, hideNotifications } from '../../utils/notificationHelper';

$(() => {
  const toggleSubmit = () => {
    const tmplt = $('#plan_template_id').find(':selected').val();
    if (isString(tmplt)) {
      $('#new_plan button[type="submit"]').removeAttr('disabled')
        .removeAttr('data-toggle').removeAttr('title');
    } else {
      $('#new_plan button[type="submit"]').attr('disabled', true)
        .attr('data-toggle', 'tooltip').attr('title', getConstant('NEW_PLAN_DISABLED_TOOLTIP'));
    }
  };

  // AJAX error function for available template search
  const error = () => {
    renderAlert(getConstant('NO_TEMPLATE_FOUND_ERROR'));
  };

  // AJAX success function for available template search
  const success = (data) => {
    hideNotifications();

    if (isObject(data)
        && isArray(data.templates)) {
      // Display the available_templates section
      if (data.templates.length > 0) {
        data.templates.forEach((t) => {
          $('#plan_template_id').append(`<option value="${t.id}">${t.title}</option>`);
        });
        // If there is only one template, set the input field value and submit the form
        // otherwise show the dropdown list and the 'Multiple templates found message'
        if (data.templates.length === 1) {
          $('#plan_template_id option').attr('selected', 'true');
          $('#multiple-templates').hide();
          $('#available-templates').fadeOut();
        } else {
          $('#multiple-templates').show();
          $('#available-templates').fadeIn();
        }
        toggleSubmit();
      } else {
        error();
      }
    }
  };

  // When one of the select fields changes, fetch the available templates
  const handleComboboxChange = debounce(() => {
    const orgId = $('#plan_org_id').val();
    const funderId = $('#plan_funder_id').val();

    // Clear out the old template dropdown contents
    $('#available-templates').hide();
    const planTemplateId = $('#plan_template_id');
    planTemplateId.find(':selected').removeAttr('selected');
    planTemplateId.val('');
    toggleSubmit();
    planTemplateId.find('option').remove();

    const data = {
      plan: {},
    };
    if (isString(orgId) && orgId.length > 0 && orgId !== '{}') {
      data.plan.research_org_id = JSON.parse(orgId);
    } else {
      data.plan.research_org_id = 'none';
    }
    if (isString(funderId) && funderId.length > 0 && funderId !== '{}') {
      data.plan.funder_id = JSON.parse(funderId);
    } else {
      data.plan.funder_id = 'none';
    }

    // Fetch the available templates based on the funder and research org selected
    const opts = {};
    opts.url = $('#template-option-target').val();
    opts.data = data;
    $.ajax(opts).done(success).fail(error);
  }, 150);

  const defaultVisibility = $('#plan_visibility').val();

  // When the user checks the 'mock project' box we need to set the
  // visibility to 'is_test'
  $('#new_plan #is_test').click((e) => {
    $('#plan_visibility').val(($(e.currentTarget)[0].checked ? 'is_test' : defaultVisibility));
  });

  $('#plan_org_id').on('change', handleComboboxChange);
  $('#plan_funder_id').on('change', handleComboboxChange);

  // When one of the checkboxes is clicked, disable the select is clear its contents
  $('#plan_no_org').on('change', (evt) => {
    if ($(evt.currentTarget).is(':checked')) {
      $('#plan_org_id').val('').attr('disabled', 'disabled').trigger('change');
    } else {
      $('#plan_org_id').val('').removeAttr('disabled').trigger('change');
    }
  });
  $('#plan_no_funder').on('change', (evt) => {
    if ($(evt.currentTarget).is(':checked')) {
      $('#plan_funder_id').val('').attr('disabled', 'disabled').trigger('change');
    } else {
      $('#plan_funder_id').val('').removeAttr('disabled').trigger('change');
    }
  });

  // Initialize the form
  $('#new_plan #available-templates').hide();
  handleComboboxChange();
  toggleSubmit();
});
