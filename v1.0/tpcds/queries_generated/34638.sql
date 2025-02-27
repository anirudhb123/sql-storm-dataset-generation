
WITH RECURSIVE address_hierarchy AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ca_country,
        1 AS level
    FROM customer_address
    WHERE ca_state = 'CA'

    UNION ALL

    SELECT 
        ca.ca_address_sk,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_address_sk = ah.ca_address_sk
    WHERE ca.ca_city = 'Los Angeles'
),
sales_summary AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_item_sk) AS total_items,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.ws_order_number
),
final_report AS (
    SELECT
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ss.total_sales,
        ss.total_items,
        COALESCE(ss.total_sales / NULLIF(ss.total_items, 0), 0) AS avg_sales_per_item
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.ws_order_number
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
)
SELECT 
    fh.ca_city,
    fh.ca_state,
    fh.ca_country,
    COUNT(fh.c_first_name) AS customer_count,
    AVG(fh.avg_sales_per_item) AS avg_sales_per_customer,
    SUM(fh.total_sales) AS total_sales_by_city
FROM final_report fh
GROUP BY fh.ca_city, fh.ca_state, fh.ca_country
HAVING AVG(fh.avg_sales_per_item) > 100.00
ORDER BY total_sales_by_city DESC
LIMIT 10;
