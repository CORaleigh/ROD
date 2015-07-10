
### Development Plans  

used by Justin Greco internally - data is pulled from Iris, pushed to Socrata, and Justin consumes the Socrata endpoint.

This script uses an SQL Query to pull all development plan data from IRIS, modifies datetime fields, modifies integers (from strings) and pushes it up to Socrata.
 A CRON job runs dev_plan.sh daily Monday - Friday to update the data set.

To run manually, cd app/dev_plan - must be on OakTree or connected via VPN
> _ruby plans.rb_


[Dev Plans data set on Socrata](https://data.raleighnc.gov/dataset/Dev-Plans/hyba-m4ki)
