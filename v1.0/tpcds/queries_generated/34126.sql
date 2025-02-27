
WITH RECURSIVE SalesTrends AS (
    SELECT 
        ws_sold_date_sk, 
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
    UNION ALL
    SELECT 
        d.d_date_sk,
        SUM(ws.ws_net_paid) 
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_date_sk > (SELECT MIN(ws_sold_date_sk) FROM web_sales)
    GROUP BY 
        d.d_date_sk
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesWithReturns AS (
    SELECT 
        c.c_customer_sk, 
        COALESCE(st.total_sales, 0) AS sales_total, 
        COALESCE(cr.return_count, 0) AS total_returns, 
        COALESCE(cr.total_return_amt, 0) AS return_amt
    FROM 
        customer c
    LEFT JOIN 
        (SELECT d_date_sk, SUM(total_sales) AS total_sales 
         FROM SalesTrends 
         GROUP BY d_date_sk) st ON st.d_date_sk = c.c_first_sales_date_sk
    LEFT JOIN 
        CustomerReturns cr ON cr.sr_customer_sk = c.c_customer_sk
)
SELECT 
    c.c_customer_id, 
    s.sales_total,
    s.total_returns,
    s.return_amt,
    FORMAT((s.sales_total - s.return_amt), 2) AS net_sales,
    CASE 
        WHEN s.sales_total IS NULL OR s.sales_total = 0 THEN 'No Sales'
        WHEN s.return_amt > s.sales_total THEN 'High Returns'
        ELSE 'Normal'
    END AS sales_status
FROM 
    SalesWithReturns s
JOIN 
    customer c ON c.c_customer_sk = s.c_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
    AND (s.total_returns > 0 OR s.sales_total > 1000)
ORDER BY 
    net_sales DESC
LIMIT 50;
