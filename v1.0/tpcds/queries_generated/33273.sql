
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s.s_store_id,
        SUM(ss_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s.s_store_id
),
customer_activity AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_spent,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
return_summary AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
aggregated_data AS (
    SELECT 
        ca.c_customer_id,
        ca.web_orders,
        ca.store_orders,
        ca.total_web_spent,
        ca.total_store_spent,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_value, 0) AS total_return_value,
        sh.total_sales AS store_sales_reported
    FROM 
        customer_activity ca
    LEFT JOIN 
        return_summary rs ON rs.sr_customer_sk = ca.c_customer_sk
    LEFT JOIN 
        sales_hierarchy sh ON sh.s_store_id = (SELECT s_store_id FROM store WHERE s_store_sk = (SELECT ss_store_sk FROM store_sales WHERE ss_customer_sk = ca.c_customer_id LIMIT 1))
)
SELECT 
    *,
    (total_web_spent + total_store_spent - total_return_value) AS net_spent,
    CASE 
        WHEN total_returns > 0 THEN 'Returned'
        ELSE 'No Returns'
    END AS return_status
FROM 
    aggregated_data
WHERE 
    (total_web_spent + total_store_spent) > 1000
    OR total_returns > 0
ORDER BY 
    net_spent DESC
LIMIT 50;
