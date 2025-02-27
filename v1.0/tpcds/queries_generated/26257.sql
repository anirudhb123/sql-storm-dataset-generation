
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
                    CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ad.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_paid) AS total_sales,
        COUNT(DISTINCT s.ss_ticket_number) AS transaction_count
    FROM 
        store_sales s
    GROUP BY 
        s.ss_item_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    ad.full_address,
    sd.total_quantity,
    sd.total_sales,
    sd.transaction_count
FROM 
    CustomerDetails cd
JOIN 
    SalesData sd ON cd.c_customer_sk = (SELECT ss_customer_sk FROM store_sales WHERE ss_item_sk = sd.ss_item_sk LIMIT 1)
WHERE 
    cd.cd_purchase_estimate > 1000 
    AND cd.cd_credit_rating = 'Good'
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
