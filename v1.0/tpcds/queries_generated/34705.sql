
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY 
        ws_item_sk
),
Address_CTE AS (
    SELECT 
        ca_address_sk, 
        ca_city,
        ca_state
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
Demographics_CTE AS (
    SELECT 
        cd_demo_sk,
        cd_gender, 
        cd_marital_status, 
        cd_purchase_estimate,
        cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 500
)
SELECT 
    a.ca_city, 
    a.ca_state,
    s.total_quantity, 
    s.total_profit, 
    d.cd_gender, 
    d.cd_marital_status
FROM 
    Sales_CTE s
JOIN 
    Address_CTE a ON s.ws_item_sk = a.ca_address_sk
JOIN 
    Demographics_CTE d ON d.gender_rank = 1
WHERE 
    s.total_profit > (SELECT AVG(total_profit) FROM Sales_CTE)
ORDER BY 
    s.total_profit DESC
LIMIT 10
UNION ALL
SELECT 
    NULL AS ca_city, 
    NULL AS ca_state, 
    COUNT(*) AS total_quantity, 
    SUM(ws_net_profit) AS total_profit, 
    'Total' AS cd_gender,
    NULL AS cd_marital_status
FROM 
    web_sales
WHERE 
    ws_sold_date_sk BETWEEN 2450000 AND 2455000
GROUP BY 
    ws_sold_date_sk
ORDER BY 
    total_profit DESC;
