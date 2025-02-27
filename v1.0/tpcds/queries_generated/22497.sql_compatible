
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rn,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_quantity,
        SUM(ws_net_paid_inc_tax) OVER (PARTITION BY ws_item_sk) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
address_details AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CASE 
            WHEN ca_state IS NULL THEN 'Unknown State'
            WHEN ca_city IN ('New York', 'Los Angeles', 'Chicago') THEN 'Major City'
            ELSE 'Other City'
        END AS city_category
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN address_details ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ci.ca_city,
    ci.cd_gender,
    COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
    SUM(rs.total_sales) AS total_sales_amount,
    AVG(rs.total_quantity) AS average_quantity_sold,
    STRING_AGG(DISTINCT ci.cd_marital_status, ', ') AS marital_status_distribution
FROM 
    ranked_sales rs
JOIN 
    customer_info ci ON rs.ws_item_sk = ci.c_customer_sk
WHERE 
    ci.cd_purchase_estimate > 1000
    AND ci.ca_city IS NOT NULL
GROUP BY 
    ci.ca_city, ci.cd_gender
HAVING 
    COUNT(DISTINCT ci.c_customer_sk) > 10
ORDER BY 
    total_sales_amount DESC
LIMIT 50;
