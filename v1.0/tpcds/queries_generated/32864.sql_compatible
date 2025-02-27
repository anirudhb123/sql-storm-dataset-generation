
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank      
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
latest_sales AS (
    SELECT 
        ws_item_sk, 
        total_quantity,
        total_profit
    FROM 
        sales_data
    WHERE 
        rank = 1
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS gender_marital_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IS NOT NULL
)
SELECT 
    cd.ca_city,
    cd.ca_state,
    COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
    COALESCE(SUM(ls.total_quantity), 0) AS total_quantity,
    COALESCE(SUM(ls.total_profit), 0) AS total_profit
FROM 
    customer_details cd
LEFT JOIN 
    latest_sales ls ON ls.ws_item_sk IN (
        SELECT i_item_sk 
        FROM item 
        WHERE i_current_price > 10 AND i_current_price < 50
    )
GROUP BY 
    cd.ca_city, 
    cd.ca_state
HAVING 
    COUNT(DISTINCT cd.c_customer_sk) > 100
ORDER BY 
    total_profit DESC
LIMIT 10;
