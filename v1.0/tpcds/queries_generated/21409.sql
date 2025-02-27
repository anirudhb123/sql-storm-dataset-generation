
WITH RankedCustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_birth_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
    GROUP BY 
        c.c_customer_id, c.c_birth_year
),
RecentWebReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(wr.wr_order_number) AS total_return_count
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk > (
            SELECT MAX(d.d_date_sk)
            FROM date_dim d 
            WHERE 
                d.d_date = CURRENT_DATE - INTERVAL '30 day'
        )
    GROUP BY 
        wr.wr_returning_customer_sk
)
SELECT 
    rcs.c_customer_id,
    rcs.total_sales,
    COALESCE(rwr.total_return_amt, 0) AS total_return_amt,
    rcs.order_count,
    rcs.sales_rank
FROM 
    RankedCustomerSales rcs
FULL OUTER JOIN 
    RecentWebReturns rwr ON rcs.c_customer_id = rwr.wr_returning_customer_sk
WHERE 
    rcs.total_sales > 5000 
    OR rwr.total_return_amt IS NOT NULL
ORDER BY 
    CASE WHEN rcs.total_sales IS NULL THEN 1 ELSE 0 END, 
    rcs.total_sales DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;

SELECT 
    SUM(COALESCE(total_sales, 0)) AS aggregate_sales,
    COUNT(DISTINCT c_customer_id) AS unique_customers
FROM 
    RankedCustomerSales
WHERE 
    sales_rank <= 10
UNION ALL
SELECT 
    COUNT(1) * -1 AS aggregate_sales,
    COUNT(DISTINCT wr_returning_customer_sk) AS unique_customers
FROM 
    web_returns
WHERE 
    wr_returned_date_sk BETWEEN 20200101 AND 20201231;
