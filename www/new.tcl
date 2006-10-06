# /packages/intranet-expenses/www/new.tcl
#
# Copyright (C) 2003-2006 Project/Open
# 060421 avila@digiteix.com
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------
ad_page_contract { 
    add / edit expense in project

    @param project_id
           project on expense is going to create

    @author avila@digiteix.com
} {
    { cost_type_id:integer "[im_cost_type_invoice]" }
    { project_id:integer "" }
    { return_url "/intranet-expenses/"}
    expense_id:integer,optional
    expense_amount:float,optional
    expense_date:optional
    {form_mode "edit"}
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id "add_expenses"]} {
    ad_return_complaint 1 "[_ intranet-timesheet2-invoices.lt_You_have_insufficient_1]"
    return
}

set today [lindex [split [ns_localsqltimestamp] " "] 0]
set page_title [lang::message::lookup "" intranet-expenses.New_Expense "New Expense Item"]
set context_bar [im_context_bar $page_title]

set currency_format [im_l10n_sql_currency_format]
set date_format [im_l10n_sql_date_format]
set percent_format "FM999"
set action_url "/intranet-expenses/new"


# ------------------------------------------------------------------
# Form Options
# ------------------------------------------------------------------

set expense_payment_type_options [db_list_of_lists payment_options "
	select	expense_payment_type,
		expense_payment_type_id
	from	im_expense_payment_type
	order by
		expense_payment_type_id
"]


# Get the list of active projects (both main and subprojects)
# where the current user is a direct member
# ToDo: This could give problems with Tasks. Maybe exclude
# tasks in the future?
#
set project_options [im_project_options \
	-exclude_subprojects_p 0 \
	-member_user_id $user_id \
	-project_id $project_id \
]

set include_empty 0
set currency_options [im_currency_options $include_empty]

set expense_type_options [db_list_of_lists expense_types "
	select	expense_type,
		expense_type_id
	from im_expense_type
"]


set include_empty 0
set currency_options [im_currency_options $include_empty]


set expense_type_options [db_list_of_lists expense_types "select expense_type, expense_type_id from im_expense_type"]
set expense_type_options [linsert $expense_type_options 0 [list [lang::message::lookup "" "intranet-expenses.--Select--" "-- Please Select --"] 0]]



set expense_payment_type_options [db_list_of_lists expense_payment_type "
	select	expense_payment_type,
		expense_payment_type_id
        from
		im_expense_payment_type
"]
set expense_payment_type_options [linsert $expense_payment_type_options 0 [list [lang::message::lookup "" "intranet-expenses.--Select--" "-- Please Select --"] 0]]




# ------------------------------------------------------------------
# Form defaults
# ------------------------------------------------------------------

# Default variables for "costs" (not really applicable)
set customer_id [im_company_internal]
set provider_id $user_id
set template_id ""
set payment_days "30"
set cost_status [im_cost_status_created]
set cost_type_id [im_cost_type_expense_item]
set tax "0"

if {![info exists reimbursable]} { set reimbursable 100 }
if {![info exists expense_date]} { set expense_date $today }
if {![info exists billable_p]} { set billable_p "f" }

if {![info exists expense_payment_type_id]} { 
    set expense_payment_type_id [im_expense_payment_type_cash]
}

if {![info exists currency]} { 
    set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"] 
}


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set form_id "expense_ae"
set focus "$form_id\.var_name"

ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {customer_id provider_id template_id payment_days cost_status cost_type_id tax return_url} \
    -form {
        expense_id:key
        {project_id:text(select),optional
	    {label "[lang::message::lookup {} intranet-expenses.Project Project]" } 
	    {options $project_options}
	}
	{expense_amount:text(text) {label "[_ intranet-expenses.Amount]"} {html {size 10}}}
	{currency:text(select) 
	    {label "[_ intranet-expenses.Currency]"}
	    {options $currency_options} 
	}
	{vat:text(text) {label "[_ intranet-expenses.Vat_Included]"} {html {size 6}}}
	{expense_date:text(text) {label "[_ intranet-expenses.Expense_Date]"} {html {size 10}}}
	{external_company_name:text(text) {label "[_ intranet-expenses.External_company_name]"} {html {size 40}}}
	{external_company_vat_number:text(text),optional {label "[lang::message::lookup {} intranet-expenses.External_Company_VatNr {External Company Vat Nr.}]"} {html {size 20}}}
	{receipt_reference:text(text),optional {label "[_ intranet-expenses.Receipt_reference]"} {html {size 40}}}
	{expense_type_id:text(select) 
	    {label "[_ intranet-expenses.Expense_Type]"}
	    {options $expense_type_options} 
	}
        {billable_p:text(radio) {label "[_ intranet-expenses.Billable_p]"} {options {{[_ intranet-core.Yes] t} {[_ intranet-core.No] f}}} }
	{reimbursable:text(text) {label "[_ intranet-expenses.reimbursable]"} { html {size 10}}}
	{expense_payment_type_id:text(select) 
	    {label "[_ intranet-expenses.Expense_Payment_Type]"}
	    {options $expense_payment_type_options} 
	}
        {note:text(textarea),optional {label "[lang::message::lookup {} intranet-expenses.Note Note]"} {html {cols 40}}}
    }


#    check conditions
#    if {![empty_string_p $vat]} {
#        if {0>$vat || 100<$vat} {
#            template::element::set_error $form_id vat "[_ intranet-expenses.vat_not_valid]"
#            incr n_errors
#        }
#    }

#    if {![empty_string_p $reimbursable]} {
#        if {0>$reimbursable || 100<$reimbursable} {
#            template::element::set_error $form_id reimbursable "[_ intranet-expenses.reimbursable_not_valid]"
#            incr n_errors
#        }
#    }



# ------------------------------------------------------------------
# Debug
# ------------------------------------------------------------------

set is_request [template::form::is_request $form_id]
set is_submission [template::form::is_submission $form_id]
set is_valid [template::form::is_valid $form_id]
set expense_id_exists [exists_and_not_null expense_id]

# ad_return_complaint 1 "r=$is_request, s=$is_submission, v=$is_valid, x=$expense_id_exists"


# ------------------------------------------------------------------
# Form Actions
# ------------------------------------------------------------------

ad_form -extend -name $form_id -on_request {

    # Populate elements from local variables

} -select_query {
    
	select	*,
		to_char(c.amount * (1 + c.vat / 100), :currency_format) as expense_amount,
		to_char(c.effective_date, :date_format) as expense_date,
		to_char(c.vat, :percent_format) as vat,
		to_char(e.reimbursable, :percent_format) as reimbursable
	from
		im_costs c,
		im_expenses e
	where
		c.cost_id = e.expense_id
		and c.cost_id = :expense_id

} -new_data {

    set amount [expr $expense_amount / [expr 1 + [expr $vat / 100.0]]]
    set expense_name $expense_id

    # Get the user's department as default CC
    set cost_center_id [db_string user_cc "
	select	department_id
	from	im_employees
	where	employee_id = :user_id
    " -default ""]
    
    db_exec_plsql create_expense {}
    
    db_dml update_costs "
	update im_costs set
	cost_center_id = :cost_center_id
	where cost_id = :expense_id
    "

} -edit_data {

    set amount [expr $expense_amount / [expr 1 + [expr $vat / 100.0]]]
    set expense_name $expense_id

    # Update the invoice itself
    db_dml update_expense "
	update im_expenses 
	set 
	        external_company_name = :external_company_name,
	        external_company_vat_number = :external_company_vat_number,
	        receipt_reference = :receipt_reference,
	        billable_p = :billable_p,
	        reimbursable = :reimbursable,
	        expense_payment_type_id = :expense_payment_type_id
	where
		expense_id = :expense_id
    "

    db_dml update_costs "
	update im_costs
	set
		project_id	= :project_id,
		cost_name	= :expense_name,
		customer_id	= :customer_id,
		cost_nr		= :expense_id,
	        cost_type_id    = :cost_type_id,
		provider_id	= :provider_id,
		template_id	= :template_id,
		effective_date	= to_timestamp(:expense_date, 'YYYY-MM-DD'),
		payment_days	= :payment_days,
		vat		= :vat,
		tax		= :tax,
		variable_cost_p = 't',
		amount		= :amount,
		currency	= :currency,
		note		= :note
	where
		cost_id = :expense_id
    "

} -on_submit {
    
    ns_log Notice "new1: on_submit"
    
} -after_submit {

    ad_returnredirect $return_url
    ad_script_abort
}




