
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id
), TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
), PopularItems AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        TopCustomers tc ON ws.ws_bill_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = tc.customer_id)
    GROUP BY 
        ws.ws_item_sk
    ORDER BY 
        order_count DESC
    LIMIT 5
)
SELECT 
    pi.ws_item_sk,
    i.i_item_desc,
    pi.order_count
FROM 
    PopularItems pi
JOIN 
    item i ON pi.ws_item_sk = i.i_item_sk
ORDER BY 
    pi.order_count DESC;
