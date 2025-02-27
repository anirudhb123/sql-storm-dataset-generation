
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE 
                   WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                   THEN CONCAT(' Suite ', TRIM(ca_suite_number)) 
                   ELSE '' 
               END) AS full_address,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        address.full_address,
        address.city,
        address.state,
        address.zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts address ON c.c_current_addr_sk = address.ca_address_sk
),
RecentPurchases AS (
    SELECT 
        c.customer_sk,
        COUNT(ws.ws_order_number) AS purchase_count,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        c.customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.full_address,
    ci.city,
    ci.state,
    ci.zip,
    COALESCE(rp.purchase_count, 0) AS recent_purchase_count,
    COALESCE(rp.total_spent, 0.00) AS recent_total_spent
FROM 
    CustomerInfo ci
LEFT JOIN 
    RecentPurchases rp ON ci.c_customer_sk = rp.customer_sk
ORDER BY 
    ci.city ASC, ci.cd_marital_status DESC, recent_total_spent DESC
LIMIT 100;
