
WITH AddressInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN LENGTH(c.c_email_address) > 0 THEN SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1)
            ELSE 'No Email'
        END AS domain
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        CONCAT(c.c_first_name, ' ', c.c_last_name) LIKE '%Smith%'
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(*) AS num_customers
    FROM 
        customer_demographics cd
    JOIN 
        AddressInfo ai ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE CONCAT(c.c_first_name, ' ', c.c_last_name) = ai.full_name)
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesSummary AS (
    SELECT 
        ws.w_web_page_id,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_first_name LIKE 'A%' AND c.c_last_name LIKE '%son%'
    GROUP BY 
        ws.w_web_page_id
)
SELECT 
    ai.full_name,
    ai.ca_city,
    ai.ca_state,
    dm.cd_gender,
    dm.cd_marital_status,
    dm.cd_education_status,
    ss.total_profit,
    ai.domain
FROM 
    AddressInfo ai
JOIN 
    Demographics dm ON ai.full_name = dm.full_name
LEFT JOIN 
    SalesSummary ss ON ai.domain = ss.w_web_page_id
ORDER BY 
    ai.ca_city, dm.cd_gender, ss.total_profit DESC
LIMIT 100;
