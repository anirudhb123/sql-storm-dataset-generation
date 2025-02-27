
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id AS customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
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
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        DATE_FORMAT(dd.d_date, '%Y-%m') AS sale_month,
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
),
AggregateSales AS (
    SELECT 
        customer_id,
        sale_month,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.customer_id = sd.ws_bill_customer_sk
    GROUP BY 
        customer_id, sale_month
)
SELECT 
    ci.customer_id,
    ci.full_name,
    ci.full_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    as.total_sales,
    as.total_quantity
FROM 
    CustomerInfo ci
LEFT JOIN 
    AggregateSales as ON ci.customer_id = as.customer_id
ORDER BY 
    ci.full_name, as.sale_month DESC
LIMIT 100;
