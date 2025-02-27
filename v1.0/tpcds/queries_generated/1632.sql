
WITH RankedSales AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) 
                                FROM date_dim d 
                                WHERE d.d_year = 2023
                                AND d.d_month_seq BETWEEN 1 AND 12)
),
TotalReturns AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
FinalSales AS (
    SELECT 
        rs.s_store_sk,
        rs.s_store_name,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        COALESCE(tr.total_return_qty, 0) AS total_return_qty,
        COALESCE(tr.total_return_amt, 0) AS total_return_amt
    FROM 
        RankedSales rs
    LEFT JOIN 
        TotalReturns tr ON rs.s_store_sk = tr.sr_store_sk
    GROUP BY 
        rs.s_store_sk, rs.s_store_name
)
SELECT 
    fs.s_store_name,
    fs.total_sales,
    fs.total_return_qty,
    fs.total_return_amt,
    (fs.total_sales - fs.total_return_amt) AS net_sales,
    CASE 
        WHEN fs.total_sales > 0 THEN (fs.total_return_qty * 100.0 / fs.total_sales) 
        ELSE NULL 
    END AS return_percentage
FROM 
    FinalSales fs
WHERE 
    fs.total_sales > 1000
ORDER BY 
    net_sales DESC
LIMIT 10;
