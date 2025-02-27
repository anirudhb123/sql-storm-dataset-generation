
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sold_date_sk) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
ItemStats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_sales
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
ReturnStats AS (
    SELECT 
        item.sk AS item_sk,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returns,
        SUM(COALESCE(cr_return_quantity, 0)) AS total_catalog_returns
    FROM 
        (SELECT sr_item_sk AS sk FROM store_returns 
         UNION ALL 
         SELECT cr_item_sk AS sk FROM catalog_returns) AS item
    LEFT JOIN 
        store_returns sr ON item.sk = sr.sr_item_sk
    LEFT JOIN 
        catalog_returns cr ON item.sk = cr.cr_item_sk
    GROUP BY 
        item.sk
)
SELECT 
    i.i_item_desc,
    is.order_count,
    is.total_sales,
    is.avg_sales,
    rs.total_returns,
    rs.total_catalog_returns,
    CASE 
        WHEN (rs.total_returns + rs.total_catalog_returns) > 0 THEN (is.total_sales / (rs.total_returns + rs.total_catalog_returns)) 
        ELSE NULL 
    END AS return_ratio,
    ROW_NUMBER() OVER (ORDER BY is.total_sales DESC) AS sales_rank
FROM 
    ItemStats is
LEFT JOIN 
    ReturnStats rs ON is.i_item_sk = rs.item_sk
WHERE 
    is.total_sales > 1000
    AND EXISTS (SELECT 1 FROM SalesCTE s WHERE s.ws_item_sk = is.i_item_sk AND s.rnk <= 5)
ORDER BY 
    return_ratio DESC
LIMIT 10;
