
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TotalReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_sk,
        item.i_product_name,
        COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS total_sales,
        COALESCE(tr.total_return_qty, 0) AS total_returns
    FROM 
        item
    LEFT JOIN 
        web_sales ws ON item.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        TotalReturns tr ON item.i_item_sk = tr.sr_item_sk
    WHERE 
        item.i_current_price IS NOT NULL 
    GROUP BY 
        item.i_item_sk, item.i_product_name
    HAVING 
        total_sales > 0
)
SELECT 
    ti.i_product_name,
    ti.total_sales,
    ti.total_returns,
    (ti.total_sales - ti.total_returns) AS net_sales,
    CASE 
        WHEN ti.total_returns > 0 THEN ROUND(CAST(ti.total_returns AS decimal) / NULLIF(ti.total_sales, 0), 2)
        ELSE 0
    END AS return_ratio,
    r.price_rank
FROM 
    TopItems ti
LEFT JOIN 
    RankedSales r ON ti.i_item_sk = r.ws_item_sk
WHERE 
    r.price_rank = 1
ORDER BY 
    net_sales DESC
LIMIT 10;
