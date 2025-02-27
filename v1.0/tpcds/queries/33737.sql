
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           1 AS level
    FROM customer c
    WHERE c.c_birth_country IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 5
),
SalesData AS (
    SELECT 
        ws_sold_date_sk AS sold_date,
        ws_item_sk AS item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT item_sk, total_sales, total_orders,
           ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData
    WHERE total_sales > (SELECT AVG(total_sales) FROM SalesData)
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    th.total_sales,
    th.total_orders,
    CASE 
        WHEN c.c_current_cdemo_sk IS NULL THEN 'No Demographic Info'
        ELSE dm.cd_gender
    END AS gender,
    CASE 
        WHEN th.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS Seller_Status
FROM CustomerHierarchy ch
LEFT JOIN customer c ON ch.c_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics dm ON c.c_current_cdemo_sk = dm.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN TopSales th ON th.item_sk = c.c_current_addr_sk
ORDER BY th.total_sales DESC, c.c_last_name ASC;
