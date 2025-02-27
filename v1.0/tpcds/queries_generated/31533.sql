
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
InventorySummary AS (
    SELECT inv_date_sk, inv_item_sk, SUM(inv_quantity_on_hand) AS total_quantity
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_date_sk, inv_item_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales, 
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rnk
    FROM web_sales
    GROUP BY ws_item_sk
),
DemographicSummary AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents
    FROM customer_demographics
    JOIN customer c ON c.c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
ReturnAnalysis AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        (SUM(sr_return_amt) / NULLIF(SUM(sr_return_quantity), 0)) AS avg_return_value
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    da.total_customers,
    SUM(ISNULL(is.total_quantity, 0)) AS inventory_level,
    SUM(SD.total_sales) AS total_revenue,
    COALESCE(ra.total_returns, 0) AS total_returns,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    SUM(DISTINCT ds.avg_dependents) OVER (PARTITION BY ch.c_current_cdemo_sk) AS customer_avg_dependents
FROM CustomerHierarchy ch
LEFT JOIN InventorySummary is ON ch.c_current_addr_sk = is.inv_item_sk
LEFT JOIN SalesData SD ON ch.c_current_cdemo_sk = SD.ws_item_sk
LEFT JOIN ReturnAnalysis ra ON SD.ws_item_sk = ra.sr_item_sk
JOIN DemographicSummary da ON da.cd_gender = (CASE WHEN ch.c_first_name IS NULL THEN 'M' ELSE 'F' END)
GROUP BY ch.c_customer_sk, ch.c_first_name, ch.c_last_name, da.total_customers, ra.total_returns, ra.total_return_amount
HAVING SUM(SD.total_sales) > 1000
ORDER BY total_revenue DESC, total_returns DESC;
