
WITH RECURSIVE customer_return_stats AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_order_number) AS return_orders,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
high_return_customers AS (
    SELECT 
        cr.*,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN d.d_day_name IN ('Saturday', 'Sunday') THEN 'Weekend'
            ELSE 'Weekday'
        END AS return_day_type
    FROM 
        customer_return_stats cr
    JOIN 
        customer c ON cr.returning_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON d.d_date_sk = (SELECT MAX(sr_returned_date_sk) FROM store_returns WHERE sr_returning_customer_sk = cr.returning_customer_sk)
    WHERE 
        cr.total_returned > (SELECT AVG(total_returned) FROM customer_return_stats)
),
top_returns AS (
    SELECT 
        hrc.*, 
        CASE WHEN hrc.total_return_amount > 1000 THEN 'High Roller' ELSE 'Regular' END AS customer_segment
    FROM 
        high_return_customers hrc
    WHERE 
        hrc.rn <= 10
)
SELECT 
    tr.customer_segment,
    tr.c_first_name,
    tr.c_last_name,
    tr.total_returned,
    tr.total_return_amount,
    tr.return_day_type,
    COALESCE(sm.sm_carrier, 'Unknown') AS shipping_carrier,
    COUNT(DISTINCT ws.ws_order_number) AS related_web_sales
FROM 
    top_returns tr
LEFT JOIN 
    web_sales ws ON tr.returning_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY 
    tr.customer_segment, 
    tr.c_first_name, 
    tr.c_last_name, 
    tr.total_returned, 
    tr.total_return_amount, 
    tr.return_day_type, 
    sm.sm_carrier
HAVING 
    SUM(tr.total_return_amount) IS NOT NULL
ORDER BY 
    tr.total_return_amount DESC, 
    tr.customer_segment DESC;
```
