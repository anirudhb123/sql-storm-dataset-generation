
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS rn
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
      AND (c.c_first_name IS NOT NULL OR c.c_last_name IS NOT NULL)
),
FilteredReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
    GROUP BY cr.cr_item_sk
),
RevenueSummary AS (
    SELECT 
        i.i_item_sk,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_sales,
        COALESCE(fr.total_returned, 0) AS total_returns,
        (COALESCE(SUM(ws.ws_net_paid), 0) - COALESCE(fr.total_returned, 0)) AS net_revenue
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN FilteredReturns fr ON i.i_item_sk = fr.cr_item_sk
    GROUP BY i.i_item_sk
        HAVING net_revenue > 1000
),
FinalOutput AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_quantity,
        rs.ws_net_paid,
        rs.rn,
        rs.ws_quantity * (SELECT AVG(ws2.ws_net_paid) 
                          FROM web_sales ws2 
                          WHERE ws2.ws_item_sk = rs.ws_item_sk) AS avg_revenue_per_item,
        rs.ws_net_paid / GREATEST(NULLIF(SUM(rs.ws_net_paid) OVER (PARTITION BY rs.ws_item_sk), 0), 1) AS ratio_to_total
    FROM RankedSales rs
    WHERE rs.rn = 1
)
SELECT 
    fo.ws_item_sk,
    fo.ws_order_number,
    fo.ws_quantity,
    fo.ws_net_paid,
    fo.avg_revenue_per_item,
    CASE 
        WHEN fo.ratio_to_total > 0.5 THEN 'High'
        WHEN fo.ratio_to_total IS NULL OR fo.ratio_to_total = 0 THEN 'Undefined'
        ELSE 'Low'
    END AS sales_level
FROM FinalOutput fo
JOIN RevenueSummary rv ON fo.ws_item_sk = rv.i_item_sk
ORDER BY fo.ws_net_paid DESC NULLS LAST, fo.ws_quantity DESC;
