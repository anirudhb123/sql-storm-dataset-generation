
WITH RECURSIVE income_brackets AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_brackets ib_prev ON ib.ib_income_band_sk = ib_prev.ib_income_band_sk + 1
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_profit
    FROM customer c
    JOIN customer_stats cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE cs.gender_rank <= 10
),
shipping_analysis AS (
    SELECT 
        sm.sm_type,
        COUNT(ws.ws_order_number) AS total_shipments,
        AVG(ws.ws_net_paid) AS avg_ship_cost,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_type
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.order_count,
    ROUND(cs.avg_spent, 2) AS avg_spent,
    COALESCE(sb.ib_lower_bound, 'Not Specified') AS income_lower_bound,
    sa.sm_type,
    sa.total_shipments,
    ROUND(sa.avg_ship_cost, 2) AS avg_ship_cost
FROM customer_stats cs
JOIN top_customers c ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN income_brackets sb ON ROUND(cs.avg_spent) BETWEEN sb.ib_lower_bound AND sb.ib_upper_bound
JOIN shipping_analysis sa ON cs.order_count > 5
WHERE cs.total_profit > 1000 AND c.c_first_name IS NOT NULL
ORDER BY cs.total_profit DESC;
