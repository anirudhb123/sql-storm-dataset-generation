
WITH RECURSIVE SalesCTE AS (
    SELECT ws_order_number, ws_item_sk, ws_quantity, ws_sales_price, 
           ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_quantity DESC) as rn
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
                              AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
TopSales AS (
    SELECT ws_order_number, SUM(ws_quantity * ws_sales_price) AS total_sales
    FROM SalesCTE
    WHERE rn <= 5
    GROUP BY ws_order_number
),
CustomerOrders AS (
    SELECT c.c_customer_sk, SUM(ts.total_sales) AS total_spent
    FROM customer c
    INNER JOIN TopSales ts ON c.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_order_number = ts.ws_order_number)
    GROUP BY c.c_customer_sk
)
SELECT cd_gender, COUNT(co.c_customer_sk) AS customer_count,
       AVG(co.total_spent) AS avg_spent,
       MAX(co.total_spent) AS max_spent
FROM CustomerOrders co
JOIN customer_demographics cd ON co.c_customer_sk = cd.cd_demo_sk
GROUP BY cd_gender
HAVING AVG(co.total_spent) > (SELECT AVG(total_spent) FROM CustomerOrders)
ORDER BY customer_count DESC;
