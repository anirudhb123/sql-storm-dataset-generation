
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(*) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        r.r_reason_desc,
        rs.total_sales,
        rs.total_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN (
        SELECT 
            ws_bill_customer_sk, 
            total_sales, 
            total_profit
        FROM ranked_sales
        WHERE profit_rank = 1
    ) rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    LEFT JOIN reason r ON r.r_reason_sk = (
        SELECT sr_reason_sk 
        FROM store_returns sr 
        WHERE sr.sr_customer_sk = c.c_customer_sk 
        ORDER BY sr_returned_date_sk DESC 
        LIMIT 1
    )
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    COALESCE(tc.cd_credit_rating, 'Not Rated') AS credit_rating,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales_value,
    CASE 
        WHEN SUM(ws.ws_ext_sales_price) > 1000 THEN 'High Value'
        ELSE 'Regular'
    END AS customer_value_category
FROM top_customers tc
JOIN web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
WHERE ws.ws_sold_date_sk IN (
    SELECT d_date_sk 
    FROM date_dim 
    WHERE d_year = 2023
)
GROUP BY 
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_credit_rating
ORDER BY total_sales_value DESC
FETCH FIRST 100 ROWS ONLY;
