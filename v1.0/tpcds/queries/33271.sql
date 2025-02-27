
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        1 AS hierarchy_level
    FROM 
        customer c
    WHERE 
        c.c_birth_year >= 1980
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ch.hierarchy_level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
), 
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ca.ca_city,
    SUM(sd.total_profit) AS total_profit_by_city,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT ch.c_customer_sk) AS hierarchy_count
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    SalesData sd ON sd.ws_item_sk IN (
        SELECT 
            i.i_item_sk
        FROM 
            item i
        WHERE 
            i.i_current_price > 50
    )
LEFT JOIN 
    CustomerHierarchy ch ON ch.c_customer_sk = c.c_customer_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(ch.c_customer_sk) > 10
ORDER BY 
    total_profit_by_city DESC;
