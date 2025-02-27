
WITH RECURSIVE customer_orders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING COUNT(ws.ws_order_number) > 0

    UNION ALL

    SELECT 
        co.c_customer_sk,
        co.c_first_name,
        co.c_last_name,
        co.order_count + 1,
        co.total_spent + (SELECT SUM(ws2.ws_net_paid_inc_tax) 
                           FROM web_sales ws2 
                           WHERE ws2.ws_bill_customer_sk = co.c_customer_sk 
                           AND ws2.ws_order_number NOT IN (SELECT ws3.ws_order_number FROM web_sales ws3 
                                                           WHERE ws3.ws_bill_customer_sk = co.c_customer_sk))
    FROM customer_orders co
    WHERE co.order_count < 10
),
ranked_customers AS (
    SELECT 
        co.c_customer_sk,
        co.c_first_name,
        co.c_last_name,
        co.order_count,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM customer_orders co
),
high_value_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.order_count,
        rc.total_spent
    FROM ranked_customers rc
    WHERE rc.rank <= 100
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.order_count,
    hvc.total_spent,
    a.ca_city,
    a.ca_state,
    a.ca_country,
    d.d_year
FROM high_value_customers hvc
JOIN customer_address a ON hvc.c_customer_sk = a.ca_address_sk
JOIN date_dim d ON d.d_date_sk = (
    SELECT MAX(ws.ws_sold_date_sk)
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk = hvc.c_customer_sk
)
WHERE hvc.total_spent > (SELECT AVG(total_spent) FROM high_value_customers)
ORDER BY hvc.total_spent DESC;
