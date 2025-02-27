
WITH RankedSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01') AND 
                                  (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-31')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_sales
    FROM 
        RankedSales r
    WHERE 
        r.total_sales > (SELECT AVG(total_sales) FROM RankedSales)
),
ReturnsSummary AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_amt) AS total_returns,
        COUNT(sr_return_quantity) AS total_return_count
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
FinalReport AS (
    SELECT 
        h.c_first_name,
        h.c_last_name,
        h.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_count, 0) AS total_return_count,
        (h.total_sales - COALESCE(r.total_returns, 0)) AS net_sales
    FROM 
        HighValueCustomers h
    LEFT JOIN 
        ReturnsSummary r ON h.c_customer_sk = r.sr_returning_customer_sk
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.total_sales,
    f.total_returns,
    f.total_return_count,
    f.net_sales,
    CASE 
        WHEN f.net_sales > 10000 THEN 'High Value'
        WHEN f.net_sales BETWEEN 5000 AND 10000 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS value_category
FROM 
    FinalReport f
ORDER BY 
    f.net_sales DESC;
