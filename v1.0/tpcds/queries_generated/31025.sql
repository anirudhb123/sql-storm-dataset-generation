
WITH RECURSIVE MonthlySales AS (
    SELECT 
        d_year, 
        d_month_seq, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales w ON d.d_date_sk = w.ws_sold_date_sk
    WHERE 
        d_year >= 2020
    GROUP BY 
        d_year, d_month_seq
    HAVING 
        SUM(ws_ext_sales_price) > 10000
    UNION ALL
    SELECT 
        ms.d_year, 
        ms.d_month_seq, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        MonthlySales ms
    JOIN 
        web_sales w ON ms.d_year = EXTRACT(YEAR FROM w.ws_sold_date) 
        AND ms.d_month_seq = EXTRACT(MONTH FROM w.ws_sold_date)
    GROUP BY 
        ms.d_year, ms.d_month_seq
),
TopCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws_net_paid_inc_tax) AS total_paid
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws_net_paid_inc_tax) > 500
),
SalesByCustomer AS (
    SELECT 
        tc.c_customer_id, 
        m.d_year, 
        m.d_month_seq, 
        tc.total_paid, 
        m.total_sales,
        CASE 
            WHEN m.total_sales > 0 THEN (tc.total_paid / m.total_sales) * 100 
            ELSE 0 
        END AS percentage_sales
    FROM 
        TopCustomers tc
    JOIN 
        MonthlySales m ON tc.total_paid >= (SELECT AVG(total_sales) FROM MonthlySales)
),
FinalReport AS (
    SELECT 
        s.c_customer_id,
        s.total_paid,
        s.percentage_sales,
        ROW_NUMBER() OVER (ORDER BY s.percentage_sales DESC) AS rank
    FROM 
        SalesByCustomer s
)
SELECT 
    f.c_customer_id,
    f.total_paid,
    f.percentage_sales
FROM 
    FinalReport f
WHERE 
    f.rank <= 10
ORDER BY 
    f.total_paid DESC;
