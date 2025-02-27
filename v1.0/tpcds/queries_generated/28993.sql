
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_street,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_location
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_purchase_estimate > 5000 THEN 'High Value'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer_demographics
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
Combined AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.customer_value,
        a.full_street,
        a.full_location,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(sd.total_sales, 0) AS total_sales
    FROM 
        customer c 
    LEFT JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_id
    LEFT JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        SalesDetails sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    customer_value,
    COUNT(*) AS customer_count,
    SUM(total_sales) AS aggregate_sales,
    AVG(total_orders) AS average_orders
FROM 
    Combined
GROUP BY 
    customer_value
ORDER BY 
    customer_value DESC;
