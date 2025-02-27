
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
FilteredData AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        si.total_quantity_sold,
        si.total_sales_amount
    FROM 
        CustomerInfo ci
    JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_item_sk
)
SELECT 
    cd.ca_city,
    COUNT(*) AS customer_count,
    AVG(f.total_sales_amount) AS average_sales,
    MAX(f.total_quantity_sold) AS max_quantity_sold
FROM 
    FilteredData f
JOIN 
    customer_address cd ON f.ca_city = cd.ca_city
GROUP BY 
    cd.ca_city
ORDER BY 
    customer_count DESC, average_sales DESC;
