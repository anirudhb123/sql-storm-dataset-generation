
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank_by_return
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk, sr_customer_sk
), MaxReturns AS (
    SELECT 
        rr.sr_item_sk,
        rr.sr_customer_sk,
        rr.total_return_quantity
    FROM 
        RankedReturns rr
    WHERE 
        rr.rank_by_return = 1
), ItemStats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(CASE WHEN ws.ws_quantity = 0 THEN NULL ELSE ws.ws_quantity END) AS avg_order_qty
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
), ReturnAnalysis AS (
    SELECT 
        is.i_item_sk,
        is.i_item_id,
        COALESCE(mr.total_return_quantity, 0) AS total_return_quantity,
        is.total_orders,
        is.total_sales,
        is.avg_order_qty,
        CASE 
            WHEN is.total_sales > 0 THEN ROUND(COALESCE(mr.total_return_quantity, 0) * 100.0 / is.total_sales, 2)
            ELSE 0
        END AS return_rate_pct
    FROM 
        ItemStats is
    LEFT JOIN 
        MaxReturns mr ON is.i_item_sk = mr.sr_item_sk
), ItemPerformance AS (
    SELECT 
        ra.i_item_id,
        ra.total_return_quantity,
        ra.total_orders,
        ra.total_sales,
        ra.avg_order_qty,
        ra.return_rate_pct,
        CASE 
            WHEN ra.return_rate_pct > 10 THEN 'High Return'
            WHEN ra.return_rate_pct BETWEEN 5 AND 10 THEN 'Moderate Return'
            ELSE 'Low Return'
        END AS return_class
    FROM 
        ReturnAnalysis ra
)
SELECT 
    ip.i_item_id,
    ip.total_return_quantity,
    ip.total_orders,
    ip.total_sales,
    ip.avg_order_qty,
    ip.return_rate_pct,
    ip.return_class
FROM 
    ItemPerformance ip
WHERE 
    ip.total_orders IS NOT NULL
    AND ip.return_rate_pct IS NOT NULL
ORDER BY 
    ip.return_rate_pct DESC;
