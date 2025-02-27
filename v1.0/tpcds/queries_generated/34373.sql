
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 0 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 3
),
daily_sales AS (
    SELECT
        d.d_date,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rank
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
),
promotions_summary AS (
    SELECT
        p.p_promo_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS promo_sales,
        COUNT(DISTINCT ws.ws_order_number) AS promo_orders
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_name
),
customer_information AS (
    SELECT
        ca.ca_city,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_city, cd.cd_gender
)
SELECT
    ch.c_first_name,
    ch.c_last_name,
    ds.total_sales,
    ds.order_count,
    ps.promo_sales,
    ps.promo_orders,
    ci.ca_city,
    ci.cd_gender,
    ci.customer_count,
    ci.avg_purchase_estimate
FROM customer_hierarchy ch
LEFT JOIN daily_sales ds ON ds.rank = 1 AND ds.total_sales > 1000
LEFT JOIN promotions_summary ps ON ps.promo_orders > 10
LEFT JOIN customer_information ci ON ci.ca_city = ch.c_current_addr_sk
WHERE ci.customer_count IS NOT NULL
  AND ds.total_sales IS NOT NULL
ORDER BY ds.total_sales DESC, ci.customer_count DESC;
