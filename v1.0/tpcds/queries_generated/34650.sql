
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_net_paid) > 1000
    UNION ALL
    SELECT 
        customer_id,
        (SELECT SUM(ss_net_paid) FROM store_sales WHERE ss_customer_sk = customer_id) AS total_spent,
        (SELECT COUNT(ss_ticket_number) FROM store_sales WHERE ss_customer_sk = customer_id) AS total_orders
    FROM sales_cte
    WHERE total_orders < 5
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
popular_items AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        COUNT(ws.ws_order_number) AS purchase_count
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_product_name
    HAVING COUNT(ws.ws_order_number) > 50
),
sales_summary AS (
    SELECT 
        customer_id,
        SUM(total_spent) AS total_revenue,
        AVG(total_orders) AS avg_orders
    FROM sales_cte
    GROUP BY customer_id
),
combined AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state,
        si.i_product_name,
        ss.total_revenue,
        ss.avg_orders
    FROM customer_info ci
    JOIN sales_summary ss ON ci.c_customer_sk = ss.customer_id
    CROSS JOIN popular_items si
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.ca_city,
    c.ca_state,
    COALESCE(s.total_revenue, 0) AS total_revenue,
    COALESCE(s.avg_orders, 0) AS avg_orders,
    p.i_product_name
FROM combined AS c
LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN promotion p ON p.p_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
WHERE 
    (s.total_revenue > 1000 OR p.promo_id IS NOT NULL)
    AND (c.ca_state IS NOT NULL)
ORDER BY c.ca_city, total_revenue DESC
LIMIT 100;
