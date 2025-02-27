
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_city,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate BETWEEN 0 AND 500 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 501 AND 1000 THEN 'Medium'
            ELSE 'High' 
        END AS purchase_estimate_band,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_net_paid_inc_tax) AS max_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
),
top_cities AS (
    SELECT 
        ca.ca_city,
        SUM(ws.ws_net_profit) AS city_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
    HAVING 
        SUM(ws.ws_net_profit) > 10000
),
ranked_customers AS (
    SELECT 
        c.customer_id,
        c.purchase_estimate_band,
        city_rank,
        ROW_NUMBER() OVER (PARTITION BY purchase_estimate_band ORDER BY city_rank) AS rank
    FROM 
        customer_data c
    WHERE 
        c.cd_gender IS NOT NULL 
        AND c.cd_marital_status <> 'S'
        AND city_rank <= 5
)

SELECT 
    rc.customer_id,
    rc.purchase_estimate_band,
    tc.city_profit,
    ds.total_profit,
    ds.total_orders,
    ds.max_order_value
FROM 
    ranked_customers rc
LEFT JOIN 
    top_cities tc ON rc.c_city = tc.ca_city
LEFT JOIN 
    daily_sales ds ON rc.customer_id = (SELECT 
                                            c.customer_id 
                                        FROM 
                                            customer c 
                                        WHERE 
                                            c.c_current_cdemo_sk = rc.c_demo_sk)
WHERE 
    rc.rank <= 3
ORDER BY 
    rc.purchase_estimate_band, 
    tc.city_profit DESC
