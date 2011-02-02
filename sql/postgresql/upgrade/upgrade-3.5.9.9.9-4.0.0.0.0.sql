-- upgrade-3.5.9.9.9-4.0.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-expenses/sql/postgresql/upgrade/upgrade-3.5.9.9.9-4.0.0.0.0.sql','');



-- Create privilege for creating expense bundles
select acs_privilege__create_privilege('add_expense_bundle','Add Expense Bundle','Add Expense Bundle');
select acs_privilege__add_child('admin', 'add_expense_bundle');
select im_priv_create('add_expense_bundle','Employees');


