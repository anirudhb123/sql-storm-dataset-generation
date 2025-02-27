
WITH RecentSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws_item_sk) AS unique_items,
        SUM(ws_ext_sales_price) AS total_revenue
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
DemographicAnalysis AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    ws.ws_item_sk,
    ws.total_sold,
    ws.total_profit,
    w.unique_items,
    w.total_revenue,
    d.customer_count,
    d.avg_purchase_estimate
FROM 
    RecentSales ws
LEFT JOIN 
    WarehouseStats w ON w.unique_items > 10 OR w.total_revenue IS NULL
JOIN 
    DemographicAnalysis d ON d.customer_count > (SELECT AVG(customer_count) FROM DemographicAnalysis)
WHERE 
    ws.rn = 1 AND 
    (ws.total_profit IS NOT NULL OR ws.total_sold > 100) AND 
    EXISTS (
        SELECT 1
        FROM catalog_sales cs 
        WHERE cs.cs_item_sk = ws.ws_item_sk 
          AND (cs.cs_net_profit > 0 OR cs.cs_ext_discount_amt IS NOT NULL)
        HAVING COUNT(cs.cs_order_number) > 0
    )
ORDER BY 
    ws.total_profit DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY;
