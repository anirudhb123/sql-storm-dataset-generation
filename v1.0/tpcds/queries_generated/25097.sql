
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk, 
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        cs.cs_ship_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cd.customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM catalog_sales cs
    JOIN CustomerDetails cd ON cs.cs_bill_customer_sk = cd.c_customer_sk
    WHERE cs.cs_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT 
        customer_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(cs_quantity) AS total_items_sold
    FROM SalesData
    GROUP BY customer_name, cd_gender, cd_marital_status, cd_education_status
)
SELECT 
    customer_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    total_orders,
    total_items_sold,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM SalesSummary
ORDER BY total_sales DESC;
