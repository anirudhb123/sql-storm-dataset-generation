
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM
        web_sales ws
    UNION ALL
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid
    FROM
        catalog_sales cs
    JOIN SalesCTE s ON cs.cs_item_sk = s.ws_item_sk
    WHERE
        cs.cs_sold_date_sk <= s.ws_sold_date_sk
),
TotalSales AS (
    SELECT
        s.ws_item_sk,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_net_paid) AS total_net_paid
    FROM
        SalesCTE s
    GROUP BY
        s.ws_item_sk
),
CustomerWithMaxReturns AS (
    SELECT
        sr.sr_customer_sk,
        COUNT(sr.sr_returned_date_sk) AS return_count
    FROM
        store_returns sr
    GROUP BY
        sr.sr_customer_sk
    HAVING
        COUNT(sr.sr_returned_date_sk) = (
            SELECT
                MAX(counts.return_count)
            FROM (
                SELECT
                    sr1.sr_customer_sk,
                    COUNT(sr1.sr_returned_date_sk) AS return_count
                FROM
                    store_returns sr1
                GROUP BY
                    sr1.sr_customer_sk
            ) counts
        )
)
SELECT
    c.c_customer_id,
    SUM(ts.total_quantity) AS total_quantity_sold,
    SUM(ts.total_net_paid) AS total_money_spent,
    COUNT(DISTINCT cr.sr_ticket_number) AS total_returns
FROM
    customer c
LEFT JOIN TotalSales ts ON c.c_customer_sk = ts.ws_item_sk
LEFT JOIN store_returns cr ON c.c_customer_sk = cr.sr_customer_sk
JOIN CustomerWithMaxReturns cmr ON c.c_customer_sk = cmr.sr_customer_sk
WHERE
    c.c_birth_year BETWEEN 1980 AND 2000
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY
    c.c_customer_id
ORDER BY
    total_money_spent DESC
LIMIT 10;
