# /packages/intranet-expenses/www/expense-del.tcl
#
# Copyright (C) 2003-2004 Project/Open
# 060427 avila@digiteix.com
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------
ad_page_contract { 
    delete expenses

    @param project_id
           project on expense is going to create

    @author avila@digiteix.com
} {
    return_url
    expense_id:multiple
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

foreach id $expense_id {

    # delete expense
    # 
    db_transaction {
	db_string del_expense {}
    }
}

ad_returnredirect $return_url
