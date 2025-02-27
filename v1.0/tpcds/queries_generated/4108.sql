
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.customer_sk, 
        c.first_name, 
        c.last_name,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs 
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.first_name,
    tc.last_name,
    COALESCE(NULLIF(tc.sales_rank, 1), 'Not Top Customer') AS customer_rank,
    AVG(ws.ws_sales_price) AS avg_unit_price,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_tax) AS total_tax_collected
FROM 
    TopCustomers tc 
LEFT JOIN 
    web_sales ws ON tc.customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    tc.first_name, 
    tc.last_name, 
    tc.sales_rank
HAVING 
    COUNT(ws.ws_order_number) > 0
ORDER BY 
    tc.sales_rank
LIMIT 10;
