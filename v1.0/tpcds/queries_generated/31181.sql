
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        1 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        ch.level + 1
    FROM 
        customer_hierarchy ch
    JOIN 
        customer c ON ch.c_customer_sk = c.c_current_hdemo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
), 
sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.cd_gender,
    COALESCE(ss.total_profit, 0) AS total_profit,
    ss.order_count,
    CASE 
        WHEN ss.order_count IS NULL THEN 'No sales'
        WHEN ss.total_profit > 500 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    customer_hierarchy ch
LEFT JOIN 
    sales_summary ss ON ch.c_customer_sk = ss.customer_sk
ORDER BY 
    total_profit DESC
LIMIT 
    10;
