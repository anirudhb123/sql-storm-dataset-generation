
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        AVG(sr_return_quantity) AS avg_return_qty
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cr.total_returns,
        cr.total_return_amt,
        cr.avg_return_qty
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    WHERE 
        cr.total_returns > 5
),
DateRange AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        MIN(ds.ws_sold_date_sk) AS first_sale_date,
        MAX(ds.ws_sold_date_sk) AS last_sale_date
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ds ON ds.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    tc.c_customer_id,
    tr.year_month,
    COALESCE(tr.total_sales, 0) AS total_sales,
    COALESCE(tr.total_qty, 0) AS total_qty,
    CASE 
        WHEN COALESCE(tr.total_sales, 0) > 1000 THEN 'High Value'
        WHEN COALESCE(tr.total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    ROW_NUMBER() OVER (PARTITION BY tc.c_customer_id ORDER BY total_sales DESC) AS sales_rank
FROM 
    TopCustomers tc
LEFT JOIN (
    SELECT 
        CONCAT(d.d_year, '-', d.d_month_seq) AS year_month,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_quantity) AS total_qty
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
) tr ON 1=1
WHERE 
    EXISTS (
        SELECT 1 
        FROM CustomerReturns cr 
        WHERE cr.sr_customer_sk = tc.total_returns
    )
ORDER BY 
    tc.c_customer_id, sales_rank;
