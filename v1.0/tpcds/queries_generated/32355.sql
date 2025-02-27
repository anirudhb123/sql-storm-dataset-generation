
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_net_paid) > 1000
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_paid) DESC) AS rn
    FROM catalog_sales
    GROUP BY cs_item_sk
    HAVING SUM(cs_net_paid) > 1000
),
Aggregate_Sales AS (
    SELECT 
        COALESCE(ws.ws_item_sk, cs.cs_item_sk) AS item_sk,
        SUM(COALESCE(ws.total_quantity, 0) + COALESCE(cs.total_quantity, 0)) AS total_quantity,
        SUM(COALESCE(ws.total_sales, 0) + COALESCE(cs.total_sales, 0)) AS total_sales
    FROM Sales_CTE ws
    FULL OUTER JOIN Sales_CTE cs ON ws.ws_item_sk = cs.cs_item_sk
    GROUP BY COALESCE(ws.ws_item_sk, cs.cs_item_sk)
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    ag.total_quantity,
    ag.total_sales,
    CASE 
        WHEN ag.total_sales > 5000 THEN 'High'
        WHEN ag.total_sales BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category 
FROM Aggregate_Sales ag
JOIN item i ON ag.item_sk = i.i_item_sk
WHERE ag.total_quantity > 50 
ORDER BY ag.total_sales DESC
LIMIT 10;
