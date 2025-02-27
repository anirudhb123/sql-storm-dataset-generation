
WITH RECURSIVE SalesCTE AS (
    SELECT ss.s_sold_date_sk, ss.ss_item_sk, ss.ss_quantity, ss.ss_ext_sales_price, ss.ss_net_profit
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk = (SELECT MAX(ss2.ss_sold_date_sk) FROM store_sales ss2)
    
    UNION ALL
    
    SELECT ss.s_sold_date_sk, ss.ss_item_sk, ss.ss_quantity + cte.ss_quantity, ss.ss_ext_sales_price + cte.ss_ext_sales_price, ss.ss_net_profit + cte.ss_net_profit
    FROM store_sales ss
    JOIN SalesCTE cte ON ss.ss_item_sk = cte.ss_item_sk
    WHERE ss.ss_sold_date_sk < cte.s_sold_date_sk
),
AggSales AS (
    SELECT c.customer_id, SUM(cte.ss_quantity) AS total_quantity, SUM(cte.ss_net_profit) AS total_net_profit
    FROM customer c
    JOIN SalesCTE cte ON c.c_customer_sk = cte.ss_item_sk
    GROUP BY c.customer_id
),
RankedSales AS (
    SELECT customer_id, total_quantity, total_net_profit,
           DENSE_RANK() OVER (ORDER BY total_net_profit DESC) AS rnk
    FROM AggSales
)
SELECT rs.customer_id, rs.total_quantity, rs.total_net_profit,
       COALESCE(ca.ca_city, 'Unknown') AS city,
       CASE 
           WHEN rs.total_net_profit > 10000 THEN 'High'
           WHEN rs.total_net_profit BETWEEN 5000 AND 10000 THEN 'Medium'
           ELSE 'Low'
       END AS profit_band
FROM RankedSales rs
LEFT JOIN customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_id = rs.customer_id)
WHERE rs.rnk <= 10
ORDER BY rs.total_net_profit DESC;
