
WITH AddressConcat AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END,
               ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerFullName AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name
    FROM 
        customer
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        c.full_name,
        a.full_address
    FROM 
        customer_demographics cd
    JOIN 
        CustomerFullName c ON c.c_customer_sk = cd.cd_demo_sk
    JOIN 
        customer_address a ON a.ca_address_sk = c.c_current_addr_sk
),
PurchaseSummary AS (
    SELECT 
        d.cd_demo_sk, 
        COUNT(ws.ws_order_number) AS total_purchases,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        Demographics d ON d.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY 
        d.cd_demo_sk
),
FinalReport AS (
    SELECT 
        d.*,
        ps.total_purchases,
        ps.total_spent
    FROM 
        Demographics d
    LEFT JOIN 
        PurchaseSummary ps ON d.cd_demo_sk = ps.cd_demo_sk
)
SELECT 
    *,
    CASE 
        WHEN total_spent > 1000 THEN 'High Spender'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Spender'
        ELSE 'Low Spender' 
    END AS spending_category
FROM 
    FinalReport
ORDER BY 
    full_name;
