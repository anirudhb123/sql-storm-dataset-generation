
WITH RECURSIVE revenue_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
high_value_customers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_profit,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        revenue_summary r
    LEFT JOIN 
        household_demographics hd ON r.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON r.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        r.c_customer_sk, r.c_first_name, r.c_last_name, r.total_profit, hd.hd_income_band_sk
    HAVING 
        r.total_profit > (SELECT AVG(total_profit) FROM revenue_summary) OR COUNT(DISTINCT ws.ws_order_number) > 5
), 
customer_recommendations AS (
    SELECT 
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        COALESCE(wp.wp_url, 'No page visited') AS last_visited_page,
        PERCENT_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
    GROUP BY 
        c.c_first_name, c.c_last_name, wp.wp_url
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_profit,
    hvc.income_band,
    cr.customer_name,
    cr.last_visited_page,
    cr.rank
FROM 
    high_value_customers hvc
LEFT JOIN 
    customer_recommendations cr ON hvc.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_first_name || ' ' || c.c_last_name = cr.customer_name LIMIT 1)
WHERE 
    hvc.income_band IS NOT NULL
ORDER BY 
    hvc.total_profit DESC, 
    cr.rank ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
