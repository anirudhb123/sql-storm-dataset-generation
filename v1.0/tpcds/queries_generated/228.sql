
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT s.ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT s.ss_sold_date_sk) AS active_days
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        c.c_birth_year < 1980
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_transactions,
        cs.active_days,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 1000
),
SalesDetail AS (
    SELECT 
        t.c_customer_id,
        t.total_sales,
        COALESCE(t.total_transactions, 0) AS total_transactions,
        COALESCE(t.active_days, 0) AS active_days,
        wd.d_week_seq,
        wd.d_year,
        wd.d_month_seq
    FROM 
        TopCustomers t
    LEFT JOIN 
        date_dim wd ON wd.d_date_sk IN (SELECT DISTINCT ws.ws_sold_date_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = t.c_customer_id)
),
FinalReport AS (
    SELECT 
        sd.c_customer_id,
        sd.total_sales,
        sd.total_transactions,
        sd.active_days,
        sd.d_week_seq,
        sd.d_year,
        sd.d_month_seq,
        CASE 
            WHEN sd.total_sales > 5000 THEN 'Platinum'
            WHEN sd.total_sales BETWEEN 1000 AND 5000 THEN 'Gold'
            ELSE 'Silver'
        END AS customer_category
    FROM 
        SalesDetail sd
)
SELECT 
    f.c_customer_id,
    f.total_sales,
    f.total_transactions,
    f.active_days,
    f.customer_category,
    COALESCE(wp.wp_id, 'No Web Activity') AS website_interaction
FROM 
    FinalReport f
LEFT JOIN 
    web_page wp ON wp.wp_customer_sk IN (SELECT DISTINCT ws.ws_bill_customer_sk FROM web_sales ws WHERE f.c_customer_id = ws.ws_bill_customer_sk)
WHERE 
    f.d_year = 2023 AND 
    f.active_days > 10
ORDER BY 
    f.total_sales DESC
FETCH FIRST 50 ROWS ONLY;
