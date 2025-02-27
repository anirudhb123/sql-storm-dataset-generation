
WITH RECURSIVE date_range AS (
    SELECT d_date_sk, d_date 
    FROM date_dim 
    WHERE d_date >= '2022-01-01' 
    UNION ALL 
    SELECT d.d_date_sk, d.d_date 
    FROM date_dim d 
    INNER JOIN date_range dr ON d.d_date_sk = dr.d_date_sk + 1
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM web_sales 
    INNER JOIN date_range ON web_sales.ws_sold_date_sk = date_range.d_date_sk
    GROUP BY ws_bill_customer_sk
),
high_value_customers AS (
    SELECT 
        cs.c_customer_id, 
        cs.c_first_name, 
        cs.c_last_name, 
        ss.total_orders, 
        ss.total_sales, 
        ss.total_profit
    FROM customer cs
    JOIN sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk 
    WHERE ss.total_profit > 1000
),
store_performance AS (
    SELECT 
        s.s_store_name, 
        COUNT(ss.ss_order_number) AS total_store_orders, 
        SUM(ss.ss_net_profit) AS store_total_profit 
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_name
)
SELECT 
    hvc.c_customer_id, 
    hvc.c_first_name, 
    hvc.c_last_name, 
    hvc.total_orders, 
    hvc.total_sales, 
    hvc.total_profit, 
    sp.total_store_orders, 
    sp.store_total_profit 
FROM high_value_customers hvc
FULL OUTER JOIN store_performance sp ON hvc.total_profit = sp.store_total_profit
WHERE hvc.total_orders > 5 
AND (sp.total_store_orders IS NULL OR sp.total_store_orders > 10)
ORDER BY hvc.total_profit DESC, sp.store_total_profit ASC;
