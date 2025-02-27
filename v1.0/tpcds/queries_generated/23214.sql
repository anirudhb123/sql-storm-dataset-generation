
WITH recent_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
),
item_stats AS (
    SELECT 
        i.i_item_id, 
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_sales,
        AVG(ws.ws_net_paid) AS average_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_spent
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
    HAVING SUM(COALESCE(ss.ss_net_paid, 0)) > 1000
),
return_issues AS (
    SELECT 
        sr_item_sk, 
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_returned
    FROM store_returns
    GROUP BY sr_item_sk
    HAVING COUNT(*) > 5
),
combined_results AS (
    SELECT 
        i.i_item_id,
        is.total_sales,
        is.average_net_paid,
        is.order_count,
        hvc.total_spent,
        COALESCE(ri.return_count, 0) AS return_count,
        COALESCE(ri.total_returned, 0) AS total_returned,
        CASE 
            WHEN hvc.total_spent IS NULL THEN 'Not a high value customer'
            WHEN hvc.total_spent > 5000 THEN 'VIP Customer'
            ELSE 'Regular Customer' 
        END AS customer_type
    FROM item_stats is
    LEFT JOIN high_value_customers hvc ON is.i_item_id = hvc.c_customer_id
    LEFT JOIN return_issues ri ON is.i_item_id = ri.sr_item_sk
)
SELECT 
    cr.i_item_id,
    cr.total_sales,
    cr.order_count,
    cr.average_net_paid,
    cr.total_spent,
    cr.customer_type,
    CASE 
        WHEN cr.return_count > 10 THEN 'Potential Quality Issues'
        ELSE 'Normal Return Rates' 
    END AS return_status
FROM combined_results cr
WHERE cr.total_sales > 100
ORDER BY cr.total_spent DESC, cr.total_sales DESC;
