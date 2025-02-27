
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 0 AS hierarchy_level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.hierarchy_level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_cdemo_sk
), sales_data AS (
    SELECT ws.bill_customer_sk, 
           SUM(ws.ws_net_profit) AS total_profit, 
           COUNT(ws.ws_order_number) AS orders_count, 
           ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN customer_hierarchy ch ON ws.bill_customer_sk = ch.c_customer_sk
    GROUP BY ws.bill_customer_sk
), promotion_data AS (
    SELECT p.p_promo_sk, 
           SUM(CASE 
                   WHEN cs.cs_sales_price IS NOT NULL THEN cs.cs_sales_price 
                   ELSE 0 
               END) AS total_promotion_sales
    FROM promotion p
    LEFT JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY p.p_promo_sk
), filtered_sales AS (
    SELECT sd.bill_customer_sk, 
           sd.total_profit, 
           sd.orders_count, 
           COALESCE(pd.total_promotion_sales, 0) AS promotion_sales
    FROM sales_data sd
    LEFT JOIN promotion_data pd ON sd.bill_customer_sk = pd.p_promo_sk
    WHERE sd.orders_count > 5 AND sd.total_profit > 5000
)
SELECT fh.c_first_name, 
       fh.c_last_name, 
       fs.total_profit, 
       fs.orders_count, 
       fs.promotion_sales, 
       ROW_NUMBER() OVER (ORDER BY fs.total_profit DESC) AS customer_rank
FROM filtered_sales fs
JOIN customer_hierarchy fh ON fs.bill_customer_sk = fh.c_customer_sk
WHERE fh.hierarchy_level = 0
ORDER BY fs.total_profit DESC
LIMIT 10;
