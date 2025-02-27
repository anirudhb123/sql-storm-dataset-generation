
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity_sold
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        rs.ws_item_sk
),
CombinedReturns AS (
    SELECT 
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amt) AS total_return_amt
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
FinalReport AS (
    SELECT 
        ti.i_item_id,
        ti.i_product_name,
        tsi.total_quantity_sold,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        (tsi.total_quantity_sold - COALESCE(cr.total_return_quantity, 0)) AS net_sales
    FROM 
        TopSellingItems tsi
    JOIN 
        item ti ON tsi.ws_item_sk = ti.i_item_sk
    LEFT JOIN 
        CombinedReturns cr ON ti.i_item_sk = cr.item_sk
)
SELECT 
    f.i_item_id,
    f.i_product_name,
    f.total_quantity_sold,
    f.total_return_quantity,
    f.total_return_amt,
    f.net_sales,
    CASE 
        WHEN f.net_sales < 0 THEN 'Negative Margin'
        WHEN f.net_sales = 0 THEN 'Break Even'
        ELSE 'Positive Margin'
    END AS sales_margin_status
FROM 
    FinalReport f
WHERE 
    f.net_sales IS NOT NULL
ORDER BY 
    f.net_sales DESC;
