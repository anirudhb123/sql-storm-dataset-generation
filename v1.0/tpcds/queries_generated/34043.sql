
WITH RECURSIVE Sales_CTE AS (
    SELECT ws.order_number, ws_item_sk, ws_sales_price, ws_quantity,
           ROW_NUMBER() OVER(PARTITION BY ws.order_number ORDER BY ws_item_sk) as rn
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL

    UNION ALL

    SELECT cs.order_number, cs_item_sk, cs_sales_price, cs_quantity,
           ROW_NUMBER() OVER(PARTITION BY cs.order_number ORDER BY cs_item_sk) as rn
    FROM catalog_sales cs
    JOIN customer c ON cs.bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL
), 
Aggregated_Sales AS (
    SELECT order_number, 
           SUM(ws_sales_price * ws_quantity) AS total_sales,
           SUM(ws_quantity) AS total_quantity,
           COUNT(DISTINCT ws_item_sk) AS unique_items
    FROM Sales_CTE
    GROUP BY order_number
),
Address_Info AS (
    SELECT c.c_customer_sk, ca.ca_city, ca.ca_state,
           COUNT(DISTINCT cs.order_number) as total_orders
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY c.c_customer_sk, ca.ca_city, ca.ca_state
),
Final_Report AS (
    SELECT ai.ca_city, ai.ca_state,
           SUM(asales.total_sales) AS city_total_sales,
           SUM(asales.total_quantity) AS city_total_quantity,
           COUNT(DISTINCT ai.c_customer_sk) AS customer_count
    FROM Address_Info ai
    LEFT JOIN Aggregated_Sales asales ON ai.total_orders > 0
    GROUP BY ai.ca_city, ai.ca_state
)
SELECT DISTINCT city, state, city_total_sales, city_total_quantity, customer_count
FROM Final_Report
WHERE city_total_sales IS NOT NULL
ORDER BY city_total_sales DESC;
