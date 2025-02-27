
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_id,
        s_store_name,
        s_sales_price,
        ss_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY ss_net_profit DESC) AS rank_sales
    FROM 
        store s
        JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss_ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
),
customer_activity AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws_order_number) AS web_orders,
        SUM(ws_sales_price) AS total_web_spent,
        CASE 
            WHEN SUM(ws_sales_price) IS NULL THEN 'Never Purchased'
            WHEN SUM(ws_sales_price) < 100 THEN 'Low Spender'
            ELSE 'High Spender'
        END AS spending_category
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        ca.c_customer_sk,
        ca.c_first_name,
        ca.c_last_name,
        ca.total_web_spent,
        PERCENT_RANK() OVER (ORDER BY ca.total_web_spent DESC) AS spend_rank
    FROM 
        customer_activity ca
    WHERE 
        ca.web_orders > 0
),
store_summary AS (
    SELECT 
        t.s_store_sk,
        MAX(sales_hierarchy.rank_sales) AS highest_sales_rank,
        CUME_DIST() OVER (PARTITION BY t.s_store_sk ORDER BY SUM(ss_net_profit) DESC) AS cumulative_profit
    FROM 
        sales_hierarchy AS sh
        JOIN store_sales AS ss ON sh.s_store_sk = ss.ss_store_sk
        JOIN store AS t ON sh.s_store_sk = t.s_store_sk
    GROUP BY 
        t.s_store_sk
)
SELECT 
    sc.s_store_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_spent,
    tc.spending_category,
    su.cumulative_profit,
    CASE 
        WHEN su.highest_sales_rank = 1 THEN 'Top Store'
        ELSE 'Regular Store'
    END AS store_category
FROM 
    top_customers tc
    JOIN store_summary su ON tc.c_customer_sk = su.s_store_sk
    JOIN store s ON s.s_store_sk = su.s_store_sk
WHERE 
    tc.spend_rank <= 0.1
ORDER BY 
    total_web_spent DESC;
