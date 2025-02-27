
WITH RECURSIVE sales_rank AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_ext_sales_price,
        ws_sold_date_sk,
        RANK() OVER (PARTITION BY ws_order_number ORDER BY ws_ext_sales_price DESC) as sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
top_sales AS (
    SELECT 
        ws_order_number, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_order_number
    HAVING SUM(ws_ext_sales_price) > 1000
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year < 1990 AND c.c_preferred_cust_flag = 'Y'
    GROUP BY c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_spent,
        cs.order_count,
        CASE 
            WHEN cs.total_spent > 5000 THEN 'VIP'
            WHEN cs.total_spent BETWEEN 3000 AND 5000 THEN 'Gold'
            WHEN cs.total_spent BETWEEN 1000 AND 3000 THEN 'Silver'
            ELSE 'Bronze' 
        END AS customer_tier
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
),
yearly_performance AS (
    SELECT 
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_sales_price) AS avg_order_value
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
return_statistics AS (
    SELECT 
        cr.cr_reason_sk,
        r.r_reason_desc,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY cr.cr_reason_sk, r.r_reason_desc
)
SELECT 
    cust.c_customer_id,
    cust.total_spent,
    cust.customer_tier,
    yr.d_year,
    yr.total_sales,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount
FROM high_value_customers cust
JOIN yearly_performance yr ON cust.order_count > 5
LEFT JOIN return_statistics rs ON cust.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = rs.cr_returning_customer_sk LIMIT 1)
ORDER BY yr.d_year DESC, cust.total_spent DESC;
