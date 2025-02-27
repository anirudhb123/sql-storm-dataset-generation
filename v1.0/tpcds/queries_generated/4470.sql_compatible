
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
)

SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(rs.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
    MAX(cd.cd_dep_count) AS max_dependents,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM 
    RankedSales rs
JOIN 
    customer c ON rs.ws_order_number = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store s ON s.s_store_sk = rs.ws_ship_mode_sk
WHERE 
    rs.rank = 1
    AND ca.ca_state IN ('CA', 'TX')
    AND cd.cd_credit_rating IS NOT NULL
GROUP BY 
    ca.ca_city, 
    ca.ca_state
HAVING 
    SUM(rs.ws_net_profit) > 10000
ORDER BY 
    total_net_profit DESC
LIMIT 10;
