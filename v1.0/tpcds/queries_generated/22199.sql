
WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
AddressInfo AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ca.ca_city) AS city_rank
    FROM 
        customer_address ca
)
SELECT 
    s.c_customer_id,
    s.c_first_name,
    s.c_last_name,
    a.ca_address_id,
    a.ca_city,
    a.ca_state,
    s.total_quantity,
    s.total_profit,
    CASE 
        WHEN s.total_profit IS NULL THEN 'No Profit'
        WHEN s.total_profit > 1000 THEN 'High Profit'
        WHEN s.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    COALESCE(a.ca_city, 'Unknown City') AS resolved_city,
    (SELECT COUNT(*) FROM AddressInfo) AS total_address_count,
    (SELECT COUNT(DISTINCT ca.ca_state) FROM customer_address ca WHERE ca.ca_city IS NOT NULL) AS distinct_states_count
FROM 
    SalesData s
LEFT JOIN 
    AddressInfo a ON s.c_customer_id = a.ca_address_id
WHERE 
    s.profit_rank = 1 AND a.city_rank <= 5
ORDER BY 
    s.total_profit DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY
UNION ALL
SELECT 
    'Total' AS c_customer_id,
    NULL AS c_first_name,
    NULL AS c_last_name,
    NULL AS ca_address_id,
    NULL AS ca_city,
    NULL AS ca_state,
    SUM(total_quantity),
    SUM(total_profit),
    NULL AS profit_category,
    NULL AS resolved_city,
    COUNT(*) AS total_address_count,
    COUNT(DISTINCT ca_state) AS distinct_states_count
FROM 
    SalesData s
JOIN 
    AddressInfo a ON s.c_customer_id = a.ca_address_id
GROUP BY 
    a.ca_state
HAVING 
    SUM(total_profit) IS NOT NULL
ORDER BY 
    total_profit DESC;
