
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) as sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_moy BETWEEN 1 AND 6
    )
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        coalesce(ARRAY_AGG(DISTINCT ca.ca_city) FILTER (WHERE ca.ca_city IS NOT NULL), '{}') as customer_cities
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COUNT(DISTINCT rs.ws_order_number) AS total_orders,
    SUM(rs.ws_net_paid) AS total_net_paid,
    STRING_AGG(DISTINCT ci.customer_cities, ', ') AS unique_cities
FROM ranked_sales rs
JOIN customer_info ci ON ci.c_customer_sk = rs.ws_bill_customer_sk
WHERE rs.sales_rank = 1
GROUP BY ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status
HAVING SUM(rs.ws_net_paid) > (SELECT AVG(ws_net_paid) FROM web_sales) 
ORDER BY total_net_paid DESC
LIMIT 50;
