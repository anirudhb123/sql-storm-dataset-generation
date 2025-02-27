
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(DISTINCT ws.order_number) AS order_count,
        MAX(ws.sold_date_sk) AS last_purchase_date
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 365 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.bill_customer_sk
),
top_customers AS (
    SELECT 
        sd.bill_customer_sk, 
        sd.total_profit,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS rank
    FROM sales_data sd
    WHERE sd.total_profit IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.first_name, 
        c.last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate 
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.first_name,
    ci.last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    tc.total_profit,
    tc.rank,
    CASE 
        WHEN tc.rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer' 
    END AS customer_tier,
    COALESCE((SELECT SUM(sr_return_quantity) 
              FROM store_returns sr 
              WHERE sr.sr_customer_sk = tc.bill_customer_sk), 0) AS total_returns,
    CASE
        WHEN COALESCE((SELECT SUM(sr_return_quantity) 
                       FROM store_returns sr 
                       WHERE sr.sr_customer_sk = tc.bill_customer_sk), 0) > 10 
        THEN 'High Return Rate'
        ELSE 'Low Return Rate' 
    END AS return_rate_category
FROM 
    top_customers tc
JOIN 
    customer_info ci ON tc.bill_customer_sk = ci.c_customer_sk
WHERE 
    tc.rank <= 50
ORDER BY 
    tc.total_profit DESC, 
    ci.last_name;
