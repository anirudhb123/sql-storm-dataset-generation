
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ss.ss_ticket_number,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_ticket_number
),
return_data AS (
    SELECT 
        sr.sr_ticket_number,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns_value
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_ticket_number
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    COALESCE(sd.total_quantity, 0) AS total_sales_quantity,
    COALESCE(sd.total_sales, 0) AS total_sales_value,
    COALESCE(rd.total_returns, 0) AS total_returned_quantity,
    COALESCE(rd.total_returns_value, 0) AS total_returns_value
FROM 
    customer_info ci
LEFT JOIN 
    sales_data sd ON ci.c_customer_id = sd.ss_ticket_number
LEFT JOIN 
    return_data rd ON ci.c_customer_id = rd.sr_ticket_number
WHERE 
    ci.cd_gender = 'F' AND 
    ci.cd_marital_status = 'M'
ORDER BY 
    ci.ca_city, ci.full_name;
