
WITH AddressInfo AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country,
        ca_zip
    FROM customer_address
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM customer_demographics
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        a.ca_zip,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM customer c
    JOIN AddressInfo a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        c.*,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN c.cd_purchase_estimate > 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_value
    FROM CustomerDetails c
    WHERE c.cd_purchase_estimate > 5000
),
SalesSummary AS (
    SELECT
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        AVG(ss_net_paid) AS avg_transaction_value,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 30
)
SELECT 
    hv.full_name,
    hv.cd_gender,
    hv.cd_marital_status,
    hv.cd_education_status,
    hv.customer_value,
    ss.total_sales,
    ss.total_transactions,
    ss.avg_transaction_value,
    ss.unique_customers
FROM HighValueCustomers hv
CROSS JOIN SalesSummary ss
ORDER BY ss.total_sales DESC;
