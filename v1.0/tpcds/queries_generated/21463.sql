
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY ws_item_sk
),
store_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS store_net_profit
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY ss_store_sk
),
customer_activity AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT wr_order_number) AS web_return_count,
        SUM(wr_return_amt) AS total_web_return
    FROM customer c
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr_returning_customer_sk
    GROUP BY c.c_customer_id
),
item_stats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        MAX(i.i_current_price) - MIN(i.i_current_price) AS price_variation
    FROM item i
    JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
)
SELECT 
    s.s_store_name,
    sd.total_quantity,
    sd.total_profit,
    ss.store_net_profit,
    ca.c_customer_id,
    ca.web_return_count,
    ca.total_web_return,
    is.i_item_desc,
    is.price_variation
FROM sales_data sd
JOIN store_summary ss ON sd.total_profit > ss.store_net_profit
JOIN customer_activity ca ON ca.web_return_count IS NOT NULL
JOIN item_stats is ON is.i_item_sk = sd.ws_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE 
    sd.profit_rank <= 10 
    OR (sd.total_quantity > 100 AND sd.total_profit IS NOT NULL)
ORDER BY sd.total_profit DESC, ss.store_net_profit ASC
LIMIT 50;
