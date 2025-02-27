
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk > 1000
    GROUP BY ws_item_sk
),
high_value_customers AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM customer
    JOIN catalog_sales ON c_customer_sk = cs_bill_customer_sk
    GROUP BY c_customer_sk
    HAVING COUNT(DISTINCT cs_order_number) > 5
),
item_with_promotions AS (
    SELECT 
        i.i_item_id,
        p.p_promo_name,
        p.p_cost
    FROM item i
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
),
daily_return_summary AS (
    SELECT 
        d.d_date,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM date_dim d
    LEFT JOIN store_returns sr ON d.d_date_sk = sr.sr_returned_date_sk
    GROUP BY d.d_date
    ORDER BY d.d_date
)
SELECT 
    vendor.i_item_id,
    SUM(COALESCE(s.total_sales, 0)) AS total_revenue,
    SUM(d.total_returns) AS total_returns,
    MAX(ic.order_count) AS high_value_order_count,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotions_used,
    CASE 
        WHEN SUM(d.total_returns) > 0 THEN 'Returns Occurred'
        ELSE 'No Returns'
    END AS return_status
FROM item_with_promotions vendor
LEFT JOIN sales_cte s ON vendor.i_item_id = s.ws_item_sk
LEFT JOIN high_value_customers ic ON ic.c_customer_sk = vendor.i_item_id
LEFT JOIN daily_return_summary d ON d.d_date = CURRENT_DATE - INTERVAL '1 DAY'
GROUP BY vendor.i_item_id
HAVING SUM(COALESCE(s.total_sales, 0)) > 1000
ORDER BY total_revenue DESC
LIMIT 10;
