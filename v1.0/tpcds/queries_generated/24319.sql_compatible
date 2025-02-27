
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, 0 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL AND ca_city IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, ah.level + 1
    FROM customer_address a
    JOIN AddressHierarchy ah ON a.ca_state = ah.ca_state AND a.ca_city <> ah.ca_city
),
SalesAnalytics AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
FinalSales AS (
    SELECT 
        sa.ws_item_sk,
        sa.total_quantity,
        sa.total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
        (sa.total_sales - COALESCE(rs.total_returned_amount, 0)) AS net_sales,
        CASE 
            WHEN sa.total_quantity > 100 THEN 'High Volume'
            WHEN sa.total_quantity BETWEEN 50 AND 100 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS sale_volume_category
    FROM SalesAnalytics sa
    LEFT JOIN ReturnStats rs ON sa.ws_item_sk = rs.sr_item_sk
)
SELECT 
    ah.ca_city,
    ah.ca_state,
    fs.ws_item_sk,
    fs.total_quantity,
    fs.total_sales,
    fs.total_returns,
    fs.net_sales,
    fs.sale_volume_category,
    CASE 
        WHEN fs.net_sales IS NULL THEN 'No Sales'
        WHEN fs.net_sales < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profitability_status
FROM AddressHierarchy ah
JOIN FinalSales fs ON fs.ws_item_sk IN (
    SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_ship_date_sk >= 2450000
)
WHERE EXISTS (
    SELECT 1 FROM customer c 
    WHERE c.c_current_addr_sk = ah.ca_address_sk AND (c.c_birth_month IS NULL OR c.c_birth_month = 1)
)
ORDER BY ah.ca_city, ah.ca_state, fs.sales_rank;
