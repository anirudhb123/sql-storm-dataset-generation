
WITH RankedSales AS (
    SELECT 
        ws_b.bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY DATE_TRUNC('month', date_dim.d_date) ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
    WHERE 
        date_dim.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        ws.ws_bill_customer_sk, c.c_first_name, c.c_last_name, date_dim.d_date
)
SELECT 
    sales.bill_customer_sk,
    sales.c_first_name,
    sales.c_last_name,
    sales.total_sales,
    date_dim.d_month AS sales_month
FROM 
    RankedSales sales
JOIN 
    date_dim ON DATE_TRUNC('month', date_dim.d_date) = DATE_TRUNC('month', CURRENT_DATE)
WHERE 
    sales_rank <= 10
ORDER BY 
    sales.total_sales DESC;
