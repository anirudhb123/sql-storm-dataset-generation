
WITH RECURSIVE Sales_CTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_net_profit, 1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_net_profit + s.ws_net_profit, level + 1
    FROM web_sales s
    INNER JOIN Sales_CTE ct ON s.ws_sold_date_sk = ct.ws_sold_date_sk - 1
    WHERE ct.level < 10
),
Customer_Stats AS (
    SELECT c.c_customer_sk, 
           COUNT(DISTINCT cs.cs_order_number) AS total_orders,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           AVG(cs.cs_ext_sales_price) AS avg_sales
    FROM customer c
    LEFT JOIN store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    GROUP BY c.c_customer_sk
),
Top_Customers AS (
    SELECT c.c_customer_sk,
           cs.total_orders,
           cs.total_sales,
           DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer c
    JOIN Customer_Stats cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE cs.total_orders > 5
),
Filtered_Sales AS (
    SELECT s.ws_item_sk, 
           s.ws_net_profit,
           COALESCE(SUM(cs.total_sales), 0) AS customer_total_sales,
           DENSE_RANK() OVER (PARTITION BY s.ws_item_sk ORDER BY s.ws_net_profit DESC) AS profit_rank
    FROM web_sales s
    LEFT JOIN Customer_Stats cs ON s.ws_bill_customer_sk = cs.c_customer_sk
    GROUP BY s.ws_item_sk, s.ws_net_profit
)
SELECT t.c_customer_sk,
       t.total_orders,
       t.total_sales,
       fs.customer_total_sales,
       fs.ws_net_profit,
       SUM(s.quantity) OVER (PARTITION BY t.c_customer_sk) AS total_item_quantity,
       CASE 
           WHEN t.total_orders < 10 THEN 'Low'
           WHEN t.total_orders BETWEEN 10 AND 50 THEN 'Medium'
           ELSE 'High'
       END AS order_segment
FROM Top_Customers t
JOIN Filtered_Sales fs ON t.c_customer_sk = fs.ws_item_sk
WHERE fs.profit_rank <= 5
ORDER BY t.total_sales DESC, total_item_quantity ASC;
