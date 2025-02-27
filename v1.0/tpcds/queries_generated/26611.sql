
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        ARRAY_AGG(DISTINCT cd.cd_marital_status) AS marital_statuses
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS number_of_orders
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
FinalBenchmark AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.gender,
        sd.total_sales,
        sd.number_of_orders,
        CONCAT('Total Sales: $', TO_CHAR(sd.total_sales, 'FM999,999,999.00'), 
               ', Orders: ', sd.number_of_orders) AS sales_summary
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    gender,
    sales_summary
FROM 
    FinalBenchmark
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC, full_name;
