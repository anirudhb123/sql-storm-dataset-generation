
WITH RECURSIVE income_brackets AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound, 1 AS level
    FROM income_band
    WHERE ib_income_band_sk = 1

    UNION ALL

    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, level + 1
    FROM income_band ib
    JOIN income_brackets ib2 ON ib.ib_income_band_sk = ib2.ib_income_band_sk + 1
    WHERE ib2.ib_upper_bound < 500000
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        COALESCE(SUM(s_sales.ss_net_profit), 0) AS total_net_profit,
        RANK() OVER (ORDER BY COALESCE(SUM(s_sales.ss_net_profit), 0) DESC) AS profit_rank
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN store_sales s_sales ON c.c_customer_sk = s_sales.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.cd_gender, d.cd_marital_status
),
top_customers AS (
    SELECT 
        * 
    FROM customer_stats
    WHERE profit_rank <= 10
),
sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS transactions_count,
        AVG(ws.ws_sales_price) AS avg_item_price
    FROM web_sales ws
    JOIN top_customers tc ON ws.ws_ship_customer_sk = tc.c_customer_sk
    GROUP BY ws.web_site_id
)
SELECT 
    s.w_warehouse_id,
    COALESCE(income_brackets.ib_lower_bound, 0) AS income_band_lower,
    COALESCE(income_brackets.ib_upper_bound, 0) AS income_band_upper,
    COALESCE(sales_summary.total_profit, 0) AS total_profit,
    sales_summary.transactions_count,
    sales_summary.avg_item_price,
    CASE 
        WHEN sales_summary.transactions_count > 100 THEN 'High Activity'
        WHEN sales_summary.transactions_count BETWEEN 50 AND 100 THEN 'Medium Activity'
        ELSE 'Low Activity'
    END AS activity_level
FROM warehouse s
LEFT JOIN income_brackets ON s.w_warehouse_sk = income_brackets.ib_income_band_sk
LEFT JOIN sales_summary ON s.w_warehouse_sk = sales_summary.total_profit
WHERE s.w_country = 'USA'
ORDER BY income_band_lower, total_profit DESC;
