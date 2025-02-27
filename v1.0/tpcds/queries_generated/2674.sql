
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        DENSE_RANK() OVER (PARTITION BY ca_state ORDER BY SUM(ws.ws_net_profit) DESC) AS state_rank
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, ca.ca_state
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_profit,
        cs.avg_sales_price,
        ca.ca_state
    FROM 
        customer_sales AS cs
    JOIN 
        customer_address AS ca ON cs.c_customer_sk = ca.ca_address_sk
    WHERE 
        cs.state_rank <= 10
),
avg_income AS (
    SELECT 
        h.hd_income_band_sk,
        AVG(hd_dep_count) AS avg_dep_count,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        household_demographics AS h
    JOIN 
        customer AS c ON h.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        h.hd_income_band_sk
)

SELECT 
    tc.c_customer_sk,
    tc.total_orders,
    tc.total_profit,
    tc.avg_sales_price,
    ai.avg_dep_count,
    ai.customer_count,
    CASE 
        WHEN tc.total_profit IS NULL THEN 'No Profit' 
        ELSE 'Has Profit' 
    END AS profit_status,
    CONCAT('Customer ', tc.c_customer_sk, ' in ', tc.ca_state) AS customer_summary
FROM 
    top_customers AS tc
LEFT OUTER JOIN 
    avg_income AS ai ON ai.hd_income_band_sk = 
        (SELECT hd_income_band_sk FROM household_demographics 
         WHERE hd_demo_sk = (SELECT c.c_current_hdemo_sk FROM customer c 
                             WHERE c.c_customer_sk = tc.c_customer_sk))
ORDER BY 
    tc.total_profit DESC, tc.total_orders ASC;
