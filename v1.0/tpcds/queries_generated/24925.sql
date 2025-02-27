
WITH RECURSIVE DateRange AS (
    SELECT MIN(d_date_sk) AS start_date, MAX(d_date_sk) AS end_date
    FROM date_dim
    WHERE d_year >= 2020
), 
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        dur.d_days AS active_days,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    CROSS JOIN (
        SELECT (end_date - start_date) AS d_days
        FROM DateRange
    ) dur
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT start_date FROM DateRange) AND (SELECT end_date FROM DateRange)
    GROUP BY c.c_customer_sk, dur.d_days
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        SUM(CASE WHEN ws.ws_net_profit > 100 THEN 1 ELSE 0 END) AS profitable_promotions
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_profit,
        cs.avg_net_paid,
        CASE 
            WHEN cs.total_profit > 1000 THEN 'High'
            WHEN cs.total_profit > 100 THEN 'Medium'
            ELSE 'Low'
        END AS value_category
    FROM CustomerSales cs
    WHERE cs.total_orders > 5 AND cs.rn = 1
    ORDER BY total_profit DESC
)
SELECT 
    c.c_customer_id,
    hc.total_orders,
    hc.total_profit,
    hc.avg_net_paid,
    ph.profitable_promotions,
    CASE 
        WHEN hc.avg_net_paid IS NULL THEN 'No Sales'
        ELSE CAST(hc.total_profit AS VARCHAR) || ' Profit'
    END AS profit_status,
    COALESCE(wc.warehouse_count, 0) AS warehouse_count
FROM HighValueCustomers hc
JOIN customer c ON hc.c_customer_sk = c.c_customer_sk
LEFT JOIN (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_warehouse_sk) AS warehouse_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
) wc ON wc.ws_bill_customer_sk = hc.c_customer_sk
LEFT JOIN Promotions ph ON ph.p_promo_sk = (
    SELECT p.p_promo_sk FROM promotion p 
    WHERE p.p_response_target IS NOT NULL 
    ORDER BY random() 
    LIMIT 1
)
WHERE c.c_birth_year IS NULL OR c.c_birth_month IS NULL
ORDER BY hc.total_profit DESC, hc.total_orders ASC
LIMIT 100;
