
WITH RankedReturns AS (
    SELECT 
        cr_returning_customer_sk,
        cr_item_sk,
        cr_return_quantity,
        cr_return_amount,
        ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY cr_return_quantity DESC) AS rn
    FROM catalog_returns
    WHERE cr_return_quantity > 0
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.net_profit) AS total_net_profit
    FROM customer AS c
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year >= 1980
    GROUP BY c.c_customer_id
    HAVING SUM(ws.net_profit) > 1000
),
DateDifference AS (
    SELECT 
        d1.d_date AS sale_date,
        d2.d_date AS return_date,
        DATEDIFF(d2.d_date, d1.d_date) AS days_between
    FROM date_dim d1
    JOIN catalog_returns cr ON d1.d_date_sk = cr.cr_returned_date_sk
    JOIN date_dim d2 ON d2.d_date_sk = cr.cr_returned_date_sk
    WHERE DATEDIFF(d2.d_date, d1.d_date) BETWEEN 0 AND 30
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    cr.cr_item_sk,
    SUM(cr.cr_return_quantity) AS total_quantity_returned,
    MAX(r.days_between) AS max_days_between,
    CASE
        WHEN MAX(r.days_between) IS NULL THEN 'No Returns'
        WHEN MAX(r.days_between) < 10 THEN 'Recent Return'
        ELSE 'Old Return'
    END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(cr.cr_return_amount) DESC) AS customer_return_rank
FROM Customer c
LEFT JOIN RankedReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN DateDifference r ON cr.cr_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
WHERE cr.cr_return_quantity > 0
GROUP BY 1, 2
HAVING SUM(cr.cr_return_quantity) > 5
ORDER BY 5 DESC, customer_return_rank
LIMIT 20;
