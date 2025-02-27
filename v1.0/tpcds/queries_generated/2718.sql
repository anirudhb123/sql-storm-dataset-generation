
WITH RankedSales AS (
    SELECT 
        ss.store_sk,
        ss.ticket_number,
        ss.item_sk,
        ss.sales_price,
        ROW_NUMBER() OVER (PARTITION BY ss.store_sk ORDER BY ss.sales_price DESC) AS rnk
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        sr.store_sk, 
        COUNT(sr.return_qty) AS return_count,
        SUM(sr.return_amount) AS total_return_amount
    FROM 
        store_returns sr
    LEFT JOIN 
        RankedSales rs ON sr.store_sk = rs.store_sk AND sr.item_sk = rs.item_sk
    GROUP BY 
        sr.store_sk
),
TotalSales AS (
    SELECT 
        s.store_sk, 
        SUM(ss.sales_price * ss.quantity) AS total_sales
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.store_sk = s.store_sk
    GROUP BY 
        s.store_sk
)
SELECT 
    s.store_sk, 
    COALESCE(ts.total_sales, 0) AS total_sales, 
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    (COALESCE(ts.total_sales, 0) - COALESCE(cr.total_return_amount, 0)) AS net_sales
FROM 
    store s
LEFT JOIN 
    TotalSales ts ON s.store_sk = ts.store_sk
LEFT JOIN 
    CustomerReturns cr ON s.store_sk = cr.store_sk
WHERE 
    s.store_sk IS NOT NULL
ORDER BY 
    net_sales DESC
LIMIT 10;
