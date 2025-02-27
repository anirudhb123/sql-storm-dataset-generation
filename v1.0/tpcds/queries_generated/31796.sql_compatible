
WITH RECURSIVE CustomerPath AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, 1 AS level
    FROM customer c
    WHERE c.c_customer_sk < 1000  

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, cp.level + 1
    FROM customer c
    JOIN CustomerPath cp ON c.c_current_addr_sk = cp.c_current_addr_sk
    WHERE cp.level < 5
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS row_num
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
TopSales AS (
    SELECT ws_item_sk AS item_sk, total_quantity, total_sales FROM SalesData WHERE row_num <= 10
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        COUNT(DISTINCT sd.item_sk) AS purchase_count,
        SUM(sd.total_sales) AS total_spent
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN TopSales sd ON c.c_customer_sk = sd.item_sk
    GROUP BY c.c_customer_sk, ca.ca_city
)
SELECT 
    cc.c_first_name,
    cc.c_last_name,
    fc.ca_city,
    fc.purchase_count,
    fc.total_spent,
    CASE 
        WHEN fc.total_spent IS NULL THEN 'No Purchases'
        WHEN fc.total_spent > 1000 THEN 'High Value'
        WHEN fc.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM CustomerPath cc
LEFT JOIN FilteredCustomers fc ON cc.c_customer_sk = fc.c_customer_sk
ORDER BY customer_value_category, fc.total_spent DESC;
