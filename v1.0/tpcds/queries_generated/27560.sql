
WITH AddressDetails AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS num_customers,
        STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
    FROM
        customer_address ca
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE
        ca.ca_state IN ('CA', 'TX', 'NY') 
    GROUP BY
        ca.ca_city, ca.ca_state
),
PromotionStats AS (
    SELECT
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_net_paid) AS total_sales
    FROM
        promotion p
    JOIN
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE
        p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = '2023-10-01')
        AND p.p_end_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_date = '2023-10-01')
    GROUP BY
        p.p_promo_name
)
SELECT
    ad.ca_city,
    ad.ca_state,
    ad.num_customers,
    ad.customer_names,
    ps.p_promo_name,
    ps.num_orders,
    ps.total_sales
FROM
    AddressDetails ad
JOIN
    PromotionStats ps ON ad.ca_city = 'Los Angeles'
ORDER BY
    ad.num_customers DESC, ps.total_sales DESC;
