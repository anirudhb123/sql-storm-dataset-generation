
WITH AddressAnalysis AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_city) AS city_uppercase
    FROM 
        customer_address
),
CustomerAnalysis AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        c_birth_day,
        c_birth_month,
        c_birth_year,
        c_email_address,
        c_login
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesAnalysis AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
FullAnalysis AS (
    SELECT 
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cu.full_name,
        cu.cd_gender,
        cu.cd_marital_status,
        cu.cd_purchase_estimate,
        sa.total_sales,
        sa.order_count,
        LENGTH(cu.full_name) AS full_name_length,
        LENGTH(cu.c_email_address) AS email_length,
        CONCAT(cu.c_login, '-', ca.ca_zip) AS unique_identifier
    FROM 
        AddressAnalysis ca
    JOIN 
        CustomerAnalysis cu ON cu.c_birth_month = MONTH(CURRENT_DATE) 
    LEFT JOIN 
        SalesAnalysis sa ON sa.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_item_desc LIKE '%special%')
    WHERE 
        ca.ca_state IN ('CA', 'NY')
)

SELECT
    full_address,
    ca_city,
    ca_state,
    ca_country,
    full_name,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    total_sales,
    order_count,
    full_name_length,
    email_length,
    unique_identifier
FROM 
    FullAnalysis
ORDER BY 
    total_sales DESC, cd_purchase_estimate DESC
LIMIT 100;
