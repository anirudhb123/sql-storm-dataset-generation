
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws_order_number, 
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990 
        AND w.web_open_date_sk IS NOT NULL
    GROUP BY 
        ws.web_site_sk, 
        ws_order_number
),
FilteredReturns AS (
    SELECT 
        wr_return_quantity, 
        wr_order_number, 
        wr_return_amt_inc_tax
    FROM 
        web_returns wr
    WHERE 
        wr.return_quantity > 0 
        AND wr_return_amt_inc_tax IS NOT NULL
),
FinalSales AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_order_number,
        rs.total_sales,
        COALESCE(fr.wr_return_quantity, 0) AS total_returns,
        COALESCE(fr.wr_return_amt_inc_tax, 0) AS total_return_amt
    FROM 
        RankedSales rs
    LEFT JOIN 
        FilteredReturns fr ON rs.ws_order_number = fr.wr_order_number
    WHERE 
        rs.sales_rank = 1
)
SELECT 
    ws.web_site_id, 
    fs.total_sales, 
    fs.total_returns, 
    fs.total_return_amt,
    (fs.total_sales - fs.total_return_amt) AS net_sales,
    CASE 
        WHEN fs.total_sales IS NULL THEN 'No Sales'
        WHEN fs.total_sales > 10000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    FinalSales fs
JOIN 
    web_site ws ON fs.web_site_sk = ws.web_site_sk
WHERE 
    fs.total_sales > 5000 OR fs.total_returns > 0
UNION ALL
SELECT 
    'TOTALS' AS web_site_id, 
    SUM(total_sales), 
    SUM(total_returns), 
    SUM(total_return_amt),
    SUM(total_sales) - SUM(total_return_amt) AS net_sales,
    NULL AS sales_category
FROM 
    FinalSales
GROUP BY 
    CASE 
        WHEN COUNT(*) > 0 THEN 1 
        ELSE NULL 
    END;
