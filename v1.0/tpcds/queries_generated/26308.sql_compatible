
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS rn
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
ConcatenatedCustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        a.ca_street_name,
        a.ca_city,
        a.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    WHERE 
        a.ca_city IS NOT NULL
),
FilteredSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_order_number, ws_item_sk
),
FinalOutput AS (
    SELECT 
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        a.ca_street_name,
        a.ca_city,
        a.ca_state,
        fs.total_sales
    FROM 
        ConcatenatedCustomerInfo c
    JOIN 
        FilteredSales fs ON c.c_customer_sk = fs.ws_billed_customer_sk
    JOIN 
        RankedAddresses a ON a.rn = 1
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_street_name,
    ca_city,
    ca_state,
    SUM(total_sales) AS total_sales
FROM 
    FinalOutput
GROUP BY 
    full_name, cd_gender, cd_marital_status, cd_education_status, ca_street_name, ca_city, ca_state
ORDER BY 
    total_sales DESC;
