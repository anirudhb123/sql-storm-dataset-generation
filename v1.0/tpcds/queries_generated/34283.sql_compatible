
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, 0 AS level
    FROM item
    WHERE i_item_sk IS NOT NULL
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, CONCAT('Subitem of ', i.i_item_desc), ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk + 1 
    WHERE ih.level < 3
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        COALESCE(ca.ca_city, 'Unknown') AS city,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
),
SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
OptimizedSalesData AS (
    SELECT 
        i.i_item_sk, 
        COALESCE(sd.total_sales, 0) AS sales_amount, 
        COALESCE(sd.order_count, 0) AS orders, 
        ih.level,
        CASE 
            WHEN COALESCE(sd.total_sales, 0) > 1000 THEN 'High'
            WHEN COALESCE(sd.total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM item i
    LEFT JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk
)
SELECT 
    ci.c_customer_id, 
    ci.city, 
    osd.sales_amount, 
    osd.orders, 
    osd.sales_category
FROM CustomerInfo ci
JOIN OptimizedSalesData osd ON ci.c_customer_sk = osd.i_item_sk
WHERE ci.rn <= 10
ORDER BY osd.sales_amount DESC
LIMIT 50;
