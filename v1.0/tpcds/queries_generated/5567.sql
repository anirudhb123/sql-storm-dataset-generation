
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
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458502 AND 2458532 -- Range of dates
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        cs.total_sales,
        cs.order_count,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_education_status
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    WHERE 
        cs.total_sales > 1000 -- High value threshold
),
CustomerInfo AS (
    SELECT 
        hvc.customer_id,
        hvc.first_name,
        hvc.last_name,
        hvc.total_sales,
        hvc.order_count,
        hvc.cd_marital_status,
        hvc.cd_gender,
        hvc.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY hvc.cd_gender ORDER BY hvc.total_sales DESC) AS rank
    FROM 
        HighValueCustomers hvc
)
SELECT 
    customer_id,
    first_name,
    last_name,
    total_sales,
    order_count,
    cd_marital_status,
    cd_gender,
    cd_education_status
FROM 
    CustomerInfo
WHERE 
    rank <= 10 -- Top 10 customers by gender
ORDER BY 
    cd_gender, total_sales DESC;
