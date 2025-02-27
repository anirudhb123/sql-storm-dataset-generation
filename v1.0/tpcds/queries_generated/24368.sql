
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, c_first_sales_date_sk
    FROM customer
    WHERE c_customer_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, c.c_first_sales_date_sk
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE c.c_customer_sk <> ch.c_customer_sk
),
sales_summary AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_paid) AS total_spent, COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
high_value_customers AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ss.total_spent, ss.total_orders,
           CASE 
               WHEN ss.total_spent IS NULL THEN 'Not a customer'
               WHEN ss.total_spent > 5000 THEN 'Gold'
               WHEN ss.total_spent BETWEEN 1001 AND 5000 THEN 'Silver'
               ELSE 'Bronze'
           END AS loyalty_tier
    FROM customer_hierarchy ch
    LEFT JOIN sales_summary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
),
state_promo AS (
    SELECT c.c_current_addr_sk, COUNT(DISTINCT ws.ws_order_number) AS promo_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_first_sales_date_sk < (
        SELECT MAX(d.d_date_sk)
        FROM date_dim d
        WHERE d.d_year = 2022 AND d.d_month_seq = 12
    )
    GROUP BY c.c_current_addr_sk
)
SELECT hv.c_customer_sk, hv.c_first_name, hv.c_last_name, hv.loyalty_tier,
       COALESCE(sp.promo_count, 0) AS promo_count,
       (SELECT COUNT(DISTINCT wr_order_number)
        FROM web_returns
        WHERE wr_returning_customer_sk = hv.c_customer_sk
          AND wr_return_quantity > (
              SELECT AVG(wr_return_quantity)
              FROM web_returns
              WHERE wr_returning_customer_sk = hv.c_customer_sk
          )) AS high_return_count
FROM high_value_customers hv
LEFT JOIN state_promo sp ON hv.c_current_addr_sk = sp.c_current_addr_sk
WHERE (
       (hv.total_orders IS NOT NULL AND hv.total_orders < 5) OR
       (hv.total_spent IS NOT NULL AND hv.total_spent BETWEEN 500 AND 2000)
      )
ORDER BY hv.loyalty_tier DESC, promo_count DESC, high_return_count DESC
FETCH FIRST 100 ROWS ONLY;
