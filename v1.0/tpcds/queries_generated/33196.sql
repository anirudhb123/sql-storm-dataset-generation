
WITH RECURSIVE SalesCTE AS (
    SELECT ss.sold_date_sk, ss.item_sk, ss.customer_sk, ss.quantity, ss_sales_price,
           CAST(ss_sales_price AS DECIMAL(10,2)) AS net_profit,
           1 AS level
    FROM store_sales ss
    WHERE ss.sold_date_sk = (SELECT MAX(ss2.sold_date_sk) FROM store_sales ss2)

    UNION ALL

    SELECT ss_next.sold_date_sk, ss_next.item_sk, ss_next.customer_sk, 
           ss_next.quantity, ss_next.sales_price, 
           COALESCE(sct.net_profit + ss_next.sales_price, ss_next.sales_price) AS net_profit,
           sct.level + 1
    FROM store_sales ss_next
    JOIN SalesCTE sct ON ss_next.customer_sk = sct.customer_sk AND sct.level < 3
)
SELECT c.c_first_name || ' ' || c.c_last_name AS customer_name,
       SUM(s.net_profit) AS total_net_profit,
       COUNT(DISTINCT s.item_sk) AS unique_items,
       COUNT(s.quantity) AS total_transactions,
       AVG(s.net_profit) AS avg_profit,
       CASE 
           WHEN AVG(s.net_profit) > 100 THEN 'High Value Customer'
           WHEN AVG(s.net_profit) BETWEEN 50 AND 100 THEN 'Medium Value Customer'
           ELSE 'Low Value Customer'
       END AS customer_value_category,
       COALESCE(d.d_year, 0) AS fiscal_year,
       CAST(DATE '2023-01-01' AS DATE) + (d.d_dom - 1) AS sales_date
FROM SalesCTE s
LEFT JOIN customer c ON s.customer_sk = c.c_customer_sk
LEFT JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
WHERE c.c_current_cdemo_sk IS NOT NULL
GROUP BY c.c_first_name, c.c_last_name, d.d_year
ORDER BY total_net_profit DESC
LIMIT 10;
