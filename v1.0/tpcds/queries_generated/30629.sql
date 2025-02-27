
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
    UNION ALL
    SELECT 
        cs_sales_price,
        cs_quantity,
        cs_net_profit,
        cs_order_number,
        ROW_NUMBER() OVER (PARTITION BY cs_order_number ORDER BY cs_net_profit DESC) AS rn
    FROM 
        catalog_sales
    WHERE 
        cs_sales_price > 0
),
aggregated_sales AS (
    SELECT 
        s_order_number,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        sales_cte
    WHERE 
        rn = 1
    GROUP BY 
        ws_order_number
),
customer_stats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT cs.ws_order_number) AS order_count,
        SUM(cs.total_sales) AS total_sales,
        AVG(cs.total_profit) AS avg_profit
    FROM 
        customer c
    LEFT JOIN aggregated_sales cs ON c.c_customer_sk = cs.s_order_number
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        customer_stats cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    tc.rank,
    COALESCE(d.d_year, 0) AS year,
    COALESCE(d.d_month_seq, 0) AS month,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid_inc_tax) AS total_paid
FROM 
    top_customers tc
LEFT JOIN date_dim d ON d.d_date_sk = (
    SELECT MAX(d_date_sk)
    FROM date_dim
    WHERE d.d_date <= CURRENT_DATE
)
LEFT JOIN web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
GROUP BY 
    tc.c_customer_id, tc.total_sales, tc.order_count, tc.rank, d.d_year, d.d_month_seq
HAVING 
    total_sales > 10000
ORDER BY 
    tc.rank;
