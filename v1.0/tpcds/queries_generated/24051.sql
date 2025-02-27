
WITH RankedSales AS (
    SELECT 
        w.warehouse_name,
        i.item_id,
        s.ss_sales_price,
        s.ss_quantity,
        RANK() OVER (PARTITION BY w.warehouse_name ORDER BY SUM(s.ss_ext_sales_price) DESC) AS rnk
    FROM 
        store_sales s
    JOIN 
        warehouse w ON s.ss_store_sk = w.w_warehouse_sk
    JOIN 
        item i ON s.ss_item_sk = i.i_item_sk
    WHERE 
        s.ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
    GROUP BY 
        w.warehouse_name, i.item_id, s.ss_sales_price, s.ss_quantity
),
ReturnStats AS (
    SELECT 
        s.ss_store_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM 
        store_returns sr
    JOIN 
        store s ON sr.sr_store_sk = s.s_store_sk
    WHERE 
        sr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
    GROUP BY 
        s.ss_store_sk
),
HighReturnItems AS (
    SELECT 
        r.rnk,
        r.warehouse_name,
        r.item_id
    FROM 
        RankedSales r
    JOIN 
        ReturnStats rs ON r.warehouse_name = (SELECT w.warehouse_name FROM warehouse w WHERE w.w_warehouse_sk = rs.ss_store_sk)
    WHERE 
        rs.total_returns > 0
)
SELECT 
    COALESCE(i.i_product_name, 'Unknown') AS product_name,
    SUM(s.ss_quantity) AS total_quantity_sold,
    COALESCE(SUM(sr_return_quantity), 0) AS total_quantity_returned,
    CASE 
        WHEN SUM(s.ss_quantity) = 0 THEN NULL 
        ELSE SUM(sr_return_quantity) / SUM(s.ss_quantity) 
    END AS return_rate
FROM 
    store_sales s 
LEFT JOIN 
    store_returns sr ON s.ss_ticket_number = sr.sr_ticket_number 
LEFT JOIN 
    item i ON s.ss_item_sk = i.i_item_sk 
WHERE 
    s.ss_item_sk IN (SELECT item_id FROM HighReturnItems)
GROUP BY 
    i.i_product_name 
HAVING 
    SUM(s.ss_quantity) > 0 
ORDER BY 
    return_rate DESC;
