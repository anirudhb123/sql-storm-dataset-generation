
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_item_sk) AS rn
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
    UNION ALL
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_ext_sales_price
    FROM catalog_sales cs
    JOIN SalesCTE s ON cs.cs_order_number = s.ws_order_number
    WHERE cs.cs_item_sk = s.ws_item_sk
),
TotalSales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales
    FROM web_sales ws
    LEFT JOIN catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    GROUP BY ws.ws_order_number
),
CustomerPerformance AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        SUM(ts.total_web_sales + ts.total_catalog_sales) AS total_spent,
        COUNT(ts.total_web_sales) AS order_count,
        MAX(ts.total_web_sales) AS max_web_order,
        COUNT(DISTINCT cs.cs_item_sk) AS unique_items_purchased
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN TotalSales ts ON c.c_customer_sk = ts.ws_order_number
    LEFT JOIN catalog_sales cs ON ts.ws_order_number = cs.cs_order_number
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city
)
SELECT 
    cp.c_customer_sk,
    cp.c_first_name,
    cp.c_last_name,
    cp.ca_city,
    cp.total_spent,
    cp.order_count,
    cp.max_web_order,
    cp.unique_items_purchased,
    CASE 
        WHEN cp.total_spent IS NULL THEN 'No Purchases'
        WHEN cp.total_spent < 100 THEN 'Low Spender'
        WHEN cp.total_spent BETWEEN 100 AND 500 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM CustomerPerformance cp
WHERE cp.order_count > 2
ORDER BY cp.total_spent DESC
LIMIT 50;
