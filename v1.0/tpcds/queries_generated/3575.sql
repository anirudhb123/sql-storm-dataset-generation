
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        c.c_country
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_country
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.total_sales,
        c.order_count,
        RANK() OVER (PARTITION BY c.c_country ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    tc.sales_rank,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
WHERE 
    tc.sales_rank <= 10
    AND ca.ca_state IN ('CA', 'TX', 'NY')
ORDER BY 
    total_sales DESC;
