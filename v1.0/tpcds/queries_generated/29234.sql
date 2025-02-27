
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
RecentTransactions AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = CURRENT_DATE - INTERVAL '30 days')
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.full_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    COALESCE(rt.total_spent, 0) AS total_spent_last_30_days,
    COALESCE(rt.order_count, 0) AS order_count_last_30_days
FROM 
    CustomerInfo ci
LEFT JOIN 
    RecentTransactions rt ON ci.c_customer_id = rt.ws_bill_customer_sk
WHERE 
    ci.cd_gender = 'F' 
    AND ci.cd_marital_status = 'M'
ORDER BY 
    total_spent_last_30_days DESC, 
    ci.full_name;
