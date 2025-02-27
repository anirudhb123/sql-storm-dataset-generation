
WITH ranked_sales AS (
    SELECT
        ws.web_site_sk,
        ws.web_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        SUM(CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_quantity ELSE 0 END) AS total_catalog_sales,
        SUM(CASE WHEN ss.ss_item_sk IS NOT NULL THEN ss.ss_quantity ELSE 0 END) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
    FROM
        customer c
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk
),
top_customers AS (
    SELECT
        cs.c_customer_sk,
        (cs.total_catalog_sales + cs.total_store_sales) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY (cs.total_catalog_sales + cs.total_store_sales) DESC) AS customer_rank
    FROM
        customer_stats cs
)
SELECT
    cu.c_first_name,
    cu.c_last_name,
    cu.c_email_address,
    cs.total_sales,
    rs.web_site_sk,
    rs.web_sales_price
FROM
    top_customers tc
JOIN customer cu ON cu.c_customer_sk = tc.c_customer_sk
JOIN ranked_sales rs ON rs.sales_rank = 1
WHERE
    tc.customer_rank <= 10
ORDER BY
    total_sales DESC;
