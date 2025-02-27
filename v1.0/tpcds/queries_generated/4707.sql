
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT wr_order_number) AS web_return_count,
        COUNT(DISTINCT sr_ticket_number) AS store_return_count,
        SUM(wr_return_amt) AS total_web_return_amt,
        SUM(sr_return_amt) AS total_store_return_amt
    FROM customer c
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.w_returning_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
),
AverageReturns AS (
    SELECT 
        AVG(web_return_count) AS avg_web_returns,
        AVG(store_return_count) AS avg_store_returns,
        AVG(total_web_return_amt) AS avg_web_return_amount,
        AVG(total_store_return_amt) AS avg_store_return_amount
    FROM CustomerReturns
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_sk, p.p_promo_name
),
RankedPromotions AS (
    SELECT 
        promo_name,
        total_orders,
        total_profit,
        RANK() OVER (ORDER BY total_profit DESC) AS promo_rank
    FROM Promotions
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cr.web_return_count,
    cr.store_return_count,
    ar.avg_web_returns,
    ar.avg_store_returns,
    r.promo_name AS top_promo,
    r.total_orders,
    r.total_profit
FROM customer c
JOIN CustomerReturns cr ON c.c_customer_sk = cr.c_customer_sk
CROSS JOIN AverageReturns ar
LEFT JOIN RankedPromotions r ON r.promo_rank = 1
WHERE cr.web_return_count > ar.avg_web_returns
OR cr.store_return_count > ar.avg_store_returns
ORDER BY c.c_customer_id;
