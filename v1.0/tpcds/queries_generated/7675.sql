
WITH CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_qty) AS total_return_qty
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), 
StoreSales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales_amt,
        SUM(ss_quantity) AS total_sales_qty
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
), 
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(ss.total_sales_amt, 0) AS total_sales_amt,
        COALESCE(ss.total_sales_qty, 0) AS total_sales_qty
    FROM 
        item i
    LEFT JOIN 
        CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
    LEFT JOIN 
        StoreSales ss ON i.i_item_sk = ss.ss_item_sk
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.return_count,
    id.total_return_amt,
    id.total_sales_amt,
    id.total_sales_qty,
    CASE 
        WHEN id.total_sales_qty = 0 THEN 0 
        ELSE (id.total_return_amt / id.total_sales_qty) * 100 
    END AS return_rate
FROM 
    ItemDetails id
WHERE 
    id.total_sales_amt > 0
ORDER BY 
    return_rate DESC
LIMIT 10;
