
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
Promotions AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS promo_count
    FROM
        promotion p
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY
        p.p_promo_id, p.p_promo_name
),
HighValueCustomers AS (
    SELECT
        c.c_customer_id,
        cs.total_profit
    FROM
        CustomerSales cs
    JOIN customer_demographics cd ON cs.c_customer_id = (
            SELECT c.c_customer_id
            FROM customer c
            WHERE c.c_customer_sk = cs.c_customer_id
        )
    WHERE cs.total_profit > (
        SELECT AVG(total_profit) FROM CustomerSales
    )
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales,
    COALESCE(sr.return_amt, 0) AS total_returns,
    CASE
        WHEN SUM(ws.ws_net_profit) IS NULL THEN 'No Sales'
        WHEN SUM(ws.ws_net_profit) < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS sales_status,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cs.total_profit DESC) AS rank,
    COALESCE(pr.promo_count, 0) AS promo_usage
FROM
    customer c
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN Promotions pr ON ws.ws_promo_sk = pr.p_promo_id
WHERE
    c.c_current_cdemo_sk IS NOT NULL
GROUP BY
    c.c_customer_id, c.c_first_name, c.c_last_name, sr.return_amt, pr.promo_count
HAVING
    total_sales > 1000 OR total_returns IS NOT NULL
ORDER BY
    c.c_last_name, rank DESC;
