
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.order_count
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.sales_rank <= 10
),
SalesBreakdown AS (
    SELECT 
        t.d_year,
        SUM(ws.ws_ext_sales_price) AS total_yearly_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ARRAY_AGG(DISTINCT c.c_customer_id) AS customer_ids
    FROM 
        web_sales ws
    JOIN 
        date_dim t ON ws.ws_sold_date_sk = t.d_date_sk
    WHERE 
        t.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        t.d_year
)

SELECT 
    t.d_year,
    tb.total_yearly_sales,
    tb.total_orders,
    COALESCE(tc.total_sales, 0) AS top_customer_sales,
    COALESCE(tc.order_count, 0) AS top_customer_orders,
    CASE 
        WHEN tb.total_yearly_sales > 1000000 THEN 'High'
        WHEN tb.total_yearly_sales BETWEEN 500000 AND 1000000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    SalesBreakdown tb
LEFT JOIN 
    TopCustomers tc ON tb.customer_ids && ARRAY[tc.customer_id]
JOIN 
    date_dim t ON tb.d_year = t.d_year
ORDER BY 
    t.d_year;
