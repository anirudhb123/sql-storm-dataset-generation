
WITH RECURSIVE top_customers AS (
    SELECT c_customer_sk, 
           c_first_name, 
           c_last_name, 
           SUM(ss_net_profit) AS total_profit,
           RANK() OVER (ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c_customer_sk, c_first_name, c_last_name
    HAVING SUM(ss_net_profit) > 0
),
valid_items AS (
    SELECT i_item_sk, 
           i_item_id, 
           i_product_name, 
           i_current_price
    FROM item
    WHERE i_current_price IS NOT NULL
),
sales_summary AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discounts,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_item_sk) AS item_count,
        MAX(ws.ws_ship_date_sk) AS last_shipped_date
    FROM web_sales ws
    LEFT JOIN valid_items vi ON ws.ws_item_sk = vi.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ws.ws_order_number
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        MAX(ss.total_sales) AS highest_order_value
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_profit,
    cs.highest_order_value,
    COALESCE(SUM(ss.total_sales), 0) AS total_web_sales,
    COALESCE(SUM(ss.total_discounts), 0) AS total_web_discounts,
    COUNT(ss.ws_order_number) AS web_sales_count
FROM top_customers tc
LEFT JOIN sales_summary ss ON tc.rank <= 10  -- Include only top 10 customers
LEFT JOIN customer_sales cs ON tc.c_customer_sk = cs.c_customer_sk
GROUP BY tc.c_first_name, tc.c_last_name, tc.total_profit, cs.highest_order_value
ORDER BY total_profit DESC, total_web_sales DESC;
