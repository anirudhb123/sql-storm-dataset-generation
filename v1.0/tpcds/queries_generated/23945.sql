
WITH RankedReturns AS (
    SELECT
        sr.returning_customer_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.return_tax,
        RANK() OVER (PARTITION BY sr.returning_customer_sk ORDER BY sr.return_quantity DESC) AS return_rank
    FROM
        store_returns sr
    WHERE
        sr.return_quantity IS NOT NULL
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0)) AS total_purchases
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    WHERE
        (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F')
        AND cd.cd_purchase_estimate > 1000
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING
        total_purchases > (SELECT AVG(total_purchases) FROM (
            SELECT SUM(ws_quantity) AS total_purchases
            FROM web_sales
            GROUP BY ws_ship_customer_sk
        ) AS avg_sales)
),
AggregateReturns AS (
    SELECT
        r.returning_customer_sk,
        SUM(r.return_quantity) AS total_returned_quantity,
        SUM(r.return_amt) AS total_returned_amount
    FROM
        RankedReturns r
    JOIN HighValueCustomers hv ON r.returning_customer_sk = hv.c_customer_sk
    WHERE
        r.return_rank <= 5
    GROUP BY
        r.returning_customer_sk
)
SELECT 
    hv.c_first_name,
    hv.c_last_name,
    (COALESCE(ar.total_returned_quantity, 0) / NULLIF(SUM(ws.ws_quantity + cs.cs_quantity), 0)) AS return_ratio,
    ar.total_returned_quantity,
    ar.total_returned_amount
FROM 
    HighValueCustomers hv
LEFT JOIN AggregateReturns ar ON hv.c_customer_sk = ar.returning_customer_sk
LEFT JOIN web_sales ws ON hv.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN catalog_sales cs ON hv.c_customer_sk = cs.cs_ship_customer_sk
WHERE 
    hv.total_purchases > 100
GROUP BY 
    hv.c_first_name, hv.c_last_name, ar.total_returned_quantity, ar.total_returned_amount
HAVING 
    return_ratio > 0.2
ORDER BY 
    return_ratio DESC;
