
WITH RECURSIVE demographic_growth AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_dep_count,
        cd_purchase_estimate,
        1 AS generation
    FROM customer_demographics
    WHERE cd_dep_count IS NOT NULL

    UNION ALL

    SELECT 
        dg.cd_demo_sk,
        dg.cd_gender,
        dg.cd_marital_status,
        dg.cd_education_status,
        (dg.cd_dep_count + 1) AS cd_dep_count,
        (dg.cd_purchase_estimate * 10) AS cd_purchase_estimate,
        generation + 1
    FROM demographic_growth dg
    JOIN customer_demographics cd ON dg.cd_demo_sk = cd.cd_demo_sk
    WHERE dg.generation < 5
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, d.d_year
    HAVING SUM(ws.ws_net_profit) IS NOT NULL
),
promotions_stats AS (
    SELECT 
        p.p_promo_id,
        SUM(cs.cs_net_profit) AS promo_net_profit,
        COUNT(cs.cs_order_number) AS promo_orders,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM promotion p
    JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY p.p_promo_id
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.ca_city,
    cs.ca_state,
    cs.total_profit,
    cs.total_orders,
    COALESCE(pg.cd_purchase_estimate, 0) AS estimated_growth,
    ps.promo_net_profit,
    ps.promo_orders,
    ps.avg_sales_price
FROM customer_summary cs
LEFT JOIN demographic_growth pg ON cs.c_customer_sk = pg.cd_demo_sk
LEFT JOIN promotions_stats ps ON pg.cd_demo_sk = ps.promo_net_profit
WHERE (cs.total_profit > 1000 OR pg.cd_dep_count > 2)
ORDER BY cs.total_profit DESC, pg.generation;
