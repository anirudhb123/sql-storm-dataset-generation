
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank <= 10
    GROUP BY 
        rs.ws_item_sk, rs.total_sales, i.i_item_desc, i.i_current_price, i.i_brand, i.i_category
    ORDER BY 
        rs.total_sales DESC
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
)
SELECT 
    ti.i_item_desc,
    ti.i_current_price,
    ti.total_sales,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    (ti.total_sales - COALESCE(cr.total_return_amt, 0)) AS net_sales,
    CASE 
        WHEN (ti.total_sales - COALESCE(cr.total_return_amt, 0)) < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_loss_status
FROM 
    TopItems ti
LEFT JOIN 
    CustomerReturns cr ON ti.ws_item_sk = cr.sr_item_sk
WHERE 
    ti.total_orders > 5
ORDER BY 
    net_sales DESC;
