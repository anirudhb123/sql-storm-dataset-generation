
WITH RECURSIVE sales_data AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ext_tax,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) AS rn
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d WHERE d.d_current_month = 'Y')
),
total_sales AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_net_paid,
        SUM(sd.ws_ext_tax) AS total_tax,
        CASE 
            WHEN SUM(sd.ws_net_paid) IS NULL THEN 0
            ELSE SUM(sd.ws_net_paid) / NULLIF(SUM(sd.ws_quantity), 0)
        END AS avg_price_per_item
    FROM
        sales_data sd
    GROUP BY
        sd.ws_item_sk
),
customer_activity AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT w.ws_order_number) AS total_orders,
        SUM(w.ws_quantity) AS total_quantity_ordered
    FROM
        customer c
    LEFT JOIN web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id
),
promotions_engaged AS (
    SELECT
        p.p_promo_id,
        COUNT(cs.cs_order_number) AS orders_count,
        AVG(cs.cs_ext_sales_price) AS avg_sales_price
    FROM
        promotion p
    LEFT JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY
        p.p_promo_id
)

SELECT
    ca.ca_city,
    ca.ca_state,
    coalesce(ca.ca_county, 'Unknown') AS county,
    MAX(ts.total_net_paid) AS highest_net_paid,
    MIN(ts.avg_price_per_item) AS lowest_avg_price_per_item,
    COUNT(DISTINCT ca.customer_id) AS total_customers,
    SUM(active.total_orders) AS total_active_customers_orders,
    AVG(prom.avg_sales_price) AS average_sales_price_per_promo
FROM
    total_sales ts
JOIN customer_activity active ON active.total_quantity_ordered > 0
JOIN warehouse w ON w.w_warehouse_sk = (
    SELECT i.i_item_sk 
    FROM item i 
    WHERE i.i_item_sk = ts.ws_item_sk
      AND i.i_current_price IS NOT NULL
      AND i.i_brand = 'SomeBrand' 
      AND i.i_size IN ('Small', 'Medium')
    ORDER BY i.i_current_price DESC
    LIMIT 1
)
LEFT JOIN customer_address ca ON ca.ca_address_sk = (
    SELECT MAX(customer.c_current_addr_sk)
    FROM customer 
    WHERE customer.c_customer_sk = active.c_customer_id
)
LEFT JOIN promotions_engaged prom ON prom.orders_count > 5 
WHERE coalesce(ca.ca_city, '') <> ''
GROUP BY 
    ca.ca_city, 
    ca.ca_state,
    ca.ca_county
HAVING
    COUNT(DISTINCT ca.customer_id) > 5 
    AND MAX(ts.total_net_paid) > 5000
ORDER BY
    highest_net_paid DESC, 
    lowest_avg_price_per_item ASC
LIMIT 100;
