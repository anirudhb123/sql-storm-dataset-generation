
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        c_first_name,
        c_last_name,
        total_sales,
        order_count,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    COUNT(ws.ws_item_sk) AS items_purchased,
    AVG(ws.ws_sales_price) AS average_item_price
FROM 
    TopCustomers tc
JOIN 
    web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
WHERE 
    tc.sales_rank <= 100
GROUP BY 
    tc.c_customer_id, tc.c_first_name, tc.c_last_name, tc.total_sales, tc.order_count
ORDER BY 
    tc.total_sales DESC;
