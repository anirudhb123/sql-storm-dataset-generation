
WITH CustomerReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amount
    FROM
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
), Promotions AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ws.ws_quantity) AS total_items_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk 
    WHERE
        p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = CURRENT_DATE)
        AND p.p_end_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_date = CURRENT_DATE)
    GROUP BY
        p.p_promo_sk, p.p_promo_name
)
SELECT
    cr.c_customer_sk,
    cr.c_first_name,
    cr.c_last_name,
    cr.total_returns,
    cr.total_return_amount,
    p.total_items_sold,
    p.total_sales
FROM
    CustomerReturns cr
FULL OUTER JOIN Promotions p ON cr.c_customer_sk IS NOT NULL
ORDER BY
    COALESCE(cr.total_return_amount, 0) DESC,
    COALESCE(p.total_sales, 0) DESC
LIMIT 100
```
