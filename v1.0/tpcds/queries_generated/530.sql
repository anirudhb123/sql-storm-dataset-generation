
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.total_sales
    FROM 
        customer c
    JOIN 
        RankedSales r ON c.c_customer_sk = r.ws_bill_customer_sk
    WHERE 
        r.sales_rank <= 10
),
SalesInfo AS (
    SELECT 
        t.d_year,
        t.d_month_seq,
        SUM(w.ws_ext_sales_price) AS monthly_sales
    FROM 
        web_sales w
    JOIN 
        date_dim t ON w.ws_sold_date_sk = t.d_date_sk
    GROUP BY 
        t.d_year, t.d_month_seq
),
MonthlyPerformance AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        monthly_sales,
        LEAD(monthly_sales, 1) OVER (ORDER BY d.d_year, d.d_month_seq) AS next_month_sales
    FROM 
        SalesInfo d
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    mp.d_year,
    mp.d_month_seq,
    mp.monthly_sales,
    (mp.monthly_sales - COALESCE(mp.next_month_sales, 0)) AS sales_change,
    COALESCE(NULLIF(tc.c_email_address, ''), 'Not provided') AS email_status
FROM 
    TopCustomers tc
LEFT JOIN 
    MonthlyPerformance mp ON mp.d_year = EXTRACT(YEAR FROM CURRENT_DATE) AND mp.d_month_seq = EXTRACT(MONTH FROM CURRENT_DATE)
ORDER BY 
    tc.total_sales DESC, mp.d_year DESC, mp.d_month_seq DESC;
