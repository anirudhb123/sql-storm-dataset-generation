
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid IS NOT NULL 
        AND ws.ws_status IN ('completed', 'returned')
    UNION ALL
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_paid,
        DENSE_RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_net_paid DESC) AS sales_rank
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_net_paid IS NOT NULL 
        AND cs.cs_status IN ('completed', 'returned')
)
SELECT 
    w.w_warehouse_name,
    w.w_city,
    SUM(CASE WHEN r_reason_desc IS NULL THEN 0 ELSE r_refunded_cash END) AS total_refunds,
    AVG(CASE 
        WHEN cd.cd_gender = 'F' AND cd.cd_marital_status = 'S' 
        THEN ws.ws_net_paid 
        ELSE NULL 
    END) AS avg_female_single_sales,
    COALESCE(NULLIF(MAX(ws.ws_net_profit), 0), 'No Profit') AS max_profit,
    COUNT(DISTINCT ca.ca_address_sk) AS distinct_addresses,
    (SELECT COUNT(*) FROM customer_demographics cd 
     WHERE cd.cd_dep_count > 2 AND cd.cd_credit_rating IN ('Fair', 'Good')) AS high_dependency_demographics
FROM 
    warehouse w
LEFT JOIN 
    store s ON w.w_warehouse_sk = s.s_warehouse_sk
LEFT JOIN 
    store_sales ss ON s.s_store_sk = ss.ss_store_sk
LEFT JOIN 
    RankedSales rs ON ss.ss_item_sk = rs.ws_item_sk
LEFT JOIN 
    reason r ON rs.ws_order_number = r.r_reason_sk
LEFT JOIN 
    customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE 
    w.w_state IN ('CA', 'NY') 
    AND EXISTS (SELECT 1 
                FROM store_returns sr 
                WHERE sr.sr_item_sk = ss.ss_item_sk AND sr.sr_return_quantity > 0
                HAVING COUNT(*) > 5)
GROUP BY 
    w.w_warehouse_name, w.w_city
ORDER BY 
    total_refunds DESC, avg_female_single_sales DESC
LIMIT 10;
