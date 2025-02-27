
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
), 
ReturnSales AS (
    SELECT
        sr.returning_customer_sk,
        SUM(COALESCE(sr_returned_amt, 0)) AS total_return_amt,
        COUNT(sr_order_number) AS return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.returning_customer_sk
), 
SalesBalance AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales - COALESCE(rs.total_return_amt, 0) AS net_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    LEFT JOIN 
        ReturnSales rs ON cs.c_customer_sk = rs.returning_customer_sk
)

SELECT 
    CASE 
        WHEN net_sales > 10000 THEN 'Top Customer'
        WHEN net_sales BETWEEN 1000 AND 10000 THEN 'Middle Customer'
        ELSE 'Low Value Customer' 
    END AS customer_category,
    s.c_customer_id,
    s.net_sales,
    s.order_count,
    COALESCE(d.d_day_name, 'Unknown') AS last_order_day
FROM 
    SalesBalance s
LEFT JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_ship_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = s.c_customer_sk)
WHERE 
    s.net_sales IS NOT NULL
ORDER BY 
    s.sales_rank
FETCH FIRST 50 ROWS ONLY;

