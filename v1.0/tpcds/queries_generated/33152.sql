
WITH RECURSIVE Customer_Hierarchy AS (
    SELECT c_customer_sk, c_customer_id, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, c.c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN Customer_Hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
Sales_Data AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           AVG(ws_net_profit) AS average_profit,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
Top_Customers AS (
    SELECT ch.c_customer_sk,
           ch.c_customer_id,
           ch.c_first_name,
           ch.c_last_name,
           COALESCE(sd.total_sales, 0) AS total_sales,
           COALESCE(sd.average_profit, 0) AS average_profit,
           COALESCE(sd.order_count, 0) AS order_count,
           RANK() OVER (ORDER BY COALESCE(sd.total_sales, 0) DESC) AS sales_rank
    FROM Customer_Hierarchy ch
    LEFT JOIN Sales_Data sd ON ch.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT tc.c_customer_id,
       tc.c_first_name,
       tc.c_last_name,
       tc.total_sales,
       tc.average_profit,
       tc.order_count,
       CASE 
           WHEN tc.total_sales > 1000 THEN 'Gold'
           WHEN tc.total_sales BETWEEN 500 AND 1000 THEN 'Silver'
           ELSE 'Bronze'
       END AS customer_tier,
       (SELECT COUNT(*) FROM Top_Customers t WHERE t.total_sales > tc.total_sales) AS higher_sales_count
FROM Top_Customers tc
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC;
```
