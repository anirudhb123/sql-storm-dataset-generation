
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_quantity,
        sr_return_amt,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_amt DESC) AS rnk
    FROM 
        store_returns 
    WHERE 
        sr_return_quantity > 0 
        AND sr_reason_sk IN (SELECT r_reason_sk FROM reason WHERE r_reason_desc NOT LIKE '%wrong item%')
),
CustomerReturns AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(rr.sr_return_amt, 0)) AS total_return_amt,
        COUNT(DISTINCT rr.sr_ticket_number) AS total_returns
    FROM
        customer c
    LEFT JOIN RankedReturns rr ON c.c_customer_sk = rr.sr_customer_sk
    WHERE
        c.c_birth_year > 1980 
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cr.total_return_amt,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_amt DESC) AS customer_rank
    FROM
        CustomerReturns cr
    JOIN customer c ON c.c_customer_id = cr.c_customer_id
),
CurrentDate AS (
    SELECT 
        DENSE_RANK() OVER (ORDER BY d_date DESC) AS date_rank,
        d_date
    FROM 
        date_dim
    WHERE 
        d_current_day = 'Y'
),
FinalSummary AS (
    SELECT 
        tc.c_customer_id,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_return_amt,
        COALESCE(d.d_date, 'No Transactions') AS transaction_date,
        CASE
            WHEN tc.total_return_amt > 1000 THEN 'High Value'
            WHEN tc.total_return_amt BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM
        TopCustomers tc
    LEFT JOIN CurrentDate d ON 1=1
    WHERE 
        tc.customer_rank <= 10
)
SELECT 
    f.customer_value_category, 
    COUNT(*) AS num_customers,
    AVG(f.total_return_amt) AS avg_return_amt
FROM 
    FinalSummary f
WHERE 
    f.transaction_date IS NOT NULL
GROUP BY 
    f.customer_value_category
ORDER BY 
    num_customers DESC;
