
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), return_stats AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_return_tax) AS total_return_tax
    FROM 
        web_returns wr
    GROUP BY 
        ws_bill_customer_sk
), aggregated_data AS (
    SELECT 
        cd.customer_id,
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        COALESCE(rs.total_return_tax, 0) AS total_return_tax
    FROM 
        customer_data cd
    LEFT JOIN 
        return_stats rs ON cd.c_customer_id = rs.customer_id
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_returns,
    total_return_amount,
    total_return_tax,
    CONCAT('User: ', full_name, ' | City: ', ca_city, ' | State: ', ca_state) AS user_info,
    LENGTH(full_name) AS full_name_length,
    LENGTH(CAST(total_return_amount AS VARCHAR)) AS return_amount_string_length
FROM 
    aggregated_data
WHERE 
    cd_gender = 'F' 
    AND total_returns > 0
ORDER BY 
    total_return_amount DESC
LIMIT 100;
