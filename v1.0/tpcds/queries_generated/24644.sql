
WITH ranked_sales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sales_price > 0
),
customer_purchases AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
return_summaries AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returned_quantity,
        COUNT(sr_order_number) AS total_return_count
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
qualified_customers AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.total_orders,
        cp.total_spent,
        COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
        rs.total_return_count
    FROM customer_purchases cp
    LEFT JOIN return_summaries rs ON cp.c_customer_sk = rs.sr_returning_customer_sk
    WHERE cp.total_spent > (SELECT AVG(total_spent) FROM customer_purchases)
      AND (rs.total_returned_quantity IS NULL OR rs.total_return_count < 3)
),
final_metrics AS (
    SELECT 
        qc.c_customer_sk,
        qc.c_first_name,
        qc.c_last_name,
        qc.total_orders,
        qc.total_spent,
        SUM(rws.ws_sales_price) AS total_sales_from_ranked,
        (SELECT COUNT(*) FROM ranked_sales rs WHERE rs.web_site_sk = qc.c_customer_sk) AS ranked_sales_count
    FROM qualified_customers qc
    LEFT JOIN ranked_sales rws ON qc.c_customer_sk = rws.web_site_sk
    GROUP BY qc.c_customer_sk, qc.c_first_name, qc.c_last_name, qc.total_orders, qc.total_spent
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_orders,
    f.total_spent,
    f.total_sales_from_ranked,
    CASE 
        WHEN f.total_spent IS NULL THEN 'Null Spending'
        WHEN f.total_spent < 1000 THEN 'Low Spender'
        ELSE 'High Roller'
    END AS spending_category
FROM final_metrics f
WHERE f.total_spent IS NOT NULL
  AND (f.total_returned_quantity < 5 OR f.total_returned_quantity IS NULL)
  AND f.total_sales_from_ranked > 0
ORDER BY f.total_spent DESC
LIMIT 100;  
