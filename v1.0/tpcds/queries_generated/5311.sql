
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT CASE WHEN c.c_gender = 'M' THEN ws.ws_bill_customer_sk END) AS male_customers,
        COUNT(DISTINCT CASE WHEN c.c_gender = 'F' THEN ws.ws_bill_customer_sk END) AS female_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020 AND d.d_year <= 2023
    GROUP BY 
        d.d_year, d.d_month_seq
),
TopMonths AS (
    SELECT 
        d_year, 
        d_month_seq, 
        total_sales,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)

SELECT 
    t.d_year,
    t.d_month_seq,
    t.total_sales,
    t.male_customers,
    t.female_customers
FROM 
    SalesSummary s
JOIN 
    TopMonths t ON s.d_year = t.d_year AND s.d_month_seq = t.d_month_seq
WHERE 
    t.sales_rank <= 3
ORDER BY 
    t.d_year, t sales_rank;
