
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        ca.ca_street_name,
        ca.ca_street_type,
        ca.ca_street_number,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        ca.ca_state IN ('CA', 'NY', 'TX')
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS number_of_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        sd.total_sales,
        sd.number_of_orders
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    cs.full_name,
    cs.ca_city,
    cs.ca_state,
    cs.ca_country,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.number_of_orders, 0) AS total_orders,
    (CASE 
        WHEN COALESCE(cs.total_sales, 0) > 1000 THEN 'High Value'
        WHEN COALESCE(cs.total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END) AS customer_value_category
FROM 
    CustomerSales cs
ORDER BY 
    cs.total_sales DESC;
