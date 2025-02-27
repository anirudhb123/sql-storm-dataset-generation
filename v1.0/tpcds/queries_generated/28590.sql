
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RecentPurchases AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        COUNT(ws_order_number) AS purchase_count,
        SUM(ws_net_paid) AS total_spent,
        AVG(ws_net_paid) AS average_spent
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)  -- last 30 days
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSummary AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ri.purchase_count,
        ri.total_spent,
        ri.average_spent
    FROM 
        CustomerInfo AS ci
    LEFT JOIN 
        RecentPurchases AS ri ON ci.c_customer_id = ri.customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COALESCE(purchase_count, 0) AS purchase_count,
    COALESCE(total_spent, 0) AS total_spent,
    CASE 
        WHEN average_spent IS NOT NULL THEN ROUND(average_spent, 2)
        ELSE 0 
    END AS average_spent
FROM 
    CustomerSummary
ORDER BY 
    total_spent DESC,
    purchase_count DESC
LIMIT 100;
