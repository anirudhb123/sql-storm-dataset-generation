
WITH RECURSIVE Address_Stats AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state, 
        COUNT(c_customer_sk) AS customer_count,
        SUM(COALESCE(c_birth_day, 0)) AS total_birth_days
    FROM customer_address AS ca
    LEFT JOIN customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca_address_sk, ca_city, ca_state
),
Aggregate_Income AS (
    SELECT 
        ib_income_band_sk, 
        COUNT(hd_demo_sk) AS household_count,
        SUM(hd_buy_potential = 'High') AS high_buy_potential_count
    FROM household_demographics AS hd
    JOIN income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib_income_band_sk
),
Daily_Sales AS (
    SELECT 
        d.d_date, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM date_dim AS d
    LEFT JOIN web_sales AS ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY d.d_date
),
Combined_Stats AS (
    SELECT 
        AS.city, 
        AS.state,
        AI.household_count,
        AI.high_buy_potential_count,
        DS.total_sales,
        DS.total_orders
    FROM Address_Stats AS AS
    JOIN Aggregate_Income AS AI ON AS.customer_count > 0
    LEFT JOIN Daily_Sales AS DS ON AS.ca_city = DS.d_date
),
Final_Result AS (
    SELECT 
        city, 
        state,
        household_count,
        high_buy_potential_count,
        COALESCE(SUM(total_sales), 0) AS total_sales,
        COALESCE(SUM(total_orders), 0) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_sales DESC) AS sales_rank
    FROM Combined_Stats
    GROUP BY city, state, household_count, high_buy_potential_count
)
SELECT 
    city, 
    state, 
    household_count,
    high_buy_potential_count,
    CASE WHEN total_sales > 0 THEN ROUND(total_sales, 2) ELSE NULL END AS total_sales,
    CASE WHEN total_orders > 0 THEN total_orders ELSE NULL END AS total_orders,
    sales_rank
FROM Final_Result
WHERE (household_count IS NOT NULL OR high_buy_potential_count > 0)
AND (total_sales IS NOT NULL OR total_orders IS NOT NULL)
ORDER BY state, total_sales DESC;
