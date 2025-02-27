
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk
),
GenderSales AS (
    SELECT 
        ci.cd_gender,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.total_sales) AS total_sales
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_id = sd.ws_bill_customer_sk
    GROUP BY 
        ci.cd_gender
),
MaritalStatusSales AS (
    SELECT 
        ci.cd_marital_status,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.total_sales) AS total_sales
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_id = sd.ws_bill_customer_sk
    GROUP BY 
        ci.cd_marital_status
)
SELECT 
    gs.cd_gender,
    gs.total_quantity AS gender_quantity,
    gs.total_sales AS gender_sales,
    ms.cd_marital_status,
    ms.total_quantity AS marital_quantity,
    ms.total_sales AS marital_sales
FROM 
    GenderSales gs
FULL OUTER JOIN 
    MaritalStatusSales ms ON gs.cd_gender = ms.cd_marital_status
ORDER BY 
    gs.cd_gender, ms.cd_marital_status;
