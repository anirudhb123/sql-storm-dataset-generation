
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, 
                  COALESCE(ca.ca_suite_number, '')) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        CA.ca_city,
        CA.ca_state,
        WS.ws_sold_date_sk
    FROM 
        web_sales ws
    JOIN 
        AddressDetails CA ON ws.ws_bill_addr_sk = CA.ca_address_sk
),
SalesSummary AS (
    SELECT 
        sd.ca_city,
        sd.ca_state,
        COUNT(sd.ws_order_number) AS total_orders,
        SUM(sd.ws_sales_price) AS total_sales,
        AVG(sd.ws_sales_price) AS avg_sales_price
    FROM 
        SalesData sd
    GROUP BY 
        sd.ca_city, sd.ca_state
)
SELECT 
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    ss.total_orders,
    ss.total_sales,
    ss.avg_sales_price 
FROM 
    CustomerDetails cs
JOIN 
    SalesSummary ss ON cs.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = (SELECT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_city = ss.ca_city AND ca.ca_state = ss.ca_state) LIMIT 1)
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
