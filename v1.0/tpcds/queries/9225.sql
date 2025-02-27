
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales,
        rs.ws_item_sk
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    ta.i_item_id,
    ta.i_item_desc,
    ta.total_quantity,
    ta.total_sales,
    COALESCE((SELECT COUNT(DISTINCT sr.sr_ticket_number) FROM store_returns sr WHERE sr.sr_item_sk = ta.ws_item_sk), 0) AS return_count,
    (SELECT COUNT(DISTINCT cc.cc_call_center_sk) FROM call_center cc 
     JOIN customer c ON cc.cc_call_center_sk = c.c_current_addr_sk
     WHERE c.c_current_addr_sk IN (SELECT DISTINCT sr.sr_addr_sk FROM store_returns sr WHERE sr.sr_item_sk = ta.ws_item_sk)) AS return_analysis
FROM 
    TopItems ta
ORDER BY 
    ta.total_sales DESC;
