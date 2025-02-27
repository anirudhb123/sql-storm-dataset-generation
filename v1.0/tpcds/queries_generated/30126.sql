
WITH RECURSIVE sales_path AS (
    SELECT
        ws_n.item_key,
        ws_sold_date_sk,
        ws_sales_price,
        1 AS level
    FROM web_sales ws_n
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    UNION ALL
    SELECT
        cs.item_key,
        cs_sold_date_sk,
        cs_sales_price,
        sp.level + 1
    FROM catalog_sales cs
    JOIN sales_path sp ON cs.item_key = sp.item_key WHERE cs_sold_date_sk < sp.ws_sold_date_sk
),
recent_info AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(ws.ws_sales_price) AS total_sales
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ca.ca_state IS NOT NULL
    GROUP BY ca.ca_city, ca.ca_state
),
ranked_products AS (
    SELECT
        item_key,
        ROW_NUMBER() OVER (PARTITION BY item_key ORDER BY sales_price DESC) AS rank
    FROM (
        SELECT
            ws.item_key,
            SUM(ws.ws_sales_price) AS sales_price
        FROM web_sales ws
        GROUP BY ws.item_key
    ) as sales_summary
)
SELECT
    r.ca_city,
    r.ca_state,
    r.unique_customers,
    r.total_sales,
    COALESCE(rp.rank, -1) AS product_rank,
    (SELECT COUNT(*) FROM customer_demographics cd WHERE cd.cd_credit_rating = 'Good') AS count_good_customers
FROM recent_info r
LEFT JOIN ranked_products rp ON r.item_key = rp.item_key
WHERE r.total_sales > 5000
ORDER BY total_sales DESC, r.ca_city;
