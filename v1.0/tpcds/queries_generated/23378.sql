
WITH RECURSIVE ranked_sales AS (
    SELECT 
        ws.web_site_sk, 
        ws.ws_order_number, 
        SUM(ws.ws_ext_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023 
    GROUP BY ws.web_site_sk, ws.ws_order_number
),
top_sites AS (
    SELECT 
        rs.web_site_sk,
        rs.total_sales_price,
        RANK() OVER (ORDER BY rs.total_sales_price DESC) AS site_rank
    FROM ranked_sales rs
    WHERE rs.rank <= 5
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS customer_total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        csk.c_customer_sk,
        csk.c_first_name,
        csk.c_last_name,
        csk.customer_total_sales
    FROM customer_sales csk
    WHERE csk.customer_total_sales IS NOT NULL AND csk.customer_total_sales = (
        SELECT MAX(customer_total_sales)
        FROM customer_sales
    )
)
SELECT 
    ts.web_site_sk,
    ts.total_sales_price,
    hvc.c_first_name,
    hvc.c_last_name
FROM top_sites ts
FULL OUTER JOIN high_value_customers hvc ON ts.web_site_sk IS NOT NULL AND hvc.c_customer_sk IS NOT NULL
WHERE (ts.total_sales_price IS NOT NULL OR hvc.c_customer_sk IS NOT NULL)
  AND (ts.total_sales_price > 10000 OR hvc.customer_total_sales IS NULL)
ORDER BY ts.total_sales_price DESC NULLS LAST, hvc.c_first_name ASC;
