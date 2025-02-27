
WITH RankedReturns AS (
    SELECT
        cr.returned_date_sk,
        cr.returning_customer_sk,
        cr.return_quantity,
        cr.return_amount,
        ROW_NUMBER() OVER (PARTITION BY cr.returning_customer_sk ORDER BY cr.returned_date_sk DESC) AS rn
    FROM catalog_returns cr
    WHERE cr.return_quantity IS NOT NULL
),
AggregateReturns AS (
    SELECT 
        rr.returning_customer_sk,
        SUM(rr.return_quantity) AS total_return_quantity,
        SUM(rr.return_amount) AS total_return_amount
    FROM RankedReturns rr
    WHERE rr.rn <= 5 -- Top 5 returns per customer
    GROUP BY rr.returning_customer_sk
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        ca.ca_city,
        COALESCE(d.cd_gender, 'U') AS gender,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        COALESCE(ar.total_return_quantity, 0) AS last_5_returns_quantity,
        COALESCE(ar.total_return_amount, 0.00) AS last_5_returns_amount
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN AggregateReturns ar ON c.c_customer_sk = ar.returning_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, ca.ca_city, d.cd_gender
),
FinalReport AS (
    SELECT 
        cs.*,
        CASE
            WHEN cs.total_orders > 10 THEN 'High Value'
            WHEN cs.last_5_returns_quantity > 0 THEN 'Problematic'
            ELSE 'Regular' 
        END AS customer_segment,
        RANK() OVER (ORDER BY cs.last_5_returns_amount DESC) AS ret_rank
    FROM CustomerStats cs
)
SELECT
    fr.c_customer_sk,
    fr.ca_city,
    fr.gender,
    fr.total_orders,
    fr.last_5_returns_quantity,
    fr.last_5_returns_amount,
    fr.customer_segment
FROM FinalReport fr
WHERE fr.ret_rank <= 10 
OR (fr.ret_rank > 10 AND fr.last_5_returns_amount > 500)
ORDER BY fr.last_5_returns_amount DESC, fr.total_orders ASC;
