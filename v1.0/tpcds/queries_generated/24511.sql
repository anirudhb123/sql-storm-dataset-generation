
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_sales_price,
        ws.web_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.web_sales_price DESC) AS sales_rank,
        CASE
            WHEN ws.web_sales_price IS NULL THEN 'No Sale'
            WHEN ws.web_sales_price < 0 THEN 'Refund'
            ELSE 'Sale'
        END AS sale_type
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 30
    AND 
        ws.ws_web_site_sk IN (
            SELECT w.web_site_sk 
            FROM web_site w 
            WHERE w.web_state = 'CA'
        )
), 
sales_with_details AS (
    SELECT 
        rs.web_site_sk,
        rs.web_sales_price,
        i.i_item_desc,
        inv.inv_quantity_on_hand,
        CASE 
            WHEN rs.sale_type = 'Refund' THEN 'Refund Processed'
            ELSE 'Sale Completed'
        END AS transaction_status
    FROM 
        ranked_sales rs
    LEFT JOIN 
        item i ON rs.web_item_sk = i.i_item_sk
    LEFT JOIN 
        inventory inv ON rs.web_item_sk = inv.inv_item_sk AND inv.inv_warehouse_sk = 1
    WHERE 
        rs.sales_rank <= 5
)
SELECT 
    swd.web_site_sk,
    COALESCE(swd.i_item_desc, 'Unknown Item') AS item_description,
    SUM(swd.web_sales_price) AS total_sales,
    AVG(swd.web_sales_price) AS avg_sales_price,
    COUNT(swd.transaction_status) FILTER (WHERE swd.transaction_status = 'Sale Completed') AS completed_sales,
    COUNT(swd.transaction_status) FILTER (WHERE swd.transaction_status = 'Refund Processed') AS refunded_sales
FROM 
    sales_with_details swd
GROUP BY 
    swd.web_site_sk
HAVING 
    total_sales > (SELECT AVG(total) FROM (
        SELECT SUM(ws_ext_sales_price) AS total 
        FROM web_sales 
        GROUP BY ws_web_site_sk) avg_totals) * 0.5
ORDER BY 
    total_sales DESC
LIMIT 10;
