
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        1 AS sales_level
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0

    UNION ALL

    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        cs_quantity,
        cs_net_profit,
        sales_level + 1
    FROM 
        catalog_sales cs
    JOIN 
        SalesCTE s ON cs_item_sk = s.ws_item_sk 
    WHERE 
        cs_sales_price > 0
        AND sales_level < 10
),
CustomerPerformance AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_web_orders,
        SUM(ws_net_profit) AS total_web_profit,
        AVG(ws_sales_price) AS avg_web_sales_price,
        MAX(ws_sales_price) AS max_web_sales_price,
        STRING_AGG(DISTINCT sm_carrier || ' - ' || sm_type, ', ') AS shipping_methods,
        COUNT(DISTINCT ss_store_sk) AS total_stores_shipped_to
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cp.c_customer_sk,
    cp.total_web_orders,
    cp.total_web_profit,
    cp.avg_web_sales_price,
    cp.max_web_sales_price,
    cp.shipping_methods,
    COALESCE(sp.total_store_orders, 0) AS total_store_orders,
    COALESCE(sp.total_store_profit, 0) AS total_store_profit,
    COALESCE(sp.avg_store_sales_price, 0) AS avg_store_sales_price
FROM 
    CustomerPerformance cp
LEFT JOIN (
    SELECT 
        ss.ss_store_sk AS store_sk,
        COUNT(ss.ss_ticket_number) AS total_store_orders,
        SUM(ss.ss_net_profit) AS total_store_profit,
        AVG(ss.ss_sales_price) AS avg_store_sales_price
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
) sp ON sp.store_sk = cp.c_customer_sk
WHERE 
    cp.total_web_orders > 5
    OR cp.total_web_profit IS NOT NULL
ORDER BY 
    cp.total_web_profit DESC NULLS LAST
LIMIT 100;
