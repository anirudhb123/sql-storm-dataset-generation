
WITH RECURSIVE MonthlySales AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        ws.ws_ext_sales_price AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY d.d_month_seq) AS month_rank
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023

    UNION ALL

    SELECT 
        d.d_year,
        d.d_month_seq,
        ws.ws_ext_sales_price AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY d.d_month_seq) AS month_rank
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        MonthlySales ms ON d.d_year = ms.d_year AND d.d_month_seq = ms.d_month_seq + 1
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
), CustomerReturns AS (
    SELECT 
        c.c_customer_sk, 
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
), TotalReturns AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        CASE 
            WHEN COALESCE(cr.total_return_amount, 0) > 0 THEN 'Yes'
            ELSE 'No'
        END AS return_flag
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.c_customer_sk
)
SELECT 
    ms.d_year,
    ms.d_month_seq,
    COUNT(DISTINCT tr.c_customer_sk) AS unique_customers,
    SUM(ms.total_sales) AS monthly_sales,
    SUM(tr.total_return_amount) AS monthly_returns,
    AVG(tr.total_return_quantity) AS avg_return_quantity,
    MAX(ms.total_sales) AS peak_sales
FROM 
    MonthlySales ms
LEFT JOIN 
    web_sales ws ON ws.ws_sold_date_sk = ms.d_month_seq
LEFT JOIN 
    TotalReturns tr ON tr.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    SUM(ms.total_sales) > 1000
GROUP BY 
    ms.d_year, ms.d_month_seq
ORDER BY 
    ms.d_year, ms.d_month_seq;
