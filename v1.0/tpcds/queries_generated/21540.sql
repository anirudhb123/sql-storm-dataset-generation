
WITH Recurring_Customers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING COUNT(DISTINCT ws.ws_order_number) > 1
),
Customer_Capital AS (
    SELECT c.c_customer_sk, 
           SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY c.c_customer_sk
),
Highest_Selling_Items AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_sold
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
    HAVING SUM(ws.ws_quantity) > (
        SELECT AVG(total_quantity) 
        FROM (
            SELECT SUM(ws2.ws_quantity) AS total_quantity 
            FROM web_sales ws2 
            GROUP BY ws2.ws_item_sk
        ) AS item_totals
    )
),
Combined_Details AS (
    SELECT rc.c_customer_sk,
           rc.c_first_name || ' ' || rc.c_last_name AS full_name,
           cc.total_spent,
           hs.total_sold
    FROM Recurring_Customers rc
    LEFT JOIN Customer_Capital cc ON rc.c_customer_sk = cc.c_customer_sk
    LEFT JOIN Highest_Selling_Items hs ON cc.c_customer_sk = hs.ws_item_sk
)
SELECT full_name, 
       COALESCE(total_spent, 0) AS total_spent, 
       COALESCE(total_sold, 0) AS total_sold,
       ROUND(total_spent ::: DECIMAL / NULLIF(total_sold, 0), 2) AS avg_spent_per_item
FROM Combined_Details
WHERE total_spent IS NOT NULL OR total_sold IS NOT NULL
ORDER BY avg_spent_per_item DESC
LIMIT 10;
