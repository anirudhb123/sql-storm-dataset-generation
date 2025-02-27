
WITH CustomerData AS (
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
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
),
AggregatedData AS (
    SELECT 
        CustomerData.full_name,
        CustomerData.ca_city,
        CustomerData.ca_state,
        SalesData.total_quantity,
        SalesData.total_profit
    FROM 
        CustomerData
    LEFT JOIN 
        SalesData ON CustomerData.c_customer_id = (
            SELECT 
                DISTINCT c.c_customer_id
            FROM 
                customer c 
            WHERE 
                c.c_first_shipto_date_sk = SalesData.ws_ship_date_sk
            LIMIT 1
        )
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_quantity,
    total_profit,
    CASE 
        WHEN total_profit > 1000 THEN 'High Value'
        WHEN total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    AggregatedData
WHERE 
    ca_city IS NOT NULL
ORDER BY 
    total_profit DESC;
