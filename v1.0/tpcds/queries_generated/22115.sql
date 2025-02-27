
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COALESCE(NULLIF(CAST(DATE_PART('YEAR', d.d_date) AS INTEGER), 0), -1) AS sale_year,
        d.d_date AS sale_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = (SELECT MAX(d_year) FROM date_dim)
        AND cd.cd_marital_status = 'M'
        AND (cd.cd_credit_rating IS NULL OR cd.cd_credit_rating LIKE 'Excellent%')
    GROUP BY 
        c.c_customer_id, d.d_date
),
ReturnedSales AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_return_quantity) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
FinalSales AS (
    SELECT 
        r.c_customer_id,
        r.total_sales,
        COALESCE(rs.return_count, 0) AS return_count,
        (r.total_sales - COALESCE(rs.total_return_amt, 0)) AS net_sales,
        r.order_count
    FROM 
        RankedSales r
    LEFT JOIN 
        ReturnedSales rs ON r.c_customer_id = rs.sr_customer_sk
)
SELECT 
    f.c_customer_id,
    f.total_sales,
    f.return_count,
    f.net_sales,
    f.order_count,
    f.order_count * CASE WHEN f.net_sales > 0 THEN 1 ELSE 0 END AS sales_status,
    CASE 
        WHEN f.net_sales > 1000 THEN 'High Value'
        WHEN f.net_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    FinalSales f
WHERE 
    f.net_sales IS NOT NULL
    AND f.return_count < (SELECT AVG(return_count) FROM ReturnedSales)
ORDER BY 
    f.net_sales DESC
LIMIT 100;
