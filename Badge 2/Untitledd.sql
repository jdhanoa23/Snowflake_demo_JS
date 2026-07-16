-- Query to find AUTO_DATA_UNLIMITED account details from org-level views
-- Co-authored with CoCo

USE ROLE ORGADMIN;

-- The ORGANIZATION_USAGE.USERS view does not exist in this account.
-- Use SHOW ACCOUNTS to find account info:
SHOW ACCOUNTS;

-- To find the admin username, check the account creation history:
-- (The username was set in the ADMIN_NAME parameter during CREATE ACCOUNT)
-- If you've lost it, you can recreate the account:
/*
DROP ACCOUNT AUTO_DATA_UNLIMITED;

CREATE ACCOUNT AUTO_DATA_UNLIMITED
  ADMIN_NAME = 'JSINGH26'
  ADMIN_PASSWORD = 'YourSecurePassword123!'
  EMAIL = 'your.email@company.com'
  EDITION = STANDARD
  REGION = 'AZURE_AUSTRALIAEAST';
*/
