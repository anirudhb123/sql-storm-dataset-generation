
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.full_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) as sales_rank
    FROM 
        CustomerSales cs
),
AddressInfo AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
)
SELECT 
    tc.full_name,
    tc.total_sales,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country
FROM 
    TopCustomers tc
JOIN 
    AddressInfo ai ON tc.full_name = ai.full_name
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
