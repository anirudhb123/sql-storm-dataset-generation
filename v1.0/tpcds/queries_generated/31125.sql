
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CombinedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_price,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        (SUM(ws.ws_ext_sales_price) - COALESCE(cr.total_return_amount, 0)) AS net_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        CustomerReturns cr ON ws.ws_item_sk = cr.sr_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        SUM(ws.ws_quantity) > 0
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    cs.total_quantity_sold,
    cs.total_sales_price,
    cs.total_returns,
    cs.total_return_amount,
    cs.net_sales,
    DENSE_RANK() OVER (ORDER BY cs.net_sales DESC) AS sales_rank
FROM 
    item i
JOIN 
    CombinedSales cs ON i.i_item_sk = cs.ws_item_sk
WHERE 
    (SELECT COUNT(*) FROM CombinedSales) > 1000
    AND (cs.total_returns IS NULL OR cs.total_returns < (SELECT AVG(total_returns) FROM CustomerReturns WHERE total_returns IS NOT NULL))
ORDER BY 
    sales_rank
LIMIT 50;
