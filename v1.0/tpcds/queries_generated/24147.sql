
WITH RankedReturns AS (
    SELECT 
        sr_item_sk, 
        sr_return_quantity, 
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
), 
HighValueReturns AS (
    SELECT 
        r1.sr_item_sk, 
        SUM(r1.sr_return_quantity) AS total_return_quantity,
        COALESCE(MAX(r2.warehouse_gmt_offset), 0) AS max_warehouse_offset,
        AVG(CASE 
                WHEN r1.sr_return_quantity > 5 THEN 1 
                ELSE NULL 
            END) AS high_return_ratio
    FROM RankedReturns r1
    LEFT JOIN inventory r2 ON r1.sr_item_sk = r2.inv_item_sk
    GROUP BY r1.sr_item_sk
    HAVING SUM(r1.sr_return_quantity) > 10
), 
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        MAX(cd.cd_dep_count) AS max_dependents,
        MAX(cd.cd_credit_rating) AS top_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_id
), 
FilteredWares AS (
    SELECT 
        w.w_warehouse_name,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        AVG(ws.ws_net_paid) AS avg_net_sales
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE w.w_country = 'USA' 
        AND COALESCE(ws.ws_net_paid, 0) > 0
    GROUP BY w.w_warehouse_name
)
SELECT 
    c.c_customer_id,
    COALESCE(h.total_return_quantity, 0) AS total_returns,
    f.web_sales_count,
    f.avg_net_sales,
    h.max_warehouse_offset,
    h.high_return_ratio
FROM CustomerStats c
LEFT JOIN HighValueReturns h ON h.sr_item_sk = (
    SELECT sr_item_sk FROM store_sales 
    WHERE ss_customer_sk = c.c_customer_sk 
    ORDER BY ss_net_profit DESC 
    LIMIT 1
)
LEFT JOIN FilteredWares f ON f.web_sales_count > 0
WHERE h.high_return_ratio IS NOT NULL 
   OR f.avg_net_sales IS NOT NULL
ORDER BY c.c_customer_id, total_returns DESC
LIMIT 100;
