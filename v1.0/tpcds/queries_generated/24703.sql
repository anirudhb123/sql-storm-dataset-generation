
WITH RecursiveCustomerReturns AS (
    SELECT
        cr.returning_customer_sk,
        cr.returning_addr_sk,
        cr.return_quantity,
        cr.return_amt,
        ROW_NUMBER() OVER (PARTITION BY cr.returning_customer_sk ORDER BY cr.returned_date_sk DESC) AS rnk
    FROM
        catalog_returns cr
    WHERE
        cr.return_quantity IS NOT NULL
),
AggregatedReturns AS (
    SELECT
        r.returning_customer_sk,
        SUM(r.return_quantity) AS total_return_quantity,
        SUM(r.return_amt) AS total_return_amt,
        COUNT(r.returning_customer_sk) AS return_count
    FROM
        RecursiveCustomerReturns r
    WHERE
        r.rnk <= 5
    GROUP BY
        r.returning_customer_sk
),
CustomerStatus AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_month,
        cd.cd_gender,
        CASE
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        COALESCE(a.ca_city, 'Unknown') AS city,
        COALESCE(a.ca_state, 'Unknown') AS state
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
ReturnAnalysis AS (
    SELECT
        cs.c_customer_sk,
        cs.city,
        cs.state,
        COALESCE(ar.total_return_quantity, 0) AS total_returns,
        COALESCE(ar.total_return_amt, 0) AS total_return_amt,
        (CASE
            WHEN ar.total_return_quantity > 10 THEN 'High Return Customer'
            WHEN ar.total_return_quantity BETWEEN 5 AND 10 THEN 'Medium Return Customer'
            ELSE 'Low Return Customer'
        END) AS return_category
    FROM
        CustomerStatus cs
    LEFT JOIN AggregatedReturns ar ON cs.c_customer_sk = ar.returning_customer_sk
)
SELECT
    r.return_category,
    COUNT(*) AS customer_count,
    SUM(r.total_return_amt) AS total_returned_amount,
    AVG(r.total_returns) AS avg_returns,
    COUNT(DISTINCT r.city) AS distinct_cities,
    STRING_AGG(DISTINCT r.state, ', ') AS states_list
FROM
    ReturnAnalysis r
WHERE
    r.total_return_amt IS NOT NULL AND r.total_return_amt > 0
GROUP BY
    r.return_category
ORDER BY
    customer_count DESC, return_category;
