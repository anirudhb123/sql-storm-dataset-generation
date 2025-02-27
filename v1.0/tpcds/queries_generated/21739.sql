
WITH RECURSIVE income_ranges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL AND ib_upper_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_ranges ir ON ib.ib_lower_bound > ir.ib_upper_bound AND ir.ib_income_band_sk != ib.ib_income_band_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) AS highest_sale,
        AVG(ws.ws_net_paid) AS average_payment,
        COUNT(DISTINCT o) FILTER (WHERE o IS NOT NULL) AS valid_orders,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT ws_bill_customer_sk AS customer_sk, ws_order_number, 
               SUM(ws_sales_price) AS ws_sales_price, 
               SUM(ws_net_profit) AS net_profit, 
               SUM(ws_net_paid) AS net_paid 
        FROM web_sales 
        GROUP BY ws_bill_customer_sk, ws_order_number
    ) ws ON c.c_customer_sk = ws.customer_sk
    LEFT JOIN (
        SELECT DISTINCT ws_bill_customer_sk, ws_order_number 
        FROM web_sales 
        WHERE (ws_list_price >= 50 OR ws_sales_price < 10) 
        AND ws_net_paid IS NOT NULL
    ) o ON ws.ws_order_number = o.ws_order_number
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ws.ws_net_profit) > (SELECT AVG(ws_net_profit) FROM web_sales WHERE ws_net_profit IS NOT NULL)
),
top_customers AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        SUM(ca.total_net_profit) AS city_net_profit,
        COUNT(DISTINCT ca.c_customer_id) AS customer_count,
        MAX(ca.highest_sale) AS max_sale,
        SUM(CASE WHEN ca.cd_marital_status = 'M' THEN ca.total_net_profit ELSE 0 END) AS married_profit,
        SUM(CASE WHEN ca.cd_marital_status = 'S' THEN ca.total_net_profit ELSE 0 END) AS single_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(ca.total_net_profit) DESC) AS rank
    FROM customer_analysis ca
    JOIN customer_address ca ON ca.ca_address_sk = ca.c_current_addr_sk
    GROUP BY ca.ca_city, ca.ca_state
    HAVING COUNT(DISTINCT ca.c_customer_id) > 5 AND city_net_profit > (SELECT AVG(city_net_profit) FROM customer_analysis)
)
SELECT t.ca_city, t.ca_state, t.city_net_profit, t.customer_count, 
       COALESCE(up_average, 0) AS upper_bound_prev_customers,
       COALESCE(low_average, 0) AS lower_bound_prev_customers
FROM top_customers t
LEFT JOIN (
    SELECT 
        ca.ca_city,
        AVG(c.total_net_profit) AS up_average
    FROM customer_analysis c
    JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE c.total_net_profit > 1000
    GROUP BY ca.ca_city
) up ON t.ca_city = up.ca_city
LEFT JOIN (
    SELECT 
        ca.ca_city,
        AVG(c.total_net_profit) AS low_average
    FROM customer_analysis c
    JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE c.total_net_profit <= 1000
    GROUP BY ca.ca_city
) low ON t.ca_city = low.ca_city
WHERE t.rank <= 10
ORDER BY t.city_net_profit DESC, t.customer_count DESC;
