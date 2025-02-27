
WITH AddressDetails AS (
    SELECT 
        ca.city as address_city,
        ca.state as address_state,
        ca.country as address_country,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ship_date_sk,
        d.d_date as sales_date,
        ad.address_city,
        ad.address_state,
        ad.address_country,
        ad.customer_full_name,
        ad.cd_gender,
        ad.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        Date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        AddressDetails ad ON ws.ws_bill_customer_sk = c.c_customer_sk 
)
SELECT 
    sales_date,
    address_city,
    address_state,
    address_country,
    COUNT(ws_order_number) AS total_orders,
    SUM(ws_sales_price) AS total_sales,
    AVG(ws_sales_price) AS average_order_value,
    COUNT(DISTINCT customer_full_name) AS unique_customers,
    cd_gender,
    cd_marital_status
FROM 
    SalesData
GROUP BY 
    sales_date, 
    address_city, 
    address_state, 
    address_country, 
    cd_gender, 
    cd_marital_status
ORDER BY 
    sales_date ASC, 
    total_sales DESC;
