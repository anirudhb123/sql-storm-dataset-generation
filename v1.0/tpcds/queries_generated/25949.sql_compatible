
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        SUBSTRING_INDEX(ca.ca_street_name, ' ', -1) AS street_name_last_word
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails c ON ws.ws_bill_customer_sk = c.c_customer_id
    GROUP BY 
        c.c_customer_id
)
SELECT 
    cd.full_name,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    cs.total_orders,
    cs.total_sales,
    cs.avg_order_value,
    cd.street_name_last_word,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other' 
    END AS gender_description
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesStats cs ON cd.c_customer_id = cs.c_customer_id
WHERE 
    cd.income_band BETWEEN 1 AND 5
ORDER BY 
    cs.total_sales DESC, 
    cd.full_name;
