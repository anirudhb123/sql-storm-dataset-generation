
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        c.total_sales,
        c.order_count,
        c.unique_items,
        RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.order_count,
    tc.unique_items,
    tc.sales_rank,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = tc.customer_id)
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_id = tc.customer_id)
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
