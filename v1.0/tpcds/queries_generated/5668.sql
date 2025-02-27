
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.num_orders,
        cs.last_purchase_date,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.num_orders,
    tc.last_purchase_date,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    tc.sales_rank <= 100
ORDER BY 
    tc.total_sales DESC;
