
WITH FilteredCustomers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_email_address, cd_gender, cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd_gender = 'F' AND cd_marital_status = 'M'
),
AddressDetails AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_zip, ca_country
    FROM customer_address
    WHERE ca_state IN ('CA', 'TX')
),
PurchaseSummary AS (
    SELECT ss_customer_sk, SUM(ss_net_paid) AS total_spent, COUNT(ss_ticket_number) AS total_purchases
    FROM store_sales
    GROUP BY ss_customer_sk
),
EmailSummary AS (
    SELECT 
        CONCAT('Name: ', fc.c_first_name, ' ', fc.c_last_name, ' - Email: ', fc.c_email_address, ' - Total Spent: $', COALESCE(ps.total_spent, 0)) AS email_summary,
        ad.ca_city, ad.ca_state
    FROM FilteredCustomers fc
    LEFT JOIN PurchaseSummary ps ON fc.c_customer_sk = ps.ss_customer_sk
    LEFT JOIN AddressDetails ad ON ad.ca_address_sk = fc.c_current_addr_sk
)
SELECT 
    es.email_summary, 
    CASE 
        WHEN es.ca_state = 'CA' THEN 'West Coast'
        WHEN es.ca_state = 'TX' THEN 'South Central'
        ELSE 'Other'
    END AS region
FROM EmailSummary es
ORDER BY es.ca_state, es.email_summary;
