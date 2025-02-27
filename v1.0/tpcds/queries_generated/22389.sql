
WITH CustomerSales AS (
    SELECT c.c_customer_id, 
           SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count,
           AVG(ws.ws_sales_price) AS avg_sales_price
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY c.c_customer_id
), ItemSales AS (
    SELECT i.i_item_id,
           COUNT(DISTINCT ws.ws_order_number) AS sale_orders,
           SUM(ws.ws_net_profit) AS total_profit
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id
), SaleStatistics AS (
    SELECT cs.c_customer_id, 
           cs.total_sales,
           cs.order_count,
           COALESCE(iss.sale_orders, 0) AS order_count_per_item,
           COALESCE(iss.total_profit, 0) AS total_profit_per_item
    FROM CustomerSales cs
    LEFT JOIN (
        SELECT DISTINCT c.c_customer_id, 
                        i.i_item_id,
                        SUM(is.total_profit) AS total_profit, 
                        COUNT(is.sale_orders) AS sale_orders
        FROM CustomerSales css
        JOIN web_sales ws ON css.c_customer_id = ws.ws_bill_customer_sk
        JOIN ItemSales is ON ws.ws_item_sk = is.i_item_id
        JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
        GROUP BY c.c_customer_id, i.i_item_id
    ) iss ON cs.c_customer_id = iss.c_customer_id
), HighSpenders AS (
    SELECT s.*, 
           DENSE_RANK() OVER (ORDER BY s.total_sales DESC) AS rank
    FROM SaleStatistics s
    WHERE s.total_sales IS NOT NULL OR s.order_count > 5
)
SELECT h.*, 
       CASE 
           WHEN h.total_sales > 10000 THEN 'Platinum'
           WHEN h.total_sales BETWEEN 5000 AND 10000 THEN 'Gold'
           ELSE 'Silver' 
       END AS customer_tier
FROM HighSpenders h
WHERE h.rank <= 10
ORDER BY h.total_sales DESC
UNION ALL 
SELECT 'Aggregated' AS customer_id, 
       SUM(total_sales) AS total_sales, 
       COUNT(c_customer_id) AS order_count,
       NULL AS order_count_per_item, 
       NULL AS total_profit_per_item
FROM SaleStatistics
WHERE total_sales IS NOT NULL
GROUP BY customer_id
HAVING SUM(total_sales) > 20000;
