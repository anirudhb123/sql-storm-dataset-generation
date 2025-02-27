
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL AND 
        c.c_email_address LIKE '%@example.com'
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
SalesAnalysis AS (
    SELECT 
        r.web_site_sk,
        r.ws_order_number,
        r.total_sales,
        COALESCE(r.sales_rank, 0) AS sales_rank,
        CASE 
            WHEN r.total_sales > 1000 THEN 'High'
            WHEN r.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 5
),
WebReturnDetails AS (
    SELECT 
        wr.wr_order_number,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(wr.wr_return_quantity) AS total_return_qty
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_order_number
),
FinalAnalysis AS (
    SELECT 
        sa.web_site_sk,
        sa.ws_order_number,
        sa.total_sales,
        sa.sales_category,
        COALESCE(wr.total_return_amt, 0) AS total_return_amt,
        COALESCE(wr.total_return_qty, 0) AS total_return_qty,
        CASE 
            WHEN COALESCE(wr.total_return_amt, 0) = 0 THEN 'No Returns'
            WHEN COALESCE(wr.total_return_qty, 0) > 0 AND sa.total_sales > 0 THEN 'Returns Made'
            ELSE 'Undefined'
        END AS return_status
    FROM 
        SalesAnalysis sa
    LEFT JOIN 
        WebReturnDetails wr ON sa.ws_order_number = wr.wr_order_number
)
SELECT 
    f.web_site_sk,
    f.ws_order_number,
    f.total_sales,
    f.sales_category,
    f.total_return_amt,
    f.total_return_qty,
    f.return_status
FROM 
    FinalAnalysis f
WHERE 
    f.return_status IS NOT NULL
ORDER BY 
    f.total_sales DESC;
