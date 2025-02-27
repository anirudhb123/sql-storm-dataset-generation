
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(cd.cd_dep_count, ' dependents') AS family_size
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_city IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number, ws.ws_sold_date_sk, ws.ws_item_sk
),
AggregatedSales AS (
    SELECT 
        si.full_name,
        si.ca_city,
        si.ca_state,
        COALESCE(SUM(sd.total_quantity), 0) AS total_items_sold,
        COALESCE(SUM(sd.total_profit), 0) AS total_profit
    FROM 
        CustomerInfo si
    LEFT JOIN 
        SalesData sd ON si.c_customer_id = sd.ws_order_number
    GROUP BY 
        si.full_name, si.ca_city, si.ca_state
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_items_sold,
    total_profit,
    CASE 
        WHEN total_profit > 1000 THEN 'High Value Customer'
        WHEN total_profit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM 
    AggregatedSales
ORDER BY 
    total_profit DESC
LIMIT 100;
