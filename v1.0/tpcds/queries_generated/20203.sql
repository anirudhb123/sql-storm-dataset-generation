
WITH RECURSIVE sales_data AS (
    SELECT ss.sold_date_sk, 
           ss.item_sk, 
           ss.store_sk, 
           ss.quantity, 
           ss.net_profit, 
           1 AS sales_depth
    FROM store_sales ss
    WHERE ss.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    
    UNION ALL

    SELECT ss.sold_date_sk, 
           ss.item_sk, 
           ss.store_sk, 
           ss.quantity + sd.quantity, 
           ss.net_profit + sd.net_profit,
           sales_depth + 1
    FROM store_sales ss
    INNER JOIN sales_data sd ON ss.store_sk = sd.store_sk
    WHERE ss.sold_date_sk < sd.sold_date_sk
    AND sd.sales_depth < 5
),
ranked_sales AS (
    SELECT sd.store_sk, 
           SUM(sd.quantity) AS total_quantity, 
           SUM(sd.net_profit) AS total_profit,
           RANK() OVER (PARTITION BY sd.store_sk ORDER BY SUM(sd.net_profit) DESC) AS rnk
    FROM sales_data sd
    GROUP BY sd.store_sk
)
SELECT ca.city, 
       ca.state, 
       rs.total_quantity, 
       rs.total_profit,
       CASE 
           WHEN rs.total_profit IS NULL THEN 'No Profit'
           ELSE CAST(rs.total_profit AS CHAR)
       END AS profit_status
FROM ranked_sales rs
JOIN store s ON rs.store_sk = s.store_sk
JOIN customer_address ca ON s.store_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk IN (
    SELECT DISTINCT c.c_current_cdemo_sk 
    FROM customer c 
    WHERE c.c_first_name IS NOT NULL OR c.c_last_name IS NOT NULL
)
WHERE rs.rnk = 1 
AND (ca.state IS NOT NULL OR ca.city IS NOT NULL)
ORDER BY rs.total_profit DESC 
LIMIT 10;
