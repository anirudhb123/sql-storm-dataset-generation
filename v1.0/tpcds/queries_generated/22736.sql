
WITH RankedReturns AS (
    SELECT 
        wr.returning_customer_sk, 
        wr.return_quantity, 
        wr.return_amt, 
        RANK() OVER (PARTITION BY wr.returning_customer_sk ORDER BY wr.returned_date_sk DESC) AS rnk,
        wr.returned_date_sk,
        wr.return_amt_inc_tax,
        wr.refunded_cash
    FROM web_returns wr
), AggregateStats AS (
    SELECT 
        R.*, 
        CASE 
            WHEN R.return_quantity IS NULL OR R.return_amt IS NULL THEN 'NO RETURN'
            ELSE 'RETURN'
        END AS return_status,
        COALESCE(R.return_amt * 0.15, 0) AS expected_fee,
        (R.return_amt_inc_tax - R.refunded_cash) AS net_return
    FROM RankedReturns R
    WHERE R.rnk = 1
), CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS latest_return_date,
        a.ca_city,
        a.ca_state,
        ROW_NUMBER() OVER (PARTITION BY a.ca_state ORDER BY d.d_date DESC) AS rn
    FROM customer c
    JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN date_dim d ON d.d_date_sk = (SELECT MAX(d2.d_date_sk) FROM date_dim d2)
)
SELECT 
    C.full_name,
    C.ca_city,
    C.ca_state,
    AS.return_quantity,
    AS.return_amt,
    AS.expected_fee,
    AS.net_return,
    CASE 
        WHEN AS.return_status = 'RETURN' THEN AS.net_return 
        ELSE NULL 
    END AS final_net_return,
    (SELECT COUNT(*) FROM AggregateStats WHERE return_status = 'RETURN' AND return_quantity > 0) AS total_returns_by_state
FROM AggregateStats AS
JOIN CustomerInfo C ON AS.returning_customer_sk = C.c_customer_sk
WHERE C.rn <= 5 AND (C.ca_state IS NOT NULL OR C.ca_city IS NOT NULL)
ORDER BY C.ca_state ASC, final_net_return DESC NULLS LAST;
