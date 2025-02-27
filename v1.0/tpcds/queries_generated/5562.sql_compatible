
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        ds.ws_sales_price,
        ds.ws_quantity,
        ds.ws_net_profit,
        ca.ca_city
    FROM 
        customer c
    JOIN 
        web_sales ds ON c.c_customer_sk = ds.ws_ship_customer_sk
    JOIN 
        date_dim d ON ds.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_year = 2023
),
aggregated_sales AS (
    SELECT 
        ci.ca_city,
        SUM(ci.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
        COUNT(*) AS total_sales
    FROM 
        customer_info ci
    GROUP BY 
        ci.ca_city
),
top_cities AS (
    SELECT 
        as.ca_city,
        as.total_net_profit,
        as.customer_count,
        as.total_sales,
        RANK() OVER (ORDER BY as.total_net_profit DESC) AS city_rank
    FROM 
        aggregated_sales as
)
SELECT 
    tc.ca_city,
    tc.total_net_profit,
    tc.customer_count,
    tc.total_sales
FROM 
    top_cities tc
WHERE 
    tc.city_rank <= 10
ORDER BY 
    tc.total_net_profit DESC;
