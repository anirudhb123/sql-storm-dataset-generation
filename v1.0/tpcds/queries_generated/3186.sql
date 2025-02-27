
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0 
        AND ws_ship_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
), total_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        ca.ca_city,
        ca.ca_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year < 1980
), top_items AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        ti.total_net_profit,
        ci.full_name,
        ci.ca_city,
        ci.ca_state
    FROM 
        ranked_sales rs
    JOIN 
        total_sales ti ON rs.ws_item_sk = ti.ws_item_sk
    JOIN 
        customer_info ci ON rs.ws_order_number = ci.c_customer_id
    WHERE 
        rs.sales_rank = 1 
        AND ti.total_net_profit > (SELECT AVG(total_net_profit) FROM total_sales)
)
SELECT 
    ti.ws_item_sk,
    ti.full_name,
    ti.ca_city,
    ti.ca_state,
    ti.total_net_profit,
    CASE 
        WHEN ti.total_net_profit IS NULL THEN 'No Profit'
        ELSE 'Profit Achieved'
    END AS profit_status
FROM 
    top_items ti
ORDER BY 
    ti.total_net_profit DESC;
