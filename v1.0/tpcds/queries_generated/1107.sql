
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) AS total_net_profit
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_profit,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM CustomerSales cs
    WHERE cs.total_net_profit > 1000
),
TopPromotions AS (
    SELECT 
        p.p_promo_name,
        SUM(COALESCE(cs.total_net_profit, 0)) AS promo_net_profit
    FROM promotion p
    JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY p.p_promo_name
    HAVING SUM(COALESCE(cs.total_net_profit, 0)) > 5000
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_net_profit,
    tp.promo_net_profit
FROM HighValueCustomers hvc
LEFT JOIN TopPromotions tp ON tp.promo_net_profit IS NOT NULL
ORDER BY hvc.rank, hvc.total_net_profit DESC;
