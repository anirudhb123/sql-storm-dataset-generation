
WITH SaleSummary AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ws.web_site_id,
        ws.web_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_id, ca.ca_city, ws.web_site_id, ws.web_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.total_sales) AS total_sales,
        COUNT(ss.order_count) AS total_orders,
        RANK() OVER (ORDER BY SUM(ss.total_sales) DESC) AS sales_rank
    FROM 
        SaleSummary ss
    JOIN 
        customer c ON ss.c_customer_id = c.c_customer_id
    GROUP BY 
        c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.total_orders,
    ca.ca_city,
    ca.ca_state,
    ws.web_name
FROM 
    TopCustomers tc
JOIN 
    SaleSummary ss ON tc.c_customer_id = ss.c_customer_id
JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_site ws ON ss.web_site_id = ws.web_site_id
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
