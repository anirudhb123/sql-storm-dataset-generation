
WITH RankedSales AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                                   (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        w.w_warehouse_name
),
TopWarehouses AS (
    SELECT 
        warehouse_name,
        total_sales
    FROM 
        RankedSales 
    WHERE 
        sales_rank <= 5
),
CustomerReturns AS (
    SELECT
        sr_store_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(*) AS total_returns
    FROM
        store_returns
    GROUP BY
        sr_store_sk
)
SELECT 
    t.warehouse_name,
    t.total_sales,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN cr.total_returns IS NOT NULL AND cr.total_returns > 0 THEN 
            (t.total_sales + COALESCE(cr.total_return_amount, 0)) / cr.total_returns
        ELSE 
            t.total_sales
    END AS adjusted_sales
FROM 
    TopWarehouses t
LEFT JOIN 
    CustomerReturns cr ON t.warehouse_name = (SELECT w.w_warehouse_name FROM warehouse w WHERE w.w_warehouse_sk = cr.sr_store_sk)
ORDER BY 
    adjusted_sales DESC;

