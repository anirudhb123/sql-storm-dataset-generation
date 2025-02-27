
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY cs_bill_customer_sk
    UNION ALL
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN SalesHierarchy sh ON cs.ship_customer_sk = sh.customer_sk
    GROUP BY cs_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        ch.total_profit,
        RANK() OVER (ORDER BY ch.total_profit DESC) AS rank
    FROM SalesHierarchy ch
    JOIN customer c ON c.c_customer_sk = ch.customer_sk
    WHERE ch.total_profit IS NOT NULL
),
Promotions AS (
    SELECT 
        p.promo_id,
        COUNT(ws.web_order_number) AS promotion_count,
        SUM(ws.ws_net_paid) AS total_sales
    FROM promotion p
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.promo_id
    HAVING SUM(ws.ws_net_paid) > 0
)
SELECT 
    tc.c_customer_id,
    COALESCE(prom.promotion_count, 0) AS promotion_count,
    COALESCE(prom.total_sales, 0) AS total_sales,
    tc.total_profit
FROM TopCustomers tc
LEFT JOIN Promotions prom ON tc.rank = 1
WHERE tc.total_profit > 1000
ORDER BY tc.total_profit DESC
LIMIT 100;
