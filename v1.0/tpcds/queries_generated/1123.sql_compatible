
WITH top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_paid_inc_tax) > 5000
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer_demographics AS cd
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    cdem.cd_gender,
    cdem.cd_marital_status,
    cdem.cd_education_status,
    COUNT(ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid) AS avg_order_value,
    MAX(ws.ws_sold_date_sk) AS last_purchase_date,
    DATEADD(day, 30, MAX(ws.ws_sold_date_sk)) AS next_purchase_due
FROM 
    top_customers AS tc
LEFT JOIN 
    customer AS c ON tc.c_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics AS cdem ON c.c_current_cdemo_sk = cdem.cd_demo_sk
LEFT JOIN 
    web_sales AS ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, cdem.cd_gender, cdem.cd_marital_status, cdem.cd_education_status
HAVING 
    COUNT(ws.ws_order_number) > 10
ORDER BY 
    total_orders DESC;
