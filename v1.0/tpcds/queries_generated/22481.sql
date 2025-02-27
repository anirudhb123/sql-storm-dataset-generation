
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ship_mode_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS ranking
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2022 AND 2023 
        AND (d.d_day_name NOT IN ('Saturday', 'Sunday') OR (d.d_day_name = 'Sunday' AND ws.ws_ship_mode_sk IS NOT NULL))
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_ship_mode_sk
),
location_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    li.ca_city,
    li.ca_state,
    sd.ws_ship_mode_sk,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    COALESCE(sd.total_net_profit, 0) AS total_net_profit,
    li.customer_count,
    CASE 
        WHEN li.customer_count IS NULL OR li.customer_count = 0 THEN 'No Customers'
        ELSE CONCAT(CAST(li.customer_count AS VARCHAR), ' Customers')
    END AS customer_status
FROM 
    location_info li
LEFT JOIN 
    sales_data sd ON li.ca_city = (
        SELECT 
            d.d_city 
        FROM 
            date_dim d 
        WHERE 
            d.d_date_sk = sd.ws_sold_date_sk
        LIMIT 1
    ) AND li.ca_state = (
        SELECT 
            d.d_state 
        FROM 
            date_dim d 
        WHERE 
            d.d_date_sk = sd.ws_sold_date_sk
        LIMIT 1
    )
WHERE 
    (li.customer_count > 5 OR li.customer_count IS NULL)
ORDER BY 
    li.ca_state, li.ca_city, sd.total_net_profit DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM location_info) / 2;
