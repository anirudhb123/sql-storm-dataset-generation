
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COUNT(DISTINCT sr.ticket_number) DESC) AS rn
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), MaxReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        CASE 
            WHEN cr.total_return_amount > (SELECT AVG(total_return_amount) FROM CustomerReturns) THEN 'Above Average'
            ELSE 'Below Average'
        END AS return_status
    FROM CustomerReturns cr
    JOIN customer c ON cr.c_customer_sk = c.c_customer_sk
    WHERE cr.rn = 1
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
    MAX(CASE WHEN cu.return_status = 'Above Average' THEN cu.total_return_amount END) AS max_above_average,
    MIN(CASE WHEN cu.return_status = 'Below Average' THEN cu.total_return_amount END) AS min_below_average
FROM MaxReturns cu 
LEFT JOIN web_sales ws ON cu.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY cu.c_first_name, cu.c_last_name
HAVING 
    COUNT(ws.ws_order_number) > 0 OR (cu.total_returns IS NOT NULL AND cu.total_returns > 10)
ORDER BY total_net_profit DESC
LIMIT 10;
