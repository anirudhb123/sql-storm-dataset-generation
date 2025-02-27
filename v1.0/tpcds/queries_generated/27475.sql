
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_last_name, c.c_first_name) AS rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'M'
),
CustomerDetails AS (
    SELECT 
        rc.c_customer_id,
        rc.c_first_name,
        rc.c_last_name,
        rc.ca_city,
        rc.ca_state,
        CONCAT(rc.c_first_name, ' ', rc.c_last_name) AS full_name,
        LENGTH(CONCAT(rc.c_first_name, ' ', rc.c_last_name)) AS name_length
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 10
)
SELECT 
    cd.full_name,
    cd.name_length,
    COUNT(wp.wp_web_page_id) AS page_visits,
    SUM(ws.ws_net_profit) AS total_profit
FROM 
    CustomerDetails cd
LEFT JOIN 
    web_page wp ON wp.wp_customer_sk = cd.c_customer_id
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = cd.c_customer_id
GROUP BY 
    cd.full_name, cd.name_length
ORDER BY 
    total_profit DESC
LIMIT 25;
