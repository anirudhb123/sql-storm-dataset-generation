
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.ca_zip,
        sd.total_quantity,
        sd.total_sales
    FROM 
        CustomerDetails cd
    JOIN SalesData sd ON cd.c_customer_id = sd.ws_bill_customer_sk
    WHERE 
        sd.total_sales > 1000
    ORDER BY 
        sd.total_sales DESC
    LIMIT 10
)
SELECT 
    full_name,
    CONCAT('City: ', ca_city, ', State: ', ca_state, ', ZIP: ', ca_zip) AS address_info,
    total_quantity AS quantity_ordered,
    total_sales AS total_spent
FROM 
    TopCustomers;
