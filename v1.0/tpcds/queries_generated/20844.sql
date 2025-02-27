
WITH RECURSIVE address_data AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) as rn
    FROM 
        customer_address
    WHERE 
        ca_state IS NOT NULL
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_credit_rating,
        COUNT(DISTINCT s.s_store_sk) AS store_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store s ON s.s_store_sk IN (
            SELECT ss_store_sk 
            FROM store_sales 
            WHERE ss_customer_sk = c.c_customer_sk 
            GROUP BY ss_store_sk
        )
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_gender, cd.cd_credit_rating
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    LEFT JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq IN (1, 2, 3)
        )
    GROUP BY 
        ws.ws_item_sk
),
integration_data AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        ad.ca_city,
        ad.ca_state,
        ad.ca_country,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_profit, 0) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ad.ca_city ORDER BY COALESCE(sd.total_profit, 0) DESC) as city_rn
    FROM 
        customer_data cd
    JOIN 
        address_data ad ON cd.c_customer_id LIKE '%' || ad.rn || '%'
    LEFT JOIN 
        sales_data sd ON cd.c_customer_id = SUBSTRING(sd.ws_item_sk::TEXT, 1, LENGTH(cd.c_customer_id))
)
SELECT 
    id.c_customer_id,
    id.c_first_name,
    id.c_last_name,
    id.ca_city,
    id.ca_state,
    id.ca_country,
    id.total_sales,
    id.total_profit
FROM 
    integration_data id
WHERE 
    id.city_rn <= 5 AND 
    (id.total_profit > 100 OR (id.total_sales > 200 AND id.ca_country IS NOT NULL))
ORDER BY 
    id.total_profit DESC;
