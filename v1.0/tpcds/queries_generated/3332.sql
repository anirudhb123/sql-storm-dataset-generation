
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
FilteredReturns AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_quantity) AS total_return_qty
    FROM 
        web_returns 
    WHERE 
        wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        wr_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        i.i_product_name,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(fr.total_return_amt, 0) AS total_return_amt,
        COALESCE(fr.total_return_qty, 0) AS total_return_qty,
        (COALESCE(rs.total_sales, 0) - COALESCE(fr.total_return_amt, 0)) AS net_sales
    FROM 
        item i
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.sales_rank = 1
    LEFT JOIN 
        FilteredReturns fr ON i.i_item_sk = fr.wr_item_sk
)
SELECT 
    wd.warehouse_name,
    id.i_item_id,
    id.i_product_name,
    id.total_sales,
    id.total_return_amt,
    id.total_return_qty,
    id.net_sales,
    CASE 
        WHEN id.total_sales = 0 THEN 'No Sales'
        WHEN id.total_return_qty > 0 THEN 'Returned'
        ELSE 'Good'
    END AS sales_status
FROM 
    ItemDetails id
JOIN 
    warehouse wd ON id.i_item_sk % 10 = wd.w_warehouse_sk % 10
WHERE 
    id.net_sales > 0
ORDER BY 
    id.net_sales DESC
LIMIT 100;
