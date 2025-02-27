
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_pages_visited
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
        AND ws.ws_sold_date_sk BETWEEN 2459795 AND 2459850  -- Assuming these are Julian days for the desired date range
    GROUP BY 
        c.c_customer_id
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
demographic_sales AS (
    SELECT 
        cs.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cs.total_profit,
        cs.total_orders,
        cs.avg_order_value,
        cs.unique_pages_visited
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    COUNT(*) AS num_customers,
    AVG(ds.total_profit) AS avg_profit,
    AVG(ds.total_orders) AS avg_orders,
    AVG(ds.avg_order_value) AS avg_order_value,
    SUM(ds.unique_pages_visited) AS total_unique_pages
FROM 
    demographic_sales ds
GROUP BY 
    ds.cd_gender,
    ds.cd_marital_status
ORDER BY 
    avg_profit DESC, num_customers DESC;
