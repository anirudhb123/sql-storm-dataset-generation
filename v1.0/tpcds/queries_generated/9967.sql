
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.bill_cdemo_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(ws.order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        cd.cd_education_status IN ('Bachelors', 'Masters') AND 
        ws.sold_date_sk BETWEEN 2451545 AND 2451910 -- Date range for sales (1st Jan 2020 - 31st Dec 2020)
    GROUP BY 
        ws.bill_customer_sk,
        ws.bill_cdemo_sk
),
TopCustomers AS (
    SELECT 
        bill_customer_sk,
        total_sales,
        total_orders
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    tc.total_sales,
    tc.total_orders,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY 
    tc.total_sales DESC;
