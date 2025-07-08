
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
RecentSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq >= 10)
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        CustomerData cd
    LEFT JOIN 
        RecentSales cs ON cd.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = cs.ws_bill_customer_sk)
)
SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_city,
    cd.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.order_count, 0) AS order_count,
    CONCAT('Customer ', cd.c_first_name, ' ', cd.c_last_name, ' from ', cd.ca_city, ', ', cd.ca_state) AS customer_info
FROM 
    CustomerData cd
LEFT JOIN 
    CustomerSales cs ON cd.c_customer_id = cs.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
