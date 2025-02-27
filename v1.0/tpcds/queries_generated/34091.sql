
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
    UNION ALL
    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sales_price DESC) AS rank
    FROM catalog_sales
    GROUP BY cs_item_sk
),
CombinedSales AS (
    SELECT 
        item.i_item_sk,
        COALESCE(SUM(s.total_sales), 0) AS total_sales_units,
        COALESCE(SUM(CASE WHEN s.rank = 1 THEN s.total_sales ELSE 0 END), 0) AS max_sales_units
    FROM item 
    LEFT JOIN SalesCTE s ON item.i_item_sk = s.ws_item_sk OR item.i_item_sk = s.cs_item_sk
    GROUP BY item.i_item_sk
),
CustomerCounts AS (
    SELECT 
        cd.gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.gender
)
SELECT 
    ca.ca_state,
    SUM(cs.total_sales_units) AS total_sales,
    AVG(cc.customer_count) AS avg_customers,
    STRING_AGG(cc.gender, ', ') AS customer_genders,
    CASE 
        WHEN SUM(cs.total_sales_units) > 10000 THEN 'High Volume'
        WHEN SUM(cs.total_sales_units) BETWEEN 5000 AND 10000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category
FROM CombinedSales cs
JOIN customer_address ca ON ca.ca_address_sk = (
    SELECT c.c_current_addr_sk 
    FROM customer c 
    WHERE c.c_customer_sk IN (
        SELECT DISTINCT c_customer_sk 
        FROM web_sales 
        WHERE ws_item_sk = cs.ws_item_sk
    )
    LIMIT 1
)
LEFT JOIN CustomerCounts cc ON true
GROUP BY ca.ca_state
ORDER BY total_sales DESC
LIMIT 10;
