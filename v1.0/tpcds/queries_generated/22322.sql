
WITH RECURSIVE address_count AS (
    SELECT 
        ca_address_sk,
        ca_city,
        COUNT(*) OVER (PARTITION BY ca_city) AS city_count
    FROM customer_address
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
sales_data AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        t.t_hour,
        t.t_minute,
        t.t_second,
        DENSE_RANK() OVER (PARTITION BY t.t_hour ORDER BY ws.ws_net_profit DESC) AS hour_rank
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_net_paid > 0 OR ws.ws_net_profit IS NULL
), 
total_sales AS (
    SELECT 
        item.i_item_id,
        SUM(sd.ws_net_profit) AS total_profit
    FROM item
    JOIN sales_data sd ON item.i_item_sk = sd.ws_item_sk
    GROUP BY item.i_item_id
), 
filtered_sales AS (
    SELECT 
        ts.item_id,
        ts.total_profit,
        (CASE 
            WHEN ts.total_profit IS NULL THEN 'No Profit'
            ELSE 'Profit'
         END) AS profit_status
    FROM total_sales ts 
    WHERE ts.total_profit IS NOT NULL
)

SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ac.ca_city,
    fs.item_id,
    fs.total_profit,
    fs.profit_status,
    RANK() OVER (PARTITION BY fs.profit_status ORDER BY fs.total_profit DESC) AS profit_rank
FROM customer_info ci
JOIN address_count ac ON ac.ca_address_sk = ci.c_current_addr_sk
LEFT JOIN filtered_sales fs ON ci.c_customer_sk = fs.item_id
WHERE 
    (ci.cd_marital_status = 'M' OR ci.cd_gender = 'F') 
    AND (fs.total_profit IS NOT NULL OR fs.profit_status = 'No Profit')
ORDER BY profit_rank, ac.ca_city;
