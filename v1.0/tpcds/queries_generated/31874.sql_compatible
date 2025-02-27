
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rnk
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451992 AND 2452022
    GROUP BY s_store_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales w ON c.c_customer_sk = w.ws_ship_customer_sk
    JOIN date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
promotional_details AS (
    SELECT 
        p.p_promo_name,
        COUNT(ws_order_number) AS promo_order_count,
        SUM(ws_net_paid_inc_tax) AS promo_total_sales
    FROM promotion p
    JOIN web_sales w ON p.p_promo_sk = w.ws_promo_sk
    GROUP BY p.p_promo_name
),
high_rollers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 5000
)

SELECT 
    sh.s_store_sk,
    sh.total_sales,
    sh.total_transactions,
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    ps.promo_order_count,
    ps.promo_total_sales,
    COALESCE(hr.c_customer_sk, 'None') AS high_roller_customer,
    CASE 
        WHEN hr.c_customer_sk IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS is_high_roller
FROM sales_hierarchy sh
FULL OUTER JOIN customer_summary cs ON sh.s_store_sk = cs.c_customer_sk
LEFT JOIN promotional_details ps ON sh.s_store_sk = ps.promo_order_count
LEFT JOIN high_rollers hr ON cs.c_customer_sk = hr.c_customer_sk
WHERE sh.total_sales > (SELECT AVG(total_sales) FROM sales_hierarchy) 
  AND (cs.order_count IS NULL OR cs.order_count > 5)
ORDER BY sh.total_sales DESC, cs.total_profit DESC;
