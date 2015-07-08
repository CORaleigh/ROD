<div style="color:black;text-align:center;background:orange;padding:8px;font-size:21px;border-radius: 25px;width:40%">
<b>Development Plans</b>
</div>
This script uses an SQL Query to pull all development plan data from IRIS, modifies datetime fields, modifies integers (from strings) and truncates to 2 decimal places. and pushes it up to Socrata. A CRON job runs dev_plan.sh daily Monday - Friday to update the data set.

To run manually, cd app/dev_plan - must be on OakTree or connected via VPN
> _ruby plans.rb_


[Dev Plans data set on Socrata](https://data.raleighnc.gov/dataset/Dev-Plans/hyba-m4ki)