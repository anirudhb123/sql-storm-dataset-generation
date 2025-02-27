
WITH sales_data AS (
    SELECT
        s.ss_ticket_number,
        s.ss_sold_date_sk,
        s.ss_item_sk,
        s.ss_quantity,
        s.ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY s.ss_net_profit DESC) AS rn
    FROM
        store_sales s
    WHERE
        s.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - INTERVAL '1 year'
),
promotions AS (
    SELECT
        p.p_promo_id,
        p.p_discount_active,
        p.p_cost,
        SUM(ws.ws_net_paid) AS total_sales
    FROM
        promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY
        p.p_promo_id, p.p_discount_active, p.p_cost
    HAVING
        SUM(ws.ws_net_paid) > 1000
),
item_total AS (
    SELECT
        i.i_item_sk,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM
        item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY
        i.i_item_sk
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    SUM(s.sales_value) AS total_sales_value,
    SUM(COALESCE(i.total_sales_price, 0)) AS item_sales_value,
    COUNT(DISTINCT s.ss_ticket_number) AS total_transactions,
    MAX(p.total_sales) AS highest_promo_sales
FROM
    customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN sales_data s ON c.c_customer_sk = s.ss_customer_sk
LEFT JOIN item_total i ON s.ss_item_sk = i.i_item_sk
LEFT JOIN promotions p ON p.p_discount_active = 'Y'
WHERE
    ca.ca_state = 'CA'
    AND (i.transaction_count > 5 OR p.total_sales IS NOT NULL)
GROUP BY
    c.c_customer_id, ca.ca_city
HAVING
    total_sales_value > 5000
ORDER BY
    total_sales_value DESC
LIMIT 10;
