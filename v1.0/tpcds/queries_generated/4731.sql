
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_quantity) AS avg_quantity_per_order
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighSpenders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
    FROM CustomerStats
    WHERE total_spent > (
        SELECT AVG(total_spent) FROM CustomerStats
    )
),
RecentReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned,
        SUM(cr.cr_return_amt) AS total_return_amount
    FROM catalog_returns cr
    WHERE cr.returning_customer_sk IS NOT NULL
    GROUP BY cr.returning_customer_sk
),
FinalStats AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        hs.spend_rank,
        COALESCE(rr.total_returned, 0) AS total_returned,
        COALESCE(rr.total_return_amount, 0.00) AS total_return_amount,
        (cs.total_spent - COALESCE(rr.total_return_amount, 0.00)) AS net_spent
    FROM CustomerStats cs
    LEFT JOIN HighSpenders hs ON cs.c_customer_sk = hs.c_customer_sk
    LEFT JOIN RecentReturns rr ON cs.c_customer_sk = rr.returning_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_orders,
    f.total_spent,
    f.net_spent
FROM FinalStats f
WHERE f.total_orders > 5
  AND f.net_spent > 100
ORDER BY f.net_spent DESC;
