
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk, ws.web_site_id
), customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_spent
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent
    FROM customer_summary cs
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM customer_summary)
), sales_with_customers AS (
    SELECT 
        r.web_site_sk,
        r.web_site_id,
        r.total_quantity,
        r.total_net_paid,
        h.c_customer_sk,
        h.c_first_name,
        h.c_last_name
    FROM ranked_sales r
    JOIN high_value_customers h ON r.web_site_sk = h.c_customer_sk
)
SELECT 
    swc.web_site_id,
    swc.total_quantity,
    swc.total_net_paid,
    COALESCE(hvc.c_first_name || ' ' || hvc.c_last_name, 'Unknown Customer') AS customer_name,
    CASE 
        WHEN swc.total_net_paid IS NULL THEN 'No Sales'
        WHEN swc.total_net_paid > 1000 THEN 'High Value Sale'
        ELSE 'Regular Sale' 
    END AS sale_classification
FROM sales_with_customers swc
FULL OUTER JOIN high_value_customers hvc ON swc.c_customer_sk = hvc.c_customer_sk
WHERE swc.total_quantity > 50 OR swc.total_net_paid IS NOT NULL
ORDER BY swc.total_net_paid DESC NULLS LAST;
