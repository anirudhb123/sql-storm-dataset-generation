
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        0 AS level,
        CAST(c.c_first_name AS VARCHAR(200)) AS path
    FROM 
        customer c
    WHERE 
        c.c_email_address IS NOT NULL

    UNION ALL

    SELECT 
        w.w_warehouse_sk,
        NULL,
        NULL,
        NULL,
        sh.level + 1,
        CONCAT(sh.path, ' > ', w.w_warehouse_name)
    FROM 
        warehouse w
    JOIN SalesHierarchy sh ON w.w_warehouse_sk = sh.c_customer_sk
    WHERE 
        sh.level < 3 -- Limit recursion to 3 levels
),
TotalReturns AS (
    SELECT 
        COALESCE(SUM(sr_return_quantity), 0) AS total_returned,
        COUNT(DISTINCT sr_item_sk) AS unique_items_returned
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk > (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '30 days')
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.c_email_address,
    wh.path,
    COALESCE(tr.total_returned, 0) AS total_returned_items,
    COALESCE(wss.total_orders, 0) AS total_orders,
    COALESCE(wss.total_revenue, 0.00) AS total_revenue,
    COALESCE(wss.avg_net_profit, 0.00) AS avg_net_profit
FROM 
    SalesHierarchy ch
LEFT JOIN 
    TotalReturns tr ON ch.c_customer_sk = tr.unique_items_returned
LEFT JOIN 
    WebSalesSummary wss ON ch.c_customer_sk = wss.ws_bill_customer_sk
ORDER BY 
    total_revenue DESC, 
    total_orders DESC
LIMIT 100;
