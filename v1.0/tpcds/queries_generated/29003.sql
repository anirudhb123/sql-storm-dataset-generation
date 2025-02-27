
WITH CustomerFullInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesStatistics AS (
    SELECT 
        cf.full_name,
        cf.ca_city,
        cf.ca_state,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS number_of_orders
    FROM
        CustomerFullInfo cf
    JOIN 
        web_sales ws ON cf.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cf.full_name, cf.ca_city, cf.ca_state
),
FilteredSales AS (
    SELECT 
        *,
        CASE 
            WHEN total_sales > 1000 THEN 'High Value'
            WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM 
        SalesStatistics
)
SELECT 
    fs.full_name,
    fs.ca_city,
    fs.ca_state,
    fs.total_sales,
    fs.number_of_orders,
    fs.customer_value_category,
    COUNT(DISTINCT ws.ws_order_number) OVER (PARTITION BY fs.customer_value_category) AS count_by_category
FROM 
    FilteredSales fs
ORDER BY 
    fs.total_sales DESC, fs.full_name ASC;
