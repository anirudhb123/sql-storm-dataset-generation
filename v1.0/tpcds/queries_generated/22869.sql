
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) as total_net_profit,
        DENSE_RANK() OVER (PARTITION BY c.c_country ORDER BY SUM(ws.ws_net_profit) DESC) as rank_in_country
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
        AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        customer_id,
        total_net_profit
    FROM 
        ranked_sales
    WHERE 
        rank_in_country <= 10
)
SELECT 
    hvc.customer_id,
    hvc.total_net_profit,
    COALESCE(CONCAT('Customer ID: ', hvc.customer_id), 'Unknown') as customer_info,
    RANK() OVER (ORDER BY hvc.total_net_profit DESC) AS rank_all_time
FROM 
    high_value_customers hvc
JOIN 
    (SELECT DISTINCT ca_country FROM customer_address WHERE ca_country IS NOT NULL) as unique_countries ON 
    hvc.total_net_profit > COALESCE(
        (SELECT AVG(ws_ext_sales_price) FROM web_sales ws WHERE ws.ws_net_profit IS NOT NULL),
        (SELECT 0)
    )
ORDER BY 
    hvc.total_net_profit DESC
FETCH FIRST 100 ROWS ONLY;
