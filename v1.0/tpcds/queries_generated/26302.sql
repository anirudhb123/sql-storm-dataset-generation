
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        STRING_AGG(DISTINCT CONCAT_WS(' ', ws.ws_order_number, DATE_FORMAT(d.d_date, '%Y-%m-%d')), ', ') AS order_details
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) as sales_rank
    FROM
        CustomerSales
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    tc.total_sales,
    tc.order_count,
    tc.order_details
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_customer_sk = c.c_customer_sk
WHERE
    tc.sales_rank <= 10
ORDER BY
    tc.total_sales DESC;
