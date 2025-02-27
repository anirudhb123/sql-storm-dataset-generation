
WITH RecursiveCTE AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        cd.cd_marital_status, 
        cd.cd_gender, 
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_customer_sk) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), FilteredCustomers AS (
    SELECT 
        city_rank, 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        ca_city 
    FROM 
        RecursiveCTE 
    WHERE 
        city_rank <= (SELECT AVG(city_rank) FROM RecursiveCTE) 
)
SELECT 
    fc.c_customer_sk,
    fc.c_first_name,
    fc.c_last_name,
    fc.ca_city,
    COALESCE(NULLIF(ROUND(AVG(ws.ws_net_profit), 2), 0), 'No profits') AS avg_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY fc.ca_city ORDER BY COUNT(DISTINCT ws.ws_order_number) DESC) AS order_rank
FROM 
    FilteredCustomers fc 
LEFT JOIN 
    web_sales ws ON fc.c_customer_sk = ws.ws_bill_customer_sk 
GROUP BY 
    fc.c_customer_sk, fc.c_first_name, fc.c_last_name, fc.ca_city
HAVING 
    COUNT(ws.ws_order_number) > 0 OR fc.ca_city IS NOT NULL
ORDER BY 
    order_rank, fc.ca_city DESC
UNION ALL
SELECT 
    NULL AS c_customer_sk,
    'Total Customers' AS c_first_name,
    NULL AS c_last_name,
    'All Cities' AS ca_city,
    SUM(COALESCE(NULLIF(ROUND(ws.ws_net_profit, 2), 0), 0)) AS avg_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    NULL AS order_rank
FROM 
    web_sales ws
WHERE 
    ws.ws_bill_customer_sk IS NOT NULL
```
