
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.bill_customer_sk,
        ws.bill_cdemo_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(ws.order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS order_rank
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year BETWEEN 2020 AND 2023
        )
    GROUP BY 
        ws.bill_customer_sk, ws.bill_cdemo_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        COALESCE(c.c_birth_year - 1980, 0) AS age_offset
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IS NOT NULL
),
top_customers AS (
    SELECT 
        cs.bill_customer_sk AS customer_sk,
        SUM(cs.net_profit) AS customer_profit,
        RANK() OVER (ORDER BY SUM(cs.net_profit) DESC) AS profit_rank
    FROM 
        web_sales cs
    WHERE 
        cs.sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_holiday = 'Y'
        )
    GROUP BY 
        cs.bill_customer_sk
    HAVING 
        SUM(cs.net_profit) > 5000
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_purchase_estimate,
    ss.total_profit,
    ss.total_orders,
    tc.customer_profit,
    (CASE 
        WHEN cd.cd_gender = 'F' THEN 'Female'
        WHEN cd.cd_gender = 'M' THEN 'Male'
        ELSE 'Other' 
    END) AS gender_description,
    (sd.c_demo_sk IS NULL OR sd.c_first_name IS NULL) AS is_incomplete_data,
    ROW_NUMBER() OVER (ORDER BY ss.total_profit DESC) AS rank_in_profit
FROM 
    sales_summary ss
JOIN 
    customer_details cd ON ss.bill_customer_sk = cd.c_customer_sk
FULL OUTER JOIN 
    top_customers tc ON ss.bill_customer_sk = tc.customer_sk
WHERE 
    (tc.customer_profit IS NOT NULL OR ss.total_orders > 10)
    AND (cd.cd_purchase_estimate BETWEEN 100 AND 10000 OR cd.c_birth_month IS NULL)
ORDER BY 
    total_profit DESC
LIMIT 50;
