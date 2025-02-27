
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CD.cd_purchase_estimate,
        REGEXP_REPLACE(c.c_email_address, '@.*', '') AS email_prefix
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent,
        SUM(ws_quantity) AS total_items_ordered
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
DetailedReport AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        ss.total_orders,
        ss.total_spent,
        ss.total_items_ordered,
        (CASE 
            WHEN ss.total_spent IS NULL THEN 'No Purchases'
            WHEN ss.total_spent < 100 THEN 'Low Spender'
            WHEN ss.total_spent BETWEEN 100 AND 500 THEN 'Medium Spender'
            ELSE 'High Spender'
        END) AS spending_category
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesSummary ss ON cd.c_customer_id = ss.customer_id
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country,
    total_orders,
    total_spent,
    total_items_ordered,
    spending_category
FROM 
    DetailedReport
WHERE 
    total_orders IS NOT NULL
ORDER BY 
    total_spent DESC
LIMIT 100;
