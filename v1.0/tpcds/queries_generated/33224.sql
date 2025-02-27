
WITH RECURSIVE SalesRanking AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
TopSellingItems AS (
    SELECT 
        s_item_sk, 
        total_quantity
    FROM SalesRanking
    WHERE rank <= 10
),
AddressSales AS (
    SELECT 
        ca_state,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_ship_customer_sk) AS unique_customers
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2459015 AND 2459340
    GROUP BY ca_state
)
SELECT 
    a.ca_state, 
    a.total_sales, 
    a.unique_customers,
    COALESCE(c.total_quantity, 0) AS total_quantity_sold,
    CASE 
        WHEN a.total_sales > 10000 THEN 'High' 
        WHEN a.total_sales > 5000 THEN 'Moderate' 
        ELSE 'Low' 
    END AS sales_category
FROM AddressSales a
LEFT JOIN TopSellingItems c ON c.ws_item_sk = a.total_sales
ORDER BY a.total_sales DESC, a.ca_state ASC;
