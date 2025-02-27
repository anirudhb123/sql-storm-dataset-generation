
WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.ws_order_number,
        o.ws_ship_date_sk,
        o.ws_item_sk,
        o.ws_quantity,
        o.ws_net_profit,
        1 AS level
    FROM 
        web_sales o
    WHERE 
        o.ws_ship_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales)

    UNION ALL

    SELECT 
        o.ws_order_number,
        o.ws_ship_date_sk,
        o.ws_item_sk,
        o.ws_quantity,
        o.ws_net_profit,
        oh.level + 1
    FROM 
        web_sales o
    INNER JOIN 
        OrderHierarchy oh ON o.ws_order_number = oh.ws_order_number
    WHERE 
        oh.level < 5
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        SUM(ws_quantity) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk
),
SalesWithReturns AS (
    SELECT 
        is.i_item_sk,
        is.total_sales,
        is.avg_net_profit,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        cr.total_returns
    FROM 
        ItemSales is
    LEFT JOIN 
        CustomerReturns cr ON is.i_item_sk = (SELECT sr_item_sk FROM store_returns WHERE sr_customer_sk = cr.sr_customer_sk LIMIT 1)
),
FinalReport AS (
    SELECT 
        wh.w_warehouse_id,
        SUM(swr.total_sales) AS total_sales,
        SUM(swr.total_return_amt) AS total_return_amt,
        COUNT(DISTINCT oh.ws_order_number) AS total_orders
    FROM 
        warehouse wh
    LEFT JOIN 
        web_sales ws ON wh.w_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN 
        SalesWithReturns swr ON ws.ws_item_sk = swr.i_item_sk
    LEFT JOIN 
        OrderHierarchy oh ON oh.ws_order_number = ws.ws_order_number
    GROUP BY 
        wh.w_warehouse_id
)
SELECT 
    fr.w_warehouse_id,
    fr.total_sales,
    fr.total_return_amt,
    fr.total_orders,
    fr.total_sales - fr.total_return_amt AS net_profit,
    CASE 
        WHEN fr.total_orders = 0 THEN NULL
        ELSE fr.total_sales / fr.total_orders
    END AS avg_sales_per_order
FROM 
    FinalReport fr
WHERE 
    fr.total_sales > (SELECT AVG(total_sales) FROM FinalReport)
ORDER BY 
    net_profit DESC;
